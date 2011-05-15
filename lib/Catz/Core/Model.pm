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

use 5.10.0;
use strict;
use warnings;

use Catz::Core::Cache;
use Catz::Core::Conf;
use Catz::Core::DB;

my $cacheon = conf ( 'cache_model' );

sub new {

 my $class = shift;
 
 $class =~ /::(\w+)$/;

 my $self = { name => $1, db => undef, lang => undef };
 
 bless ( $self, $class );
 
 $self->{cache} = $self->cachet;
 
 return $self;
 
}

sub cachetime {

 my ( $self, $sub ) = @_;
 
 $self->{cache}->{$sub} and return $self->{cache}->{$sub};

 return -1;

}

sub cachet {

 my $self = shift;

 {}

}

sub fetch { # the API for Controllers to access Models

 my ( $self, $version, $lang, $sub, @args ) = @_;
 
 # check that DB is initialized and for this data version
 ( $self->{db} and $self->{db}->{version} eq $version ) or do {
 
  # if not, then switch to a fresh database instance
  
  $self->{db} = Catz::Core::DB->new ( $version );
  
 };
     
 $self->{lang} = $lang;
  
 { no strict 'refs'; return $self->$sub( @args ) }
 
   
}

sub DESTROY { }

sub AUTOLOAD {

 my ( $self, @args ) = @_; our $AUTOLOAD;
	
 my $sub = $AUTOLOAD; $sub =~ s/.*://;
  
 substr ( $sub, 0, 1 ) eq '_' and 
  die "recursive autoload short circuit with '$sub'";
  
 my $res;
  
 $cacheon and do { # try to get the requested result from the cache
  
  $res = cache_get ( 
   $self->{name}, $self->{db}->{version}, $self->{lang}, $sub, @args 
  );
 
  $res and return $res; # if cache hit then done
 
 };
 
 my $target = '_' . $sub;
   
 { no strict 'refs'; $res = $self->$target( @args ) }
  
 $cacheon and cache_set ( 
  $self->{name}, $self->{db}->{version}, $self->{lang}, $sub, 
  @args, $res, $self->cachetime ( $sub ) 
 );
 
 return $res;

}

sub dball { my $self = shift; $self->{db}->run ( 'all', @_ ) }

sub dbrow { my $self = shift; $self->{db}->run ( 'row', @_ ) }

sub dbcol { my $self = shift; $self->{db}->run ( 'col', @_ ) }

sub dbone { my $self = shift; $self->{db}->run ( 'one', @_ ) }

1;

