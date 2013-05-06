#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2013 Heikki Siltala
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

use strict;
use warnings;
use 5.16.2;

use parent 'Exporter';

# The external interface is prodecural method calls
our @EXPORT = qw ( setup_init setup_keys setup_values setup_default );

use Const::Fast;

#
# the base system setup array that should be
# edited only very seldom and with a MAXIMUM care
#

const my $CONF => [
 { name => 'palette',   values => [ qw ( dark neutral bright ) ] },
 { name => 'perpage',   values => [ qw ( 10 15 20 25 30 35 40 45 50 ) ] },
 { name => 'thumbsize', values => [ qw ( 100 125 150 175 200 ) ] },
 { name => 'display',   values => [ qw ( none text basic full ) ] },
 { name => 'photosize', values => [ qw ( original fit ) ] },
 { name => 'peek',      values => [ qw ( off on ) ] }
];

# use Devel::Size qw ( total_size); say total_size $CONF;
# 2010-10-25: 2302 bytes

# the default setup

const my $DEFAULT => '123321';

# the names of the setup keys in correct order

const my $SETKEYS => [ map { $_->{ name } } @$CONF ];

# generate all valid setups beforehand at compile time
# easy to test setups and to process them to stash

my $init = {};

foreach my $a ( 0 .. $#{ $CONF->[ 0 ]->{ values } } ) {
 foreach my $b ( 0 .. $#{ $CONF->[ 1 ]->{ values } } ) {
  foreach my $c ( 0 .. $#{ $CONF->[ 2 ]->{ values } } ) {
   foreach my $d ( 0 .. $#{ $CONF->[ 3 ]->{ values } } ) {
    foreach my $e ( 0 .. $#{ $CONF->[ 4 ]->{ values } } ) {
     foreach my $f ( 0 .. $#{ $CONF->[ 5 ]->{ values } } ) {
      $init->{ $a + 1 . $b + 1 . $c + 1 . $d + 1 . $e + 1 . $f + 1 } = 1;
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

foreach my $i ( 0 .. $#{ $CONF } ) {

 foreach my $j ( 0 .. $#{ $CONF->[ $i ]->{ values } } ) {

  foreach my $old ( keys %{ $init } ) {

   my $new = '';

   foreach my $x ( 0 .. $#{ $CONF } ) {

    if   ( $i == $x ) { $new .= ( $j + 1 ) }               # change
    else              { $new .= substr ( $old, $x, 1 ) }

   }

   defined $list->{ $old . $CONF->[ $i ]->{ name } }
    or $list->{ $old . $CONF->[ $i ]->{ name } } = [];     # initialize

   push @{ $list->{ $old . $CONF->[ $i ]->{ name } } },
    $CONF->[ $i ]->{ values }->[ $j ];

   push @{ $list->{ $old . $CONF->[ $i ]->{ name } } },
    $new ne $DEFAULT ? $new : '';

  } ## end foreach my $old ( keys %{ $init...})

 } ## end foreach my $j ( 0 .. $#{ $CONF...})

} ## end foreach my $i ( 0 .. $#{ $CONF...})

# use Devel::Size qw ( total_size); say total_size $list;
# 2010-10-28 4295412 bytes

sub setup_init {

 # initialize the setup to application application stash

 my $app = shift;
 my $config = shift // $DEFAULT;

 $init->{ $config } or return 0;

 foreach my $i ( 0 .. $#{ $CONF } ) {

  $app->{ stash }->{ $CONF->[ $i ]->{ name } } =
   $CONF->[ $i ]->{ values }->[ int ( substr ( $config, $i, 1 ) ) - 1 ];

 }
 1;

}

sub setup_keys { $SETKEYS }    # get arrayref of all setup keys

sub setup_values { $list }     # get change struct

sub setup_default { $DEFAULT }

1;
