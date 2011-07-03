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

use Catz::Core::Text;

use Catz::Util::String qw ( encode enurl );

my $t = Test::Mojo->new( app => 'Catz::Core::App' );

my $c = 0;

# bare root, should do temp redirect

$t->get_ok('/')
  ->status_is(302);
  
$c += 2;

foreach my $lang ( qw ( en fi en211211 fi171212 ) ) {

 my $txt = text ( substr ( $lang, 0, 2 ) );
 
 # front page
   
 $t->get_ok("/$lang/")
   ->status_is(200)
   ->content_type_like(qr/text\/html/)
   ->element_exists('html body h1')
   ->content_like(qr/$txt->{NOSCRIPT}/)
   ->content_like(qr/href=\"\/$lang\/list\/breeder\/a2z\/\"/)
   ->content_like(qr/alt="\[(kuva|photo) \d{6}\]"/)
   ->content_like(qr/\.JPG/);
   
 $c += 8;  
 
 # without slash should do perm redirect
 
 $t->get_ok("/$lang")
   ->status_is(301);
   
 $c += 2;
 
} 

done_testing( $c );