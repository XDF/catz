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

package Catz::Model::Base;

# the base class for all Models

use 5.12.0; use strict; use warnings;

use DBI;
use Time::HiRes qw ( time );

use Catz::Data::Cache;

use Catz::Util::Number qw ( fullnum33 round );

my $db = undef; my $currver = 0;

my $time_model = 0; # turns on timing on all model access

my $time_db = 0; # turns on timing on all database access

sub new {

 my $class = shift;
 
 $class =~ /::(\w+)$/;

 my $self = { name => lc($1) };
 
 bless ( $self, $class );
 
 $self->{lang} = undef;
   
 return $self;
 
}

sub fetch {

 my ( $self, $newver, $lang, $sub, @args ) = @_;
 
 length ( $newver ) == 14 or 
  die 'invalid version on fetch ' . ( join ' ', @_ );  

 $self->{lang} = $lang;

 if ( $currver ne $newver ) {
 
   # version change -> change db
   
   defined $db and $db->disconnect;
 
   $db = DBI->connect (
    'dbi:SQLite:dbname='.$ENV{MOJO_HOME}."/db/$newver.db",
     undef, undef, { AutoCommit => 1, RaiseError => 1, PrintError => 1 }
    ) || die ( $DBI::errstr );
    
   # sequence
   $db->func( 'fullnum33', 2, \&fullnum33, 'create_function' );
     
   # store the new version as current version
   
   $currver = $newver;
 
 }
       
 { no strict 'refs'; return $self->$sub( @args ) }
   
}


sub AUTOLOAD {

 my ( $self, @args ) = @_;

 my $nspace = 'model'; 

 our $AUTOLOAD; my $sub = $AUTOLOAD; $sub =~ s/.*://;
  
 substr ( $sub, 0, 1 ) eq '_' and 
  die "recursive autoload prevented when calling sub '$sub'";

 my $start; my $end;
 
 $time_model and $start = time();
 
 my $res = cache_get ( 
  $currver, $nspace, $self->{lang}, $self->{name}, $sub, @args 
 ); 
 
 $res and do {
 
  $time_model and $end = time();
 
  $time_model and warn "MODEL $self->{name} $sub -> " . round ( ( ( $end - $start ) * 1000 ), 0 ) . ' ms (cached)';
   
  return $res; # if cache hit then done
  
 };
  
 my $target = '_' . $sub;
   
 { no strict 'refs'; $res = $self->$target( @args ) }
  
 $time_model and $end = time();
 
 $time_model and warn "MODEL $self->{name} $sub -> " . round ( ( ( $end - $start ) * 1000 ), 0 ) . ' ms (real)';
  
 cache_set ( 
  $currver, $nspace, $self->{lang}, $self->{name}, $sub, @args, $res
 );
 
 return $res;

}

sub db_run {

 my ( $self, $comm, $sql, @args ) = @_;
 
 my $nspace = 'db';

 my $start; my $end;
 
 $time_db and $start = time();
  
 my $res = cache_get ( $currver, $nspace, $comm, $sql, @args );
 
 $res and do {
 
  $time_db and $end = time();
 
  $time_db and warn "DB $comm $sql -> " . round ( ( ( $end - $start ) * 1000 ), 0 ) . ' ms (cached)' ;
 
  return $res; # if cache hit then done
  
 };
 
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

 $time_db and $end = time();
 
 $time_db and warn "DB $comm $sql -> " . round ( ( ( $end - $start ) * 1000 ), 0 ) . ' ms (real)' ;

 # at database level we currently use infinite caching 
 cache_set (  $currver, $nspace, $comm, $sql, @args, $res );
  
 return $res;

}

sub dball { my $self = shift; $self->db_run ( 'all', @_ ) }

sub dbrow { my $self = shift; $self->db_run ( 'row', @_ ) }

sub dbcol { my $self = shift; $self->db_run ( 'col', @_ ) }

sub dbone { my $self = shift; $self->db_run ( 'one', @_ ) }

sub dbhash {my $self = shift; $self->db_run ( 'hash', @_ ) }

sub DESTROY {

 $db and $db->disconnect;

}

1;

