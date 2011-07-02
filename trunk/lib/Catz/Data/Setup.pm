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

use strict; use warnings; use 5.10.0;

use parent 'Exporter';

use Bit::Vector;

use POSIX qw ( ceil );

# The external interface is prodecural method calls

our @EXPORT = qw ( setup_init setup_keys setup_values );

#
# the system configuration array that should be 
# edited only very seldom and with a MAXIMUM care
#

#
# each set consists of 
#  configuration key, possible values and the default value's position
#

my $conf = [
 { name => 'palette', values => [ qw ( dark neutral bright ) ] },
 { name => 'perpage', values => [ qw( 10 15 20 25 30 35 40 45 50 ) ] },
 { name => 'thumbsize', values => [ qw ( 100 125 150 175 200 ) ] },
 { name => 'display', values => [ qw ( none brief full ) ] },
 { name => 'photosize', values => [ qw ( original fit ) ] },
 { name => 'peek', values => [ qw ( off on ) ] }
];

my $default = '123321';
 
my $setkeys = [ map { $_->{name} } @$conf ];

# generate all configurations beforehand at compile time

# for initialization: config -> values
# size (Devel::Size) 550 kB 2011-07-02 
my $init = {};

foreach my $a ( 0 .. $#{ $conf->[0]->{values} } ) {
 foreach my $b ( 0 .. $#{ $conf->[1]->{values} } ) {
  foreach my $c ( 0 .. $#{ $conf->[2]->{values} } ) {
   foreach my $d ( 0 .. $#{ $conf->[3]->{values} } ) {
    foreach my $e ( 0 .. $#{ $conf->[4]->{values} } ) {
     foreach my $f ( 0 .. $#{ $conf->[5]->{values} } ) {
      $init->{ $a+1 . $b+1 . $c+1 . $d+1 . $e+1 . $f+1 } =
       [ 
        $conf->[0]->{values}->[$a],
        $conf->[1]->{values}->[$b],
        $conf->[2]->{values}->[$c],
        $conf->[3]->{values}->[$d],
        $conf->[4]->{values}->[$e],
        $conf->[5]->{values}->[$f] 
      ];
     } 
    }
   }
  }
 }
} 

# for changes: key -> new value -> old config -> new config
# size (Devel::Size) 2,1 MB 2011-07-02 
my $list = {};

foreach my $i ( 0 .. $#{ $conf } ) {
 
 foreach my $j ( 0 .. $#{ $conf->[$i]->{values} } ) {
 
  foreach my $old ( keys %{ $init } ) {
 
   my $new = ''; 
 
   foreach my $x ( 0 .. $#{ $conf } ) {
   
    if ( $i == $x ) { # change
  
      $new .= ( $j + 1 );
    
    } else { # plain copy
    
      $new .= substr ( $old, $x, 1 );
    }
    
   }
      
   $list
    ->{ $conf->[ $i ]->{name} }
    ->{ $conf->[ $i ]->{values}->[ $j ] }
    ->{ $old }
    = $new ne $default ? $new : '';
   
  } 
 
 }
 
}

sub setup_init { # initialize the setup to application stash

 my $app = shift; # Mojolicious application
 
 my $langa = shift; # the full lang & config string
 
 my $config = $default;
 
 if ( length $langa == ( 2 + scalar @{ $conf } ) ) {
 
  # langa has lang + configuration 
 
   $config = substr ( $langa, 2 );
   
 }
 
 if ( $init->{$config} ) { # config key is ok 
 
  foreach my $i ( 0 .. $#{ $conf } ) {
 
   $app->{stash}->{ $conf->[ $i ]->{name} } = $init->{$config}->[ $i ];
   
  }
  
  return 1; # success

 } else { return 0 } # init failed
  
}


# get arrayref of all setup keys
sub setup_keys { [ map { $_->{name} } @$conf ] };

sub setup_values { 

 # generates lists of setup values and change targets
 # uses directly application stash variable $langa
 
 my $langa = shift; # the full lang & config string
 
 my $config = $default;
 
 my $lang = $langa;
 
 if ( length $langa == ( 2 + scalar @{ $conf } ) ) {
 
  # langa has lang + configuration 
 
   $config = substr ( $langa, 2 );
   
   $lang = substr ( $langa, 0, 2 );
   
 }
   
 my $out = {};
  
 foreach my $i ( 0 .. $#{ $conf } ) {
 
  my @one = ();
  
  foreach my $j ( 0 .. $#{ $conf->[ $i ]->{values} } ) {
     
   push @one, [ 
    $conf->[ $i ]->{values}->[ $j ], 
    $lang .
    $list->{$conf->[$i]->{name}}->{$conf->[$i]->{values}->[$j]}->{$config}
   ]; 
   
  }
   
  $out->{$conf->[$i]->{name}} = \@one;

 }
  
 return $out;

}

1; 