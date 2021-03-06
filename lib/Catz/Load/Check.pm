#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2013 Heikki Siltala
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

use 5.16.2;
use strict;
use warnings;

use parent 'Exporter';

our @EXPORT = qw ( check_begin check_any check_end );

use Const::Fast;
use DBI;
use Text::LevenshteinXS qw( distance );

use Catz::Util::Log qw ( logadd logclose logopen logit logdone );
use Catz::Util::Number qw ( ceil floor );
use Catz::Util::String qw ( lcc digesthex );

my $dbc;    # static reference to the database

my $phase = 1;    # static test phase counter

my $item = 1;     # static test item counter

my $skip = 0;     # count skipped items

my $fail = 0;     # count failed tests

my $class = undef;    # static storing of the current test

sub check_begin {

 my $dbfile = shift;

 logit ( "connecting database '$dbfile'" );

 $dbc = DBI->connect ( 'dbi:SQLite:dbname=' . $dbfile,
  undef, undef, { AutoCommit => 0, RaiseError => 1, PrintError => 1 } )
  or die "unable to connect to database $dbfile: $DBI::errstr";

 logit ( 'clearing check tables' );
 $dbc->do ( 'delete from crun' );
 $dbc->do ( 'delete from cclass' );
 $dbc->do ( 'delete from citem' );

 logit ( 'initializing check tables' );
 $dbc->do ( 'insert into crun select max(dt) from run' );

 return int ( $dbc->selectrow_array ( 'select dt from crun' ) );

} ## end sub check_begin

const my $JOINER => ';';

sub item {

 # handle a test failure

 my ( $pri, $sec1, $sec2 ) = @_;

 defined $pri or die "internal error: pri not set for an item";

 defined $sec1 or die "internal error: sec not set for an item";

 my $key1 =
  defined $sec2
  ? join $JOINER, ( $class, $pri, $sec1, $sec2 )
  : join $JOINER, ( $class, $pri, $sec1 );

 my $key2 =    # secs in reversed order to catch reversed skip keys
  defined $sec2
  ? join $JOINER, ( $class, $pri, $sec2, $sec1 )
  : undef;

 my $sql = 'select count(*) from mskip where skipkey=?';

 my @args = ( $sql, undef, $key1 );

 defined $key2 and do {

  $sql .= ' or skipkey=?';

  @args = ( $sql, undef, $key1, $key2 );

 };

 my $cnt = int ( $dbc->selectrow_array ( @args ) );

 $cnt > 0 and do { $skip++; return };    # supressed case, skip altogether

 $fail++;                                # yes, this is a test failure

 $dbc->do ( 'insert into citem values (?,?,?,?,?)',
  undef, $class, $item++, $pri, $sec1, $sec2 );

} ## end sub item

sub _breed_exists {

 my @not = @{
  $dbc->selectcol_arrayref (
   qq {
  select sec from sec_en where 
  pid=(select pid from pri where pri='breed') and
  sec not in ( select breed from mbreed ) order by sort; 
 }
  )
  };

 foreach ( @not ) { item ( 'breed', $_ ) }

}

sub _breeder_nation {

 my @not = @{
  $dbc->selectcol_arrayref (
   qq {
  select sec from sec_en where 
  pid=(select pid from pri where pri='breeder') and
  sec not in ( select breeder from mbreeder ) order by sort; 
 }
  )
  };

 foreach ( @not ) { item ( 'breeder', $_ ) }

}

sub _subject_case {

 my @pris = qw ( breeder cat );

 foreach my $pri ( @pris ) {

  my @secs = @{
   $dbc->selectcol_arrayref (
    qq {
   select sec from sec_en where pid=(select pid from pri where pri=?) union 
   select sec from sec_fi where pid=(select pid from pri where pri=?)
  }, undef, $pri, $pri
   )
   };

  my $match = {};

  foreach my $sec ( @secs ) {

   if ( defined $match->{ lcc ( $sec ) } ) {

    push @{ $match->{ lcc ( $sec ) } }, $sec;

   }
   else {

    $match->{ lcc ( $sec ) } = [ $sec ];

   }

  }

  foreach my $key ( keys %{ $match } ) {

   if ( scalar @{ $match->{ $key } } > 1 ) {

    foreach ( 1 .. ( scalar @{ $match->{ $key } } ) - 1 ) {

     item ( $pri, $match->{ $key }->[ 0 ], $match->{ $key }->[ $_ ] );

    }

   }

  }

 } ## end foreach my $pri ( @pris )

} ## end sub _subject_case

