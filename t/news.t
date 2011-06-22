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

use lib '../lib';

use Test::More;
use Test::Mojo;

use Catz::Core::Text;

my $t = Test::Mojo->new( app => 'Catz::Core::App' );

my $c = 0;

foreach my $lang ( qw ( en fi ) ) {

 my $txt = text ( $lang );
 
 # news page
   
 $t->get_ok("/$lang/news/")
   ->status_is(200)
   ->content_type_like(qr/text\/html/)
   ->text_is('html body h1'=>$txt->{NEWS_ALL})
   ->content_like(qr/$txt->{NOSCRIPT}/);
 
 $c += 5;
 
 # RSS feed
 
 $t->get_ok("/$lang/feed/")
   ->status_is(200)
   ->content_type_like(qr/xml/)
   ->element_exists('rss[version=2.0]')
   ->text_is('title'=>$txt->{SITE})
   ->element_exists('pubDate');
    
 $c += 6;
 
}

done_testing( $c );