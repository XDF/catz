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
package Catz::Data::Setup;

use parent 'Exporter';

our @EXPORT = qw ( 
 setup_init setup_verify setup_set setup_signature 
 setup_colors setup_values setup_keys setup_pagekey );

use Catz::Data::Conf;        

# local copies based on conf - mostly for fun :-D
# actually they might provide a tiny performance boost

my $ok = {}; # for key vefification

my $defaults = {}; # to get default values

my $values = {}; # to get value lists

my $keys = []; # to get keys 

foreach my $key ( keys %{ conf('setup_defaults' ) } ) {

 push @{ $keys }, $key;

 $defaults->{$key} = conf('setup_defaults')->{$key};
 
 $values->{$key} = conf( 'setup_values' )->{$key};

 foreach my $val ( @{ $values->{$key} } ) {
 
  $ok->{$key}->{$val} = 1;
  
 }

}

sub setup_values {

 # return a values list as arrayref for one setup key 

 defined $values->{ $_[0] } and return $values->{ $_[0] };
 
 return undef;  
 
}

sub setup_keys {

 # return a values list as arrayref for one setup key 

 return $keys;
 
}

sub setup_init {

 # if the value is not set in session or the value is invalid
 # then put the default value to the session 
 
 my $app = shift;
 
 foreach my $key ( @$keys ) {

  my $val = $app->session( $key );

  ( defined $val and setup_verify ( $key, $val ) ) or
   $app->session( $key => $defaults->{$key} );

  # copy all key-value pairs from session to stash
  $app->stash->{$key} = $app->session($key);

 }
 
}

sub setup_set {

 my ( $app, $key, $val ) = @_;
 
 # changes one setup value
  
 setup_verify ( $key, $val ) and do {
  
  # if verify ok then change session data ...
  $app->session( $key => $val );
 
  # ... and stash data  
  $app->stash->{$key} = $val;
  
  # report that the modification was done
  return 1; 
  
 };
 
 return 0; # report that no modification occured 

}

sub setup_verify {

 # verifies a single setup key-value pair

 $ok->{$_[0]}->{$_[1]};
 
}

1;