sub _subject_approx_1 {

 my $stm = $dbc->prepare (
  qq {
  select sec_en from sec where pid=(select pid from pri where pri=?) and
  sid<>? and substr ( sec_en, 1, 2 )=?
 }
 );

 foreach my $pri ( qw ( breeder cat ) ) {

  my $seena = {};
  my $seenb = {};

  my @secs = @{
   $dbc->selectall_arrayref (
    qq {
   select sid,sec_en from sec where pid=(select pid from pri where pri=?)
  }, undef, $pri
   )
   };

  foreach my $sec ( @secs ) {

   my $head = substr ( $sec->[ 1 ], 0, 2 );

   $stm->execute ( $pri, $sec->[ 0 ], $head );

   foreach my $com ( $stm->fetchrow_array ) {

    my $len = length $sec->[ 1 ];
    my $allow = ceil ( ( $len + 1 ) / 5 );

    if ( distance ( $sec->[ 1 ], $com ) <= $allow ) {

     ( exists $seenb->{ $sec->[ 1 ] } and exists $seena->{ $com } ) or do {

      $seena->{ $sec->[ 1 ] } = 1;
      $seenb->{ $com } = 1;

      item ( $pri, $sec->[ 1 ], $com );

     };

    }

   }

  } ## end foreach my $sec ( @secs )

 } ## end foreach my $pri ( qw ( breeder cat ))

 $stm->finish;

}

sub _subject_approx_2 {

 foreach my $pri ( qw ( breeder cat ) ) {

  my $seena = {};
  my $seenb = {};

  my @secs = @{
   $dbc->selectall_arrayref ( qq {
    select sid,sec_en from sec where 
    pid=(select pid from pri where pri=?)
    order by sid asc
   }, undef, $pri )
  };

  my @coms = ();
  my @idxs = ();
  
  foreach my $row ( @secs ) {
  
   $coms[$row->[0]] = $row->[1];
   
   push @idxs, $row->[0];
  
  }    

  for ( my $i = 0; $i < $#idxs; $i++ ) {
  
   my $idx = $idxs[$i];
   
   for ( my $j = $i + 1; $j <= $#idxs; $j++  ) {
   
    my $jdx = $idxs[$j];

    my $leni = length($coms[$idx]);
    my $lenj = length($coms[$jdx]);
    my $allow = 1;
        
    if ( ( $leni > 10 ) and ( $lenj > 10 ) and ( abs ( $leni - $lenj ) < 2 ) ) {

     if ( distance ( $coms[$idx], $coms[$jdx] ) <= $allow ) {

      ( exists $seenb->{ $coms[$idx] } and exists $seena->{ $coms[$jdx] } ) or do {

       $seena->{ $coms[$idx] } = 1;
       $seenb->{ $coms[$jdx] } = 1;

       item ( $pri, $coms[$idx], $coms[$jdx] );

      };
   
     }
     
    }
  
   }
   
  }

 }

} 

sub _feature_exists {

 my @not = @{
  $dbc->selectcol_arrayref (
   qq {
  select sec from sec_en where 
  pid=(select pid from pri where pri='feat') and
  sec not in ( select feat from mfeat ) order by sort; 
 }
  )
  };

 foreach ( @not ) {
  item ( 'feat', $_ );
 }

}

sub _title_exists {

 my @not = @{
  $dbc->selectcol_arrayref (
   qq {
  select sec from sec_en where 
  pid=(select pid from pri where pri='title') and
  sec not in ( select title from mtitle ) order by sort; 
 }
  )
  };

 foreach ( @not ) {
  item ( 'title', $_ );
 }

}

sub _nation_core_exists {

 my %nats =
  map { $_ => 1 }
  @{ $dbc->selectcol_arrayref ( qq { select nat from mnat } ) };

 my @text = @{
  $dbc->selectcol_arrayref (
   qq { 
  select sec from sec_en where pid=(select pid from pri where pri='text')
  order by sec  
 }
  )
  };

 foreach my $text ( @text ) {

  if ( $text =~ /([A-Z]{2})\*\w/ ) {

   exists $nats{ $1 } or item ( 'nation', $1 );

  }
  elsif ( $text =~ /\w\*([A-Z]{2})/ ) {

   exists $nats{ $1 } or item ( 'nation', $1 );

  }

 }

}

sub _nation_breeder_exists {

 my %nats =
  map { $_ => 1 }
  @{ $dbc->selectcol_arrayref ( qq { select nat from mnat } ) };

 my @nat = 
  @{ $dbc->selectcol_arrayref ( 
   qq { select nat from mbreeder group by nat order by nat } 
  ) }; 

 foreach my $na ( @nat ) {

  exists $nats{ $na } or item ( 'nation', $na );

 }

}

sub check_any {

 my $what = shift;

 my $sub = "_$what";
 $class = $what;

 logit ( "check $what" );

 $skip = 0;
 $fail = 0;

 { no strict 'refs'; $sub->() }    ## no critic

 $dbc->do ( 'insert into cclass values (?,?,?,?)',
  undef, $class, $phase++, $fail, $skip );

}

sub check_end { logit ( 'checking done' ); $dbc->commit; $dbc->disconnect }

1;
