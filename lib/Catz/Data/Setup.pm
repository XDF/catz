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

use strict; use warnings; use 5.10.0;

use parent 'Exporter';

# The external interface is prodecural method calls
our @EXPORT = qw ( setup_init setup_keys setup_values );

#
# the base system setup array that should be 
# edited only very seldom and with a MAXIMUM care
#

my $conf = [
 { name => 'palette', values => [ qw ( dark neutral bright ) ] },
 { name => 'perpage', values => [ qw( 10 15 20 25 30 35 40 45 50 ) ] },
 { name => 'thumbsize', values => [ qw ( 100 125 150 175 200 ) ] },
 { name => 'display', values => [ qw ( none brief full ) ] },
 { name => 'photosize', values => [ qw ( original fit ) ] },
 { name => 'peek', values => [ qw ( off on ) ] }
];

# use Devel::Size qw ( total_size); say total_size $conf;
# 2010-10-25: 2302 bytes

# the default setup

my $default = '123321';

# the names of the setup keys in correct order
 
my $setkeys = [ map { $_->{name} } @$conf ];

# generate all valid setups beforehand at compile time
# easy to test setups and to process them to stash
 
my $init = {};

foreach my $a ( 0 .. $#{ $conf->[0]->{values} } ) {
 foreach my $b ( 0 .. $#{ $conf->[1]->{values} } ) {
  foreach my $c ( 0 .. $#{ $conf->[2]->{values} } ) {
   foreach my $d ( 0 .. $#{ $conf->[3]->{values} } ) {
    foreach my $e ( 0 .. $#{ $conf->[4]->{values} } ) {
     foreach my $f ( 0 .. $#{ $conf->[5]->{values} } ) {
      $init->{ $a+1 . $b+1 . $c+1 . $d+1 . $e+1 . $f+1 } = 1; 
     } 
    }
   }
  }
 }
}

# use Devel::Size qw ( total_size); say total_size $init;
# 2010-10-28: 98994 bytes 

#
# generate mappings: old setup . key -> [ new value, new setup, ... ]
# at compilation time, easy to pass change effects to controller
#
# it is a two-level structure, a hash of arrays
#
 
my $list = {};

foreach my $i ( 0 .. $#{ $conf } ) {
 
 foreach my $j ( 0 .. $#{ $conf->[$i]->{values} } ) {
 
  foreach my $old ( keys %{ $init } ) {
 
   my $new = ''; 
 
   foreach my $x ( 0 .. $#{ $conf } ) {
   
    if ( $i == $x ) { $new .= ( $j + 1 ) } # change
     else { $new .= substr ( $old, $x, 1 ) }
    
   }
   
   defined $list->{ $old . $conf->[ $i ]->{name} } or
    $list->{ $old . $conf->[ $i ]->{name} } = []; # initialize
          
   push @{ $list->{ $old . $conf->[ $i ]->{name} } }, 
    $conf->[ $i ]->{values}->[ $j ]; 
   
   push @{ $list->{ $old . $conf->[ $i ]->{name} } }, 
    $new ne $default ? $new : '';    
       
  } 
 
 }
 
}

# use Devel::Size qw ( total_size); say total_size $list;
# 2010-10-28 4295412 bytes 

sub setup_init { 

 # initialize the setup to application application stash

 my $app = shift; my $config = shift // $default;
 
 $init->{ $config } or return 0;
   
 foreach my $i ( 0 .. $#{ $conf } ) {
 
  $app->{stash}->{ $conf->[ $i ]->{name} } 
   = $conf->[ $i ]->{values}->[ 
    int ( substr ( $config, $i, 1 ) ) - 1
   ];
   
 } 1;
  
}

sub setup_keys { $setkeys } # get arrayref of all setup keys

sub setup_values { $list } # get change struct 

1; 