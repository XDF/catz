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
use Catz::Data::Text;

my $t = Test::Mojo->new ( conf ( 'app' ) );

my @oksetups = qw ( en fi );

my @okintents = qw ( contrib margin missing );

my @okpalettes = qw ( dark neutral bright );

foreach my $intent ( @okintents ) {

 foreach my $palette ( @okpalettes ) {

  my $setup = $oksetups[ rand @oksetups ];

  $t->get_ok ( "/$setup/widget/contact/$intent/$palette/" )->status_is ( 200 )
   ->content_type_like ( qr/png/ );

  # no ending slash
  $t->get_ok ( "/$setup/widget/contact/$intent/$palette" )->status_is ( 301 );

 }

}

# illegal intents

$t->get_ok ( "/en/widget/contact/noxious/dark/" )->status_is ( 404 );

$t->get_ok ( "/fi/widget/contact/undef/bright/" )->status_is ( 404 );

# with setup

$t->get_ok ( "/en211211/widget/contact/contrib/neutral/" )->status_is ( 404 );

$t->get_ok ( "/fi171212/widget/contact/missing/bright/" )->status_is ( 404 );

#
# builder (build) and renderer (embed)
#

@oksetups = qw ( en fi en394211 fi211111 en264311 fi365312 );

my @okwsetups = qw (
 c1a2f3l700s140g8 c2a1f2l2000s190g2 c2a2f1l1100s200g4 c3a2f3l1500s50g0
 c1a2f3s140g8 a1f2l2000s190g2 c3 c3a2f3l1500
);

my @badwsetups = qw (
 t1c1f3l700s140g8 t1c2a1f2l2000x190g2 t1c2a2f1l3100s200g4 t2c7a2f3l1500s50g90
);

my $setup;

# testing embed with setup, should lead to an error
$t->get_ok ( "/en394211/embed/c2a2f1l1100s200g4/" )->status_is ( 404 );
$t->get_ok ( "/en394211/embed/nick/Mikke/" )->status_is ( 404 );
$t->get_ok ( "/fi365312/embed/c3?q=%2Blens%3Dsigma*%20%2Borg%3Dsurok%20%2Bbreed%3Drus" )->status_is ( 404 );

foreach my $action ( qw ( build embed ) ) {

 $setup = $oksetups[ rand @oksetups ];
 $action eq 'embed' and $setup = substr ( $setup, 0, 2 );

 # all mode, no ending slash
 $t->get_ok ( "/$setup/$action" )->status_is ( 301 );

 # pair mode, no ending slash
 $t->get_ok ( "/$setup/$action/nick/Mikke" )->status_is ( 301 );

 # all mode
 $t->get_ok ( "/$setup/$action/" )->status_is ( 200 )
  ->content_type_like ( qr/text\/html/ )
  ->content_like ( qr/div id=\"page\"/ );

 # pair mode
 $t->get_ok ( "/$setup/$action/breed/OSH/" )->status_is ( 200 )
  ->content_type_like ( qr/text\/html/ )
  ->content_like ( qr/div id=\"page\"/ );

 $action eq 'embed' and do {

  $t->get_ok ( "/$setup/$action/flen/78_mm/" )->status_is ( 200 )
   ->content_like ( qr/\_LR\.JPG/ );

 };

 # search mode
 $t->get_ok (
  "/$setup/$action?q=%2Bbreeder%3DMi*%20date%3D2011*%20date%3D2010*%20date%3D2001*"
  )->status_is ( 200 )->content_type_like ( qr/text\/html/ )
  ->content_like ( qr/div id\=\"page\"/ );

 foreach my $wsetup ( @okwsetups ) {

  $setup = $oksetups[ rand @oksetups ];
  $action eq 'embed' and $setup = substr ( $setup, 0, 2 );

  # all mode, no ending slash
  $t->get_ok ( "/$setup/$action/$wsetup" )->status_is ( 301 );

  # pair mode, no ending slash
  $t->get_ok ( "/$setup/$action/nick/Mikke/$wsetup" )->status_is ( 301 );

  $t->get_ok ( "/$setup/$action/$wsetup/" )->status_is ( 200 )
   ->content_type_like ( qr/text\/html/ )
   ->content_like ( qr/div id\=\"page\"/ );

  $t->get_ok ( "/$setup/$action/cat/Peku/$wsetup/" )->status_is ( 200 )
   ->content_type_like ( qr/text\/html/ )
   ->content_like ( qr/div id\=\"page\"/ );

  $t->get_ok (
   "/$setup/$action/$wsetup?q=%2Blens%3Dsigma*%20%2Borg%3Dsurok%20%2Bbreed%3Drus"
   )->status_is ( 200 )->content_type_like ( qr/text\/html/ )
   ->content_like ( qr/div id\=\"page\"/ );

 } ## end foreach my $wsetup ( @okwsetups)

 foreach my $wsetup ( @badwsetups ) {

  $setup = $oksetups[ rand @oksetups ];
  $action eq 'embed' and $setup = substr ( $setup, 0, 2 );

  $t->get_ok ( "/$setup/$action/$wsetup/" )->status_is ( 404 );

  $t->get_ok ( "/$setup/$action/cat/Peku/$wsetup/" )->status_is ( 404 );

  $t->get_ok (
   "/$setup/$action/$wsetup?q=%2Blens%3Dsigma*%20%2Borg%3Dsurok%20%2Bbreed%3Drus"
  )->status_is ( 404 );

 }

} ## end foreach my $action ( qw ( build embed ))

done_testing;
