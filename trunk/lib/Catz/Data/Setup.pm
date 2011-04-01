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
our @EXPORT = qw ( setup_defaultize setup_verify setup_set setup_signature setup_colors setup_values );

use List::MoreUtils qw ( any );

#use Data::Dumper;

# just some dummy hard-coded value for initial testing
my $signature = 'o_!+9akjJJ209-*&&';

sub setup_signature { $signature }

#
# Color palettes are developed based on "4-class Pink-Yellow-Green 
# diverging" color scheme of Colorbrewer 2.0
#
# http://colorbrewer2.org/index.php?type=diverging&scheme=PiYG&n=4
#
# Colorbrewer copyright Cynthia Brewer, Mark Harrower and 
# The Pennsylvania State University
# 
# 0xD01C8B; 0xF1B6DA; 0xB8E186; 0x4DAC26;   
#

 my $color_back  = 'EEEEEE'; 
 my $color_front  = '000000';
 my $color_box1  = 'EEEEEE';
 my $color_box2 = 'EEEEEE';
 my $color_alt1 = 'FFFFFF';
 my $color_alt2 = '772211';

my $colors = {

 dark => {
  canvas => '#000000',
  text => '#FFFFFF',
  back1 => '#252525',
  back2 => '#353535',
  back3 => '#454545',
  color1strong => '#4DAC26',
  color1weak => '#B8E186',
  color2strong => '#D01C8B',
  color2weak => '#BF1B6DA',
  
 },

 bright => {
  canvas => '#FDFDFD',
  text => '#000000',
  back1 => '#858585',
  back2 => '#959595',
  back3 => '#A5A5A5',
  color1strong => '#4DAC26',
  color1weak => '#B8E186',
  color2strong => '#D01C8B',
  color2weak => '#BF1B6DA',  
 },

};

sub setup_colors { $colors } 

my $defaults = { 
 palette => 'bright',
 photosize => 'full',
 thumbsperpage => 20,
 thumbsize => 140,
};
              
my $values = { 
 palette => [ qw ( dark bright ) ],
 photosize => [ qw ( full fit_width fit_height fit_all ) ],
 thumbsperpage => [ qw( 10 15 20 25 30 35 40 45 50 ) ],
 thumbsize => [ qw ( 100 120 140 160 180 200 ) ],
};

sub setup_values {

 # return a values list as arrayref for one setup key 

 defined $values->{ $_[0] } and return $values->{ $_[0] };
 
 return undef;  
 
}

sub setup_defaultize {

 # if the value is not set in session or the value is invalid
 # then put the default value to the session 
 
 my $app = shift;
 
 foreach my $key ( keys %{ $defaults } ) {

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
  
 };

}

sub setup_verify {

 # verifies a single setup key-value pair

 my ( $key, $value ) = @_;
 
 exists $values->{$key} or return 0;
 
 any { $_ eq $value } @{ $values->{$key} } or return 0;
 
 return 1;

}

1;