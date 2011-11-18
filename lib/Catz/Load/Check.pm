#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2011 Heikki Siltala
# Licensed under The MIT License
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

package Catz::Load::Check;

use 5.12.0; use strict; use warnings;

use parent 'Exporter';

our @EXPORT = qw ( check_begin check_any check_end );

use Catz::Util::Log qw ( logadd logclose logopen logit logdone );

use DBI;
use Text::LevenshteinXS qw( distance );

#use Catz::Core::Text;
use Catz::Util::File qw ( findlatest );
use Catz::Util::String qw ( lcc );

my $dbc;

my $phase = 1; # static test phase counter

my $item = 1;  # static test item counter

my $skip = 0;

my $fail = 0;

my $class = undef;

sub check_begin { 

 my $dbfile = shift;
  
 logit ( "connecting database '$dbfile'" );

 $dbc = DBI->connect( 
  'dbi:SQLite:dbname=' . $dbfile , undef, undef, 
  { AutoCommit => 0, RaiseError => 1, PrintError => 1 } 
 )  or die "unable to connect to database $dbfile: $DBI::errstr";
 
 logit ( 'registering functions' );
  
 # sequence
 $dbc->func( 'lcc', 1, \&lcc, 'create_function' );

 logit ( 'initializing check tables' );
  
 $dbc->do( 'delete from crun' );
 $dbc->do( 'delete from cclass' );
 $dbc->do( 'delete from citem' ); 
 
 $dbc->do( 'insert into crun select max(dt) from run' );
 
 return $dbc->selectrow_array ( 'select dt from crun' );
 
}


sub item {

 defined $_[0] or die 'test item need message';
 
 my $cnt = $dbc->selectrow_array ( 'select count(*) from mskip where mess=?', undef, $_[0] );
 
 $cnt > 0 and return;

 $fail++;

 foreach ( 1 .. 3 ) { defined $_[$_] or $_[$_] = undef }  

 $dbc->do ( 'insert into citem values (?,?,?,?,?,?)', undef, $class, $item++, @_ ); 

}

sub _breed_exists {

 my @not = @{ $dbc->selectcol_arrayref ( qq {
  select sec from sec_en where 
  pid=(select pid from pri where pri='breed') and
  sec not in ( select breed from mbreed ) order by sort; 
 })}; 

 foreach ( @not ) {
  item ( qq{breed '$_' appears in data but not is not a defined breed code}, 'breed', $_ ); 
 }

}

sub _breeder_nation {

 my @not = @{ $dbc->selectcol_arrayref ( qq {
  select sec from sec_en where 
  pid=(select pid from pri where pri='breeder') and
  sec not in ( select breeder from mbreeder ) order by sort; 
 })}; 

 foreach ( @not ) {
  item ( qq{breeder '$_' has no nation set}, 'breeder', $_ ); 
 }

}

sub _subject_case {

 my @pris = qw ( breeder cat ); 
    
 foreach my $pri( @pris ) {

  my @secs = @{ $dbc->selectcol_arrayref ( qq {
   select sec from sec_en where pid=(select pid from pri where pri=?) union 
   select sec from sec_fi where pid=(select pid from pri where pri=?)
  },undef, $pri, $pri )}; 
 
 my $match = {};
 
 foreach my $sec ( @secs ) {
 
  if ( defined $match->{lcc($sec)} ) {
  
   push @{ $match->{lcc($sec)} }, $sec;
  
  } else {
  
   $match->{lcc($sec)} = [ $sec ];
    
  } 
 
 }
 
 foreach my $key ( keys %{ $match } ) {
 

  if ( scalar @{ $match->{$key} } > 1 ) {
  
   foreach ( 1 .. ( scalar @{ $match->{$key} } ) - 1 ) {
  
    item ( qq{subjects '$match->{$key}->[0]' and '$match->{$key}->[$_]' differ only by case}, $pri, $match->{$key}->[0], $match->{$key}->[$_] );   
   
  }
   
 }  
 
} 
 
}

}

sub _subject_approx {

 my $stm = $dbc->prepare ( qq {
  select sec_en from sec where pid=(select pid from pri where pri=?) and
  sid<>? and substr ( sec_en, 1, 3 )=?
 } );

 foreach my $pri ( qw ( breeder cat ) ) {

  my @secs = @{ $dbc->selectall_arrayref ( qq {
   select sid,sec_en from sec where pid=(select pid from pri where pri=?)
  },undef, $pri )};
    
  foreach my $sec ( @secs ) {
 
  my $head = substr ( $sec->[1], 0, 3 );

  $stm->execute ( $pri, $sec->[0], $head );  

  foreach my $com ( $stm->fetchrow_array ) {
  
   #say "$pri $sec->[0] $sec->[1] $head $com";
   
   if ( length $sec->[1] > 14 ) {

   if ( distance ( $sec->[1], $com ) == 2 ) {
    
      item ( qq{subjects '$sec->[1]' and '$com' differ only by two edits}, $pri, $sec->[1], $com );
    
     }   
   
   
   } else {

   if ( distance ( $sec->[1], $com ) == 1 ) {
    
      item ( qq{subjects '$sec->[1]' and '$com' differ only by one edit}, $pri, $sec->[1], $com );
    
     }   
   
   
   }
    
   
   }
 
 }
 
}

 $stm->finish; 
  


}

sub _feature_exists {

 my @not = @{ $dbc->selectcol_arrayref ( qq {
  select sec from sec_en where 
  pid=(select pid from pri where pri='feat') and
  sec not in ( select feat from mfeat ) order by sort; 
 })}; 

 foreach ( @not ) {
  item ( qq{feature '$_' appears in data but is not a defined feature code}, 'feat', $_ ); 
 }

}


sub _title_exists {

 my @not = @{ $dbc->selectcol_arrayref ( qq {
  select sec from sec_en where 
  pid=(select pid from pri where pri='title') and
  sec not in ( select title from mtitle ) order by sort; 
 })}; 

 foreach ( @not ) {
  item ( qq{title '$_' appears in data but is not a defined title code}, 'title', $_ ); 
 }

}


sub check_any {

 my $what = shift;

 my $sub = "_$what";
 
 $class = $what;
 
 logit ( "check $what" );
 
 $skip = 0; $fail = 0;
 

 {
  
  no strict 'refs';
  
  $sub->();
 
 }
 
 $dbc->do ( 'insert into cclass values (?,?,?,?)', undef, $class, $phase++, $fail, $skip ); 


}

sub check_end { $dbc->commit }


1;
