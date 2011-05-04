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

our @EXPORT = qw ( setup_init setup_exit setup_set setup_values setup_verify );


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

my $MAXKEY = 50; # maximum lenght of a setup key
my $MAXVAL = 50; # maximum lenght of a setup value

sub setup_init {

 # read incoming cookies and populate stash from them or from default values

 my $app = shift;

 foreach my $key ( @keys ) {

  my $val = $app->cookie ( $key );

  if ( $val and ( length ( $val ) < 51 ) and $ok->{$key}->{$val} ) {

   $app->stash->{ $key } = $val; # value from cookie

  #warn ( "-> $key = $val from cookie" ); 

  } else {

   $app->stash->{$key} = $defaults->{ $key }; # default value

   #warn ( "-> setting up $key from defaults" ); 
  } 

 }

 my $val = $app->cookie ( 'dt' );

 $val and $val =~ /^d{14}$/ and $app->stash->{ 'dt' } = $val;
 
}

sub setup_exit {

 my $app = shift;

 foreach my $key ( @keys ) {

  if ( $stash->{$key} and ( $stash->{$key} ne $defaults->{key} ) ) {
   
   $app->cookie ( $key => $val, { path => '/' } );
 
  }

 }

 $stash->{dt} and $app->cookie ( 'dt' => $stash->{dt} );

}

sub setup_set {

 my ( $app, $key, $val ) = @_;

 if ( 
  $key and 
  $val and 
  ( length ( $key ) < $MAXKEY ) and 
  ( length ( $val ) < $MAXVAL ) and 
  $ok->{$key}->{$val} 
 ) {

  $app->cookie ( $key => $val, { path => '/' }  );
 
  return 1; # OK

 }

 if ( $key and $key eq 'dt' ) {

   $val eq '0' and do {
    $app->stash->{ 'dt' } = $val;
    return 1; # OK
   }; 

   $val =~ /^\d{14}$/ and do {
    $app->stash->{ 'dt' } = $val;
    return 1; # OK
   }; 

  }
  
  #warn ( "key $key val $val" ); 
  return 0; # FAILED 
}

sub setup_values {

 # return a values list as arrayref for one setup key 

 defined $values->{ $_[0] } and return $values->{ $_[0] };
 
 return undef;  
 
}

sub setup_verify {

 ( $_[0] and $_[1] ) or return 0;

 length ( $_[0] ) > $MAXKEY and return 0;
 length ( $_[1] ) > $MAXVAL and return 0; 

 $ok->{$_[0]}->{$_[1]} 
 
};

1;