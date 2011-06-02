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

use 5.10.0; use strict; use warnings;

use parent 'Exporter';

our @EXPORT = qw ( setup_default setup_init setup_set setup_values setup_verify setup_keys );

use List::MoreUtils qw ( any );

use Catz::Core::Conf;

my $default = {
 display => 'full',
 palette => 'neutral',
 photosize => 'fit',
 perpage => 20,
 thumbsize => 150,
 # peek is special default key in $default, not in $values
 peek => 0, # the forced data version
  
};

my $values = {
 display => [ qw ( none brief full ) ], 
 palette => [ qw ( dark neutral bright ) ],
 photosize => [ qw ( fit original ) ],
 perpage => [ qw( 10 15 20 25 30 35 40 45 50 ) ],
 thumbsize => [ qw ( 100 125 150 175 200 ) ],
};

sub setup_default { $default->{$_[0]} }
      
sub setup_verify  {

 # check that a single value is ok, 1 = ok, 0 = not ok
 
 my ( $key, $val ) = @_;
 
 ( length $key > 50 or length $val > 50 ) and return 0; # preliminary check
 
 if ( $key eq 'peek' ) { # peek gets special handling
 
  # if value is ok and such a database file is found then return 1 = ok
  ( $val eq '0' or ( $val =~ /^\d{14}$/ and 
   -f ( conf ( 'path_db' ) . "/$val.db" ) ) ) and return 1; 
    
  return 0; # 0 = not ok
 
 } else { # standard handling for all the rest
 
  exists $values->{$key} and ( any { $val eq $_ } @{ $values->{$key} } )
   and return 1;
   
  return 0; 
  
 } 

}

sub setup_init {

 # check that session values are ok and if needed populate them with defaults

 my $app = shift;
 
 foreach my $key ( keys %{ $default } ) {
 
  my $val = $app->session ( $key ) // ''; # read from session
  
  if ( setup_verify ( $key, $val ) ) { # if key-value -pair is ok...
  
   $app->stash->{$key} = $val; # ...copy to stash
  
  } else {
  
   $app->session ( $key => $default->{$key} ); # set the default...
   $app->stash->{$key} = $default->{$key}; # ...and also stash
  
  } 
 
 }
 
 # set version & checked to 0 if not at all set 
 $app->session ( version => $app->session ( 'version' ) // '0' );
 $app->session ( checked => $app->session ( 'checked' ) // '0' );
  
  
}

sub setup_set {
 
 # set one key-value -pair 

 my ( $app, $key, $val ) = @_;

 # if the pair verifies ok, then set session and return 1 = ok
 setup_verify ( $key, $val ) and do { $app->session( $key => $val ); return 1 };
  
 return 0; # = not ok

}
  
sub setup_keys { keys %{ $values } } # return all key names as array

sub setup_values { $values } # return hashref of all possible values 

1;