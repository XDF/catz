#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2019 Heikki Siltala
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

use 5.16.2;
use strict;
use warnings;

do '../script/core.pl';

# to give the test cases enough time to run
# on slow development environment
$ENV{'MOJO_INACTIVITY_TIMEOUT'} = 60;

# unbuffered outputs
# from http://perldoc.perl.org/functions/open.html
select STDERR;
$| = 1;
select STDOUT;
$| = 1;

use Test::More;
use Test::Mojo;

use Catz::Data::Conf;
use Catz::Data::Text;

my $t = Test::Mojo->new ( conf ( 'app' ) );

my @oklangs = qw ( en fi );

my $txt = text ( 'en' );

my $i = 0;

foreach my $map ( qw ( index core news list pair photo browse ) ) {

 my $lang = $oklangs[ $i++ % 2 ];
 $lang = $map eq 'index' ? '' : "/$lang";

 $t->get_ok ( "$lang/sitemap/$map/" )->status_is ( 200 )
  ->content_type_like ( qr/xml/ )->content_like ( qr/$txt->{URL_CATZA}/ );

 # without trailing slash
 $t->get_ok ( "$lang/sitemap/$map" )->status_is ( 301 );

 $map ne 'index' and do { 
  # with setup
  $t->get_ok ( $lang."394211/sitemap/$map/" )->status_is ( 404 );
 };
  
}

done_testing;
