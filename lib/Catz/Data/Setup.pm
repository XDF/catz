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
# Live color palettes developed by Heikki Siltala  based on 
# the Public Domain palette developed by  The Tango Desktop Project 
# http://tango.freedesktop.org/Tango_Desktop_Project
#
# "The Tango Desktop Project exists to create a consistent
# user experience for Open Source software."
#

sub cf { '#' . uc $_[0] }

my $cbase = {
 yellow => [ map { cf ( $_ ) } qw ( fce94f	edd400 c4a000 ) ],
 orange => [ map { cf ( $_ ) } qw ( fcaf3e	f57900 ce5c00 ) ],
 brown => [ map { cf ( $_ ) } qw ( e9b96e c17d11 8f5902 ) ],
 green => [ map { cf ( $_ ) } qw ( 8ae234 73d216 4e9a06 ) ],
 blue => [ map { cf ( $_ ) } qw ( 729fcf	3465a4 204a87 ) ],
 violet => [ map { cf ( $_ ) } qw ( ad7fa8	75507b 5c3566 ) ],
 red => [ map { cf ( $_ ) } qw ( ef2929 cc0000 a40000 ) ],
 gray => [ map { cf ( $_ ) } qw ( 
  ffffff eeeeec d3d7cf babdb6 888a85 555753 2e3436 000000 
 ) ]
};

my $colors = {

 dark => {
  fore => {
   yellow => $cbase->{yellow}->[0],
   orange => $cbase->{orange}->[0],
   brown => $cbase->{brown}->[0],
   green => $cbase->{green}->[0],
   blue => $cbase->{blue}->[0],
   violet => $cbase->{violet}->[0],
   red => $cbase->{red}->[0],
   light => $cbase->{gray}->[1],
   medium => $cbase->{gray}->[2],
   dark => $cbase->{gray}->[3],
   base => $cbase->{gray}->[0],
  },
  back => {
   yellow => $cbase->{yellow}->[2],
   orange => $cbase->{orange}->[2],
   brown => $cbase->{brown}->[2],
   green => $cbase->{green}->[2],
   blue => $cbase->{blue}->[2],
   violet => $cbase->{violet}->[2],
   red => $cbase->{red}->[2],
   light => $cbase->{gray}->[4],
   medium => $cbase->{gray}->[5],
   dark => $cbase->{gray}->[6],
   base => $cbase->{gray}->[7], 
  }   
 },

 bright => {
  fore => {
   yellow => $cbase->{yellow}->[2],
   orange => $cbase->{orange}->[2],
   brown => $cbase->{brown}->[2],
   green => $cbase->{green}->[2],
   blue => $cbase->{blue}->[2],
   violet => $cbase->{violet}->[2],
   red => $cbase->{red}->[2],
   light => $cbase->{gray}->[4],
   medium => $cbase->{gray}->[5],
   dark => $cbase->{gray}->[6],
   base => $cbase->{gray}->[7],
  },
  back => {
   yellow => $cbase->{yellow}->[0],
   orange => $cbase->{orange}->[0],
   brown => $cbase->{brown}->[0],
   green => $cbase->{green}->[0],
   blue => $cbase->{blue}->[0],
   violet => $cbase->{violet}->[0],
   red => $cbase->{red}->[0],
   light => $cbase->{gray}->[2],
   medium => $cbase->{gray}->[3],
   dark => $cbase->{gray}->[4],
   base => $cbase->{gray}->[1], 
  }   
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
  
  # report that the modification was done
  return 1; 
  
 };
 
 return 0; # report that no modification occured 

}

sub setup_verify {

 # verifies a single setup key-value pair

 my ( $key, $value ) = @_;
 
 exists $values->{$key} or return 0;
 
 any { $_ eq $value } @{ $values->{$key} } or return 0;
 
 return 1;

}

1;