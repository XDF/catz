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

# unbuffered outputs
# from http://perldoc.perl.org/functions/open.html
select STDERR; $| = 1; 
select STDOUT; $| = 1; 

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new( 'Catz::Core::App' );

$t->max_redirects( 3 );

foreach my $lang ( qw ( en fi en264312 fi384322 ) ) {

 $t->get_ok("/$lang/viz/dist/20/30/40/20011012123456/")
  ->status_is(200)
  ->content_type_like(qr/image\/png/);
  
 $c += 3;

 $t->get_ok("/$lang/viz/rank/iso/ISO_1600/20011012123456/")
  ->status_is(200)
  ->content_type_like(qr/image\/png/);
  
 $c += 3;
 
 $t->get_ok("/$lang/viz/rank/breed/ACS/20011012123456/")
  ->status_is(200)
  ->content_type_like(qr/image\/png/);
  
 $c += 3;

 $t->get_ok("/$lang/viz/rank/loc/Espoo/20011012123456/")
  ->status_is(200)
  ->content_type_like(qr/image\/png/);
  
 $c += 3;

 $t->get_ok("/$lang/viz/globe/20011012123456/")
  ->status_is(200)
  ->content_type_like(qr/image\/png/);
  
 $c += 3;
 
}

done_testing($c);