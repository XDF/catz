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

package Catz::Core::DB;

# extending DBI is not recommended
# so we need a separate class to act as a database

use 5.10.0; use strict; use warnings;

use DBI;

use Catz::Core::Cache;
use Catz::Core::Conf;

my $cacheon = conf ( 'cache_db' );

sub new {

 my ( $class, $version ) = @_;
   
 my $db = DBI->connect (
  conf ( 'dbconn' ) . conf ( 'path_db' ) . "/$version.db",
  undef, undef, conf( 'dbargs_runtime' )
 ) || die ( $DBI::errstr );
 
 my $self = { version => $version, db => $db, cache => -1 };
 
 bless ( $self, $class );

 return $self;
 
}

sub DESTROY { $_[0]->disconnect }

sub disconnect {

 my $self = shift;

 $self->{db} and $self->{db}->disconnect;

}

sub run {

 my ( $self, $comm, $sql, @args ) = @_;
 
 my $version = $self->{version}; 
 
 my $res;
 
 $cacheon and do {
 
  # try to get the requested result from the cache
  
  $res = cache_get ( $version, $comm, $sql, @args );
 
  $res and return $res; # if cache hit then done
 
 };

 given ( $comm ) {
  
  when ( 'one' ) { 

   my $arr = $self->{db}->selectrow_arrayref( $sql, undef, @args );
  
   $res = $arr->[0];
  
  }
  
  when ( 'row' ) {
  
   $res = $self->{db}->selectrow_arrayref( $sql, undef, @args );

  }
  
  when ( 'col' ) {
  
   $res = $self->{db}->selectcol_arrayref( $sql, undef, @args );
  
  }
  
  when ( 'all' ) {
  
   $res = $self->{db}->selectall_arrayref( $sql, undef, @args );
  
  }
 
  default { die "unknown database command '$comm'" }
 
 }

 $cacheon and cache_set ( $version, $comm, $sql, @args, $res, $self->{cache} );
  
 return $res;

}



1; 