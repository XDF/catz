#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2011 Heikki Siltala
# Licensed under The MIT License
# 
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

use 5.12.0; use strict; use warnings;

# unbuffered outputs
# from http://perldoc.perl.org/functions/open.html
select STDERR; $| = 1; 
select STDOUT; $| = 1; 

use Test::More;
use Test::Mojo;

use Catz::Data::Conf;
use Catz::Data::Style;

use Catz::Util::String qw ( enurl );
    
my $t = Test::Mojo->new( conf ( 'app' ) );

my $style = style_get;

# reset
$t->get_ok('/style/reset/')
  ->status_is(200)
  ->content_type_like(qr/text\/css/)
  ->content_like(qr/Yahoo/)
  ->content_like(qr/border-collapse/);

# no ending slash -> redirect  
$t->get_ok("/style/reset")->status_is(301);

# base stylesheet with all available palettes
foreach my $palette ( sort keys %{ $style->{color} } ) {

 # prepare palette-specific strings to check for

 my $pattern1 = 
  'color: ' . $style->{color}->{$palette}->{text} . ';';
  
 my $pattern2 = 
  'background-color: ' . $style->{color}->{$palette}->{shade} . ';';
   
 $t->get_ok("/style/$palette/")
   ->status_is(200)
   ->content_type_like(qr/text\/css/)
   ->content_like(qr/\.xtra/)
   ->content_like(qr/$pattern1/)
   ->content_like(qr/$pattern2/);
 
 # no ending slash -> redirect
 $t->get_ok("/style/$palette")->status_is(301);
 
}

foreach my $path  ( qw ( 
 /style/ /style/randomtexthere/ /style/more/random/texts/ /style/+++~~~/
) ) {

 $t->get_ok( $path )->status_is(404);
 
}

done_testing;