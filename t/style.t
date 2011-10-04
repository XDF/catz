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

use 5.10.0; use strict; use warnings;

use Test::More;
use Test::Mojo;

use Catz::Data::Style;

use Catz::Util::String qw ( enurl );
    
my $t = Test::Mojo->new( 'Catz::Core::App' );

my $c = 0;

my $style = style_get;

# reset

$t->get_ok('/style/reset/')
  ->status_is(200)
  ->content_type_like(qr/text\/css/)
  ->content_like(qr/Yahoo/)
  ->content_like(qr/border-collapse/);
  
$c += 5;

# palettes

foreach my $palette ( qw ( dark neutral bright ) ) {

 # prepare 2 palette-specific string to check for

 my $pattern1 = 'color: ' . $style->{color}->{$palette}->{text} . ';';
 my $pattern2 = 'background-color: ' . $style->{color}->{$palette}->{shade} . ';';
   
 $t->get_ok("/style/$palette/")
   ->status_is(200)
   ->content_type_like(qr/text\/css/)
   ->content_like(qr/\.xtra/)
   ->content_like(qr/$pattern1/)
   ->content_like(qr/$pattern2/);
   
 $c += 6;
 
 # without slash should be ok
 
 $t->get_ok("/style/$palette")
   ->status_is(200)
   ->content_type_like(qr/text\/css/)
   ->content_like(qr/\.xtra/)
   ->content_like(qr/$pattern1/)
   ->content_like(qr/$pattern2/);
   
 $c += 6;
 
}

# illegal urls

$t->get_ok('/style/')
  ->status_is(404);
  
$c += 2;

$t->get_ok('/style/stupidvalue/')
  ->status_is(404);
  
$c += 2;

$t->get_ok('/style/stupid/values/in/chain/')
  ->status_is(404);
  
$c += 2;

$t->get_ok('/style/'.enurl('?#_;KIJ833i:*').'/')
  ->status_is(404);
  
$c += 2;

done_testing( $c );