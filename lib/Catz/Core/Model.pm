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

package Catz::Core::Model;

# the base class for all Models

use 5.10.0; use strict; use warnings;

use DBI;

use Catz::Core::Cache;

my $db =  DBI->connect (
 'dbi:SQLite:dbname='.$ENV{MOJO_HOME}.'/db/master.db',
 undef, undef, { AutoCommit => 1, RaiseError => 1, PrintError => 1 }
) || die ( $DBI::errstr ); 

sub new {

 my $class = shift;
 
 $class =~ /::(\w+)$/;

 my $self = { name => lc($1) };
 
 bless ( $self, $class );
 
 $self->{expire} = $self->expiry;

 $self->{lang} = undef; # default
 
 return $self;
 
}

sub cachetime { $_[0]->{expire}->{$_[1]} ? $_[0]->{expire}->{$_[1]} : 'never' } 

# override this sub to set caching times other than never
sub expiry { {} }

sub fetch {

 my ( $self, $sub, $lang, @args ) = @_;

 # each call to this object sets the language
 $self->{lang} = $lang;
       
 { no strict 'refs'; return $self->$sub( @args ) }
   
}

sub DESTROY { }

sub AUTOLOAD {

 my ( $self, @args ) = @_;

 my $nspace = 'model'; 

 our $AUTOLOAD; my $sub = $AUTOLOAD; $sub =~ s/.*://;
  
 substr ( $sub, 0, 1 ) eq '_' and 
  die "recursive autoload prevented on '$sub'";
 
 my $res = cache_get ( $nspace, $self->{name}, $sub, $self->{lang}, @args ); 
 
 $res and return $res; # if cache hit then done
 
 my $target = '_' . $sub;
   
 { no strict 'refs'; $res = $self->$target( @args ) }
  
 cache_set ( 
  $nspace, $self->{name}, $sub, $self->{lang}, @args, $res, 
  $self->cachetime ( $sub )
 );
 
 return $res;

}

sub db_run {

 my ( $comm, $sql, @args ) = @_;

 my $nspace = 'db';
  
 my $res = 
  cache_get ( $nspace, $comm, $sql, @args );
 
 $res and return $res; # if cache hit then done

 given ( $comm ) {
  
  when ( 'one' ) { 

   my $arr = $db->selectrow_arrayref( $sql, undef, @args );
  
   $res = $arr->[0];
  
  }
  
  when ( 'row' ) {
  
   $res = $db->selectrow_arrayref( $sql, undef, @args );

  }
  
  when ( 'col' ) {
  
   $res = $db->selectcol_arrayref( $sql, undef, @args );
  
  }
  
  when ( 'all' ) {
  
   $res = $db->selectall_arrayref( $sql, undef, @args );
  
  }

  when ( 'hash' ) {
  
   my $kf = shift @args;

   $res = $db->selectall_hashref( $sql, $kf, undef, @args );

   unshift @args, $kf;
  
  }
 
  default { die "unknown database command '$comm'" }
 
 }

 cache_set ( $nspace, $comm, $sql, @args, $res, 'never' );
  
 return $res;

}

sub dball { shift; db_run ( 'all', @_ ) }

sub dbrow { shift; db_run ( 'row', @_ ) }

sub dbcol { shift; db_run ( 'col', @_ ) }

sub dbone { shift; db_run ( 'one', @_ ) }

sub dbhash { shift; db_run ( 'hash', @_ ) }

1;

