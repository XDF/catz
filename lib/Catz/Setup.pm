#
# The MIT License
# 
# Copyright (c) 2010-2011 Heikki Siltala
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
package Catz::Setup;

use parent 'Exporter';
our @EXPORT = qw ( setup_defaultize setup_verify setup_signature setup_colors setup_values setup_reset setup_next setup_prev setup_circ );

use List::MoreUtils qw ( any );

use Data::Dumper;

# just some dummy hard-coded value for initial testing
my $signature = 'o_!+9akjJJ209-*&&';

sub setup_signature { $signature }

 my $color_back  = 'EEEEEE'; 
 my $color_front  = '000000';
 my $color_box1  = 'EEEEEE';
 my $color_box2 = 'EEEEEE';
 my $color_alt1 = 'FFFFFF';
 my $color_alt2 = '772211';

my $colors = {

 dark => {
  canvas => '000000',
  text => 'FFFFFF',
  alt1 => 'BB0505'
 },
 medium => {
  canvas => 'B9B9B9',
  text => '000000',
  alt1 => '772211'
 },

 bright => {
  canvas => 'FFFFFF',
  text => '000000',
  alt1 => '772211'
 },

};

sub setup_colors { $colors } 

my $defaults = {
 keycommands => 'off', 
 palette => 'medium',
 photosize => 'auto',
 thumbsperpage => 15,
 thumbsize => 140,
 comment => 'on',
 camera => 'on',
 result => 'on',
 related => 'on'
};
              
my $values = {
 keycommands => [ qw ( on off ) ], 
 palette => [ qw ( dark medium bright ) ],
 photosize => [ qw ( auto full ) ],
 thumbsperpage => [ qw( 10 15 20 25 30 35 40 45 50 ) ],
 thumbsize => [ qw ( 100 120 140 160 180 200 ) ],
 comment => [ qw ( on off ) ],
 camera => [ qw ( on off ) ],
 related => [ qw ( on off ) ],
 result => [ qw ( on off ) ]
};

# hashrefs containing pre-build previous and next values of setups
my $nexts = {};
my $prevs = {};

# populate $nexts and $prevs
foreach my $key ( keys %{ $values } ) {

 my $i = 0;
 
 my $prev = undef;

 while ( $i < scalar ( @{ $values->{$key} } ) ) {
  
  my $next = $values->{$key}->[$i+1] // undef;  
  
  $nexts->{$key}->{ $values->{$key}->[$i] } = $next;

  $prevs->{$key}->{ $values->{$key}->[$i] } = $prev;

  $prev = $values->{$key}->[$i];
   
  $i++;
  
 }

}

sub setup_next { $nexts->{$_[0]}->{$_[1]} }

sub setup_prev { $prevs->{$_[0]}->{$_[1]} }

sub setup_circ {
 
 defined $nexts->{$_[0]}->{$_[1]} and 
  return $nexts->{$_[0]}->{$_[1]};
  
 $values->{$_[0]}->[0];
   
}

sub setup_defaultize {
 
 my $app = shift;
 
 foreach my $key ( keys %{ $defaults } ) {

  my $now = $app->session( $key );

  ( defined $now and ( any { $now eq $_ } @{ $values->{$key} } ) ) or
   $app->session( $key => $defaults->{$key} );

  $app->stash->{$key} = $app->session($key);

 }
 
}

sub setup_verify {

 my ( $key, $value ) = @_;
 
 exists $values->{$key} or return 0;
 
 any { $_ eq $value } @{ $values->{$key} } or return 0;
 
 1;

}

1;