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

our @EXPORT = qw ( 
 setup_init setup_exit setup_set setup_values setup_keys setup_verify 
);

use Catz::Core::Conf;

my $defaults = {
 display => 'full',
 palette => 'neutral',
 photosize => 'fit',
 perpage => 20,
 thumbsize => 150
};

my $values = {
 display => [ qw ( none brief full ) ], 
 palette => [ qw ( dark neutral bright ) ],
 photosize => [ qw ( fit original ) ],
 perpage => [ qw( 10 15 20 25 30 35 40 45 50 ) ],
 thumbsize => [ qw ( 100 125 150 175 200 ) ]
};

my @keys = keys %{ $defaults }; 
      
my $ok = {}; # for simple key vefification

foreach my $key ( @keys ) {

 foreach my $val ( @{ $values->{$key} } ) {
 
  $ok->{$key}->{$val} = 1;
  
 }

}

use constant MAXKEY => 50; # maximum lenght of a setup key
use constant MAXVAL => 50; # maximum lenght of a setup value

sub setup_init {

 # read incoming cookies and populate stash from them or from default values

 my $app = shift;

 foreach my $key ( @keys ) {

  my $val = $app->cookie ( $key );

  if ( 
   $val and ( length ( $val ) < MAXVAL ) and $ok->{$key}->{$val} ) {

   $app->stash->{$key} = $val; # value from cookie

  } else {

   $app->stash->{$key} = $defaults->{ $key }; # default value

  } 

 }

 # reads the version number for peek cookie and uses it's value if present
 # otherwise sets peek to the default value 0

 my $val = $app->cookie ( 'peek' );

 warn "read peek val $val from cookie ".$app->stash->{url};
 
 # inspect the peek cookie value very carefully, even check the file existence
 if ( 
  $val and $val ne '0' and length ( $val ) == 14 and $val =~ /^\d{14}$/ 
  and -f ( conf ( 'path_db' ) . "/$val.db" )
 ) {
 
   warn "cookie val ok";
 
  $app->stash->{peek} = $val;
  
 } else { # the normal production behavior when peek is 0 

 warn "cookie val rejected";

  $app->stash->{peek} = 0;
 
 } 
  
}

sub setup_exit {

 my $app = shift; my $s = $app->{stash};

 foreach my $key ( @keys ) {

  if ( $s->{$key} ) { 
  
   $app->cookie ( $key =>  $s->{$key}, { path => '/' } );
 
  }

 }

 # peek is written out even if it is 0
 $app->cookie ( 'peek' => $s->{peek} );

}

sub setup_set {

 my ( $app, $key, $val ) = @_;

 if ( 
  $key and 
  $val and 
  ( length ( $key ) < MAXKEY ) and 
  ( length ( $val ) < MAXVAL ) and 
  $ok->{$key}->{$val} 
 ) {

  $app->cookie ( $key => $val, { path => '/' }  );
 
  return 1; # OK

 }

 if ( $key and $key eq 'peek' ) {

  length ( $val ) < MAXVAL or return 0; # failed
    
  $val and $val ne '0' and length ( $val ) == 14 and $val =~ /^\d{14}$/ 
  and -f ( conf ( 'path_db' ) . "/$val.db" ) and do {
    
    $app->cookie ( $key => $val, { path => '/' }  );

    return 1; # OK  
  
  };

 }
  
 return 0; # FAILED
  
}

sub setup_keys { \@keys } # return all key names as arrayref

sub setup_values { $values } # return hashref having all keys with all values 

sub setup_verify {

 ( $_[0] and $_[1] ) or return 0;

 length ( $_[0] ) > MAXKEY and return 0;
 length ( $_[1] ) > MAXVAL and return 0; 

 $ok->{$_[0]}->{$_[1]} 
 
};

1;