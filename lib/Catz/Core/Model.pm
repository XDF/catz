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
use Time::HiRes qw ( time );

use Catz::Core::Cache;
use Catz::Util::Number qw ( round );

my $time_model = 0; # turns on timing on all model access

my $time_db = 0; # turns on timing on all database access

sub new {

 my $class = shift;
 
 $class =~ /::(\w+)$/;

 my $self = { name => lc($1) };
 
 bless ( $self, $class );
 
 $self->{lang} = undef;
 $self->{version} = 0;
 $self->{db} = undef;
   
 return $self;
 
}


sub fetch {

 my ( $self, $version, $lang, $sub, @args ) = @_;

 $self->{lang} = $lang;

 if ( $self->{version} ne $version ) {
 
   # version change -> change db
   
   defined $self->{db} and $self->{db}->disconnect;
 
   $self->{db} = DBI->connect (
    'dbi:SQLite:dbname='.$ENV{MOJO_HOME}."/db/$version.db",
     undef, undef, { AutoCommit => 1, RaiseError => 1, PrintError => 1 }
    ) || die ( $DBI::errstr ); 
 
  $self->{version} = $version;
 
 }
       
 { no strict 'refs'; return $self->$sub( @args ) }
   
}

sub DESTROY { 

 my $self = shift;

 defined $self->{db} and do {
  
  $self->{db}->disconnect; $self->{db} = undef;
   
 };
  
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
  $self->{version}, $nspace, $self->{lang}, $self->{name}, $sub, @args 
 ); 
 
 $res and do {
 
  $time_model and $end = time();
 
  $time_model and warn "MODEL $self->{name} $sub -> " . round ( ( ( $end - $start ) * 1000 ), 0 ) . ' ms';
   
  return $res; # if cache hit then done
  
 };
  
 my $target = '_' . $sub;
   
 { no strict 'refs'; $res = $self->$target( @args ) }
  
 $time_model and $end = time();
 
 $time_model and warn "MODEL $self->{name} $sub -> " . round ( ( ( $end - $start ) * 1000 ), 0 ) . ' ms';
  
 cache_set ( 
  $self->{version}, $nspace, $self->{lang}, $self->{name}, $sub, @args, $res
 );
 
 return $res;

}

sub db_run {

 my ( $self, $comm, $sql, @args ) = @_;
 
 my $nspace = 'db';

 my $start; my $end;
 
 $time_db and $start = time();
  
 my $res = cache_get ( $self->{version}, $nspace, $comm, $sql, @args );
 
 $res and do {
 
  $time_db and $end = time();
 
  $time_db and warn "DB $comm $sql -> " . round ( ( ( $end - $start ) * 1000 ), 0 ) . ' ms' ;
 
  return $res; # if cache hit then done
  
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

  when ( 'hash' ) {
  
   my $kf = shift @args;

   $res = $self->{db}->selectall_hashref( $sql, $kf, undef, @args );

   unshift @args, $kf;
  
  }
 
  default { die "unknown database command '$comm'" }
 
 }

 $time_db and $end = time();
 
 $time_db and warn "DB $comm $sql -> " . round ( ( ( $end - $start ) * 1000 ), 0 ) . ' ms' ;

 # at database level we currently use infinite caching 
 cache_set (  $self->{version}, $nspace, $comm, $sql, @args, $res );
  
 return $res;

}

sub dball { my $self = shift; $self->db_run ( 'all', @_ ) }

sub dbrow { my $self = shift; $self->db_run ( 'row', @_ ) }

sub dbcol { my $self = shift; $self->db_run ( 'col', @_ ) }

sub dbone { my $self = shift; $self->db_run ( 'one', @_ ) }

sub dbhash {my $self = shift; $self->db_run ( 'hash', @_ ) }

1;
