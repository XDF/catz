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

use 5.12.0;
use strict;
use warnings;

# unbuffered outputs
# from http://perldoc.perl.org/functions/open.html
select STDERR;
$| = 1;
select STDOUT;
$| = 1;

use Test::More;
use Test::Mojo;

use Catz::Data::Conf;
use Catz::Load::Data qw ( loc );

use Catz::Util::String qw ( enurl ucc );
use Catz::Util::Time qw ( dtexpand );

my $t = Test::Mojo->new ( conf ( 'app' ) );

$t->ua->max_redirects ( 0 );

my @oklangs = qw ( en fi );

my @oksetups = qw ( en394211 fi211111 );

my @okfolders = qw (
 20040801helsinki 20070708kempele 20070708KEMPELE 20110910kemio 20110910kemiö
);

my @badfolders =
 qw ( 20040805utsjoki 2007070!kem%%le /20070808@AKKE''.mpele );

my $lang;

sub splitf {

 $_[ 0 ] =~ m|^(.{8})(.+)$|;

 my $date = $1;
 my $loc  = $2;

 my $datel = dtexpand ( $date, 'en' );

 return ( ( enurl $date ), ( enurl $datel ), ( enurl $loc ) );

}

# with no language
$t->get_ok ( "/bulk/photolist/" )->status_is ( 404 );

# with setup and that is not allowed
foreach my $setup ( @oksetups ) {

 $t->get_ok ( "/$setup/bulk/photolist/" )->status_is ( 404 );

}

$lang = @oklangs[ rand @oklangs ];

$t->get_ok ( "/$lang/bulk/photolist/" )->status_is ( 200 )
 ->content_type_like ( qr/text\/plain/ )->content_like ( qr/\.JPG/ );

# no ending slash -> redirect
$t->get_ok ( "/$lang/bulk/photolist" )->status_is ( 301 );

# then with folder definitions
foreach my $data ( @okfolders ) {

 my ( $date, $datel, $loc ) = splitf $data;

 foreach my $d ( ( $date, $datel ) ) {

  $lang = @oklangs[ rand @oklangs ];

  $t->get_ok ( "/$lang/bulk/photolist?d=$d&l=$loc" )->status_is ( 200 )
   ->content_type_like ( qr/text\/plain/ )->content_like ( qr/\.JPG/ );

  # just date parameter
  $t->get_ok ( "/$lang/bulk/photolist?d=$d" )->status_is ( 404 );

 }

 # just location parameter
 $t->get_ok ( "/$lang/bulk/photolist?l=$loc" )->status_is ( 404 );

}

# a few bad folders -> 404 expected
foreach my $data ( @badfolders ) {

 my ( $date, $datel, $loc ) = splitf $data;

 foreach my $d ( ( $date, $datel ) ) {

  $lang = @oklangs[ rand @oklangs ];

  $t->get_ok ( "/$lang/bulk/photolist?d=$d&l=$loc" )->status_is ( 404 );

 }
}

done_testing;
