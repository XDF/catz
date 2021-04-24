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

# unbuffered outputs
# from http://perldoc.perl.org/functions/open.html
select STDERR;
$| = 1;
select STDOUT;
$| = 1;

use Test::More;
use Test::Mojo;

use Catz::Data::Conf;

my $t = Test::Mojo->new ( conf ( 'app' ) );

$t->ua->max_redirects ( 5 );

# these include all three palettes
my @oksetups = qw ( en fi en214221 fi372222 );

my $setup;

my @okversions = qw ( 20101012123456 20111019164540 );

my @badversions = qw ( 2010101212345 201110191645403 JJJEJ838j3jkl3jsdsdaf );

my @okcombs = qw (
 dist/10001/10002/10003/10004 dist/14/78/68/2141 dist/11/90/1225/2
 rank/iso/ISO_1600 rank/loc/Espoo rank/cat/Ipekkedinin_Birinci_Bebek
 globe
);

my @badcombs = qw (
 dist/33420/99130/71240 dist/15/10 dist/8 mist/20/30/40
 rank/iso/ISO_40 rank/loc/Tynnyri hank/cat/FireWire_Solo_MAudio_Generic
 blobe ? x 8
);

foreach my $comb ( @okcombs ) {

 $setup = $oksetups[ rand @oksetups ];

 $t->get_ok ( "/$setup/viz/$comb/$okversions[0]/" )->status_is ( 200 )
  ->content_type_like ( qr/image\/png/ );

 $comb =~ m|^dist| and do {

  $t->get_ok ( "/$setup/viz/$comb/$okversions[0]?jmap=1" )->status_is ( 200 )
   ->content_type_like ( qr/text\/plain/ );    # json data but as text

 };

}

foreach my $comb ( @badcombs ) {

 $setup = $oksetups[ rand @oksetups ];

 $t->get_ok ( "/$setup/viz/$comb/$okversions[1]/" )->status_is ( 404 );

}

foreach my $version ( @badversions ) {

 $setup = $oksetups[ rand @oksetups ];

 foreach my $comb ( @okcombs ) {

  $t->get_ok ( "/$setup/viz/$comb/$version/" )->status_is ( 404 );

 }

}

done_testing;
