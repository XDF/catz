#
# The MIT License
# 
# Copyright (c) 1994-2011 Heikki Siltala
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

our @EXPORT = qw ( setup_defaultize setup_verify setup_signature setup_colors setup_values setup_reset );

use List::MoreUtils qw ( any );

# some dummy hard-coded value for initial testing
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
  alt1 => 'FF2222'
   

 },
 bright => {
  canvas => 'EEEEEE',
  text => '000000',
  alt1 => '772211'
 }
};

sub setup_colors { $colors } 

my $defaults = {
 keycommands => 'off', 
 palette => 'bright',
 resize => 'auto',
 thumbsperpage => 15,
 thumbsize => 150,
 comment => 'on',
 camera => 'on',
 result => 'on',
 related => 'on'
};
              
my $values = {
 keycommands => [ qw ( on off ) ], 
 palette => [ qw ( bright dark ) ],
 resize => [ qw ( auto full ) ],
 thumbsperpage => [ qw( 10 15 20 25 30 35 40 45 50 ) ],
 thumbsize => [ qw ( 125 150 175 200 ) ],
 comment => [ qw ( on off ) ],
 camera => [ qw ( on off ) ],
 related => [ qw ( on off ) ],
 result => [ qw ( on off ) ]
};

sub setup_defaultize {
 
 my $app = shift;
 
 foreach my $key ( keys %{ $defaults } ) {

  my $now = $app->session( $key );

  ( defined $now and ( any { $now eq $_ } @{ $values->{$key} } ) ) or
   $app->session( $key => $defaults->{$key} );

  $app->stash->{$key} = $app->session($key);

 }
 
}

sub setup_values {

 return $values;

}

sub setup_verify {

 my ( $key, $value ) = @_;
 
 exists $values->{$key} or return 0;
 
 any { $_ eq $value } @{ $values->{$key} } or return 0;
 
 1;

}

sub setup_reset {

 my $app = shift;

 foreach my $key ( keys %{ $defaults } ) {

  $app->session( $key => $defaults->{$key} );

  $app->stash->{$key} = $app->session($key);

 }

}

 