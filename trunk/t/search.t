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
use Catz::Data::Text;

use Catz::Util::String qw ( enurl );

my $t = Test::Mojo->new ( conf ( 'app' ) );

my @oksetups = qw ( en fi en264311 fi365312 );

my $setup;
my $txt;

# some searches that return photos
my @oksearches = (
 'a',
 '"n 22"',
 'mimosa',
 'Ipekkedinin',
 '"Ipe*edin* B?r?nc? *bek"',
 '+MCO d e f -22 -23',
 '+text="* panel*"',
 '+*a??a* +A?? -AB?',
 '+breeder=Mi* date=2010* date=2009* date=2008*',
 'album="Kiss?liiton Vuoden kissa*"',
 '         +nick=RäpsY  ',
 '+nick=ÖRPPI           ',
 '*""Toykiller""*',
 'cate=4      -cate=1 -cate=2      +cate=3',
 '+id=1???2? +file=EOS*',
);

# searches that don't return photos
my @badsearches = (
 'oipqwpoiwpoeri',
 'Ipekedinn',
 '"Ipekkedi* Bjri?ci Beblek"',
 '+MCO +TUV +CRX +NFO +SRL +n +22 +lens=Sigma* +org=SUROK',
 'date=2001*',
 'album="Kisaliton Vuoden kisa*"',
 '+roska=CRX',
 'album="Tätä näyttelyä ei koskaan ollut*"',
 'kjasd (/#(/)#/)(#) +!"#¤%¤%& -ÅÄÖ+++---ÅÄÖÅÄÖåäöö +?????"',
 'cate=100',
);

# known good search / photo id combinations
my @okcombs = (
 '139024?q=mimosan',
 '014001?q=%2Blens%3Dsigma* %2Borg%3Dsurok %2Bbreed%3Drus',
 '126127?q=%2Btext%3D"* panel*"'
);

# known bad  search / photo id combinations
my @badcombs = (
 '122001?q=mimosan',
 '123456?q=%2Blens%3Dsigma* %2Borg%3Dsurok %2Bbreed%3Drus',
 '121100?q=%2Btext%3D"* panel*"'
);

my $i = 0;

# search main page
foreach my $setup ( @oksetups ) {

 $setup = $oksetups[ rand @oksetups ];
 $txt = text ( substr ( $setup, 0, 2 ) );

 $t->get_ok ( "/$setup/search/" )->status_is ( 200 )
  ->content_type_like ( qr/text\/html/ )->content_like ( qr/$txt->{CATE}/ )
  ->content_like ( qr/$txt->{CODE}/ );

 # no ending slash -> redirect
 $t->get_ok ( "/$setup/search" )->status_is ( 301 );

 # empty search
 $t->get_ok ( "/$setup/search?q=" )->status_is ( 200 )
  ->content_type_like ( qr/text\/html/ )->content_like ( qr/$txt->{CATE}/ )
  ->content_like ( qr/$txt->{CODE}/ );

}

foreach my $mode ( qw ( search display ) ) {

 foreach my $search ( @oksearches ) {

  $setup = $oksetups[ rand @oksetups ];
  $txt = text ( substr ( $setup, 0, 2 ) );

  $mode eq 'search' and do {

   # search page with init parameter
   $t->get_ok ( "/$setup/$mode?i=" . enurl ( $search ) )->status_is ( 200 )
    ->content_type_like ( qr/text\/html/ )->content_like ( qr/$txt->{CATE}/ )
    ->content_like ( qr/$txt->{CODE}/ );
  };

  # browse / view results
  $t->get_ok ( "/$setup/$mode?q=" . enurl ( $search ) )->status_is ( 200 )
   ->content_type_like ( qr/text\/html/ )
   ->content_like      ( qr/alt=\".+\d{6}/ )    # photo alt text
   ->content_like      ( qr/\.JPG/ );

  # with ending slash -> redirect
  $t->get_ok ( "/$setup/$mode/?q=" . enurl ( $search ) )->status_is ( 301 );

 } ## end foreach my $search ( @oksearches)

 foreach my $search ( @badsearches ) {

  my $setup = $oksetups[ rand @oksetups ];
  my $txt = text ( substr ( $setup, 0, 2 ) );

  if ( $mode eq 'search' ) {

   # should display nothing found + instructions
   $t->get_ok ( "/$setup/$mode?q=" . enurl ( $search ) )->status_is ( 200 )
    ->content_type_like ( qr/text\/html/ )->content_like ( qr/$txt->{CATE}/ )
    ->content_like      ( qr/$txt->{CODE}/ )
    ->content_like      ( qr/$txt->{SEARCH_NOTHING}/ );

  }
  else {    # display

   # should give 404 error - can't display a single image
   $t->get_ok ( "/$setup/$mode?q=" . enurl ( $search ) )->status_is ( 404 );

  }

 } ## end foreach my $search ( @badsearches)

 foreach my $search ( @okcombs ) {

  $setup = $oksetups[ rand @oksetups ];
  $txt = text ( substr ( $setup, 0, 2 ) );

  $t->get_ok ( "/$setup/$mode/$search" )->status_is ( 200 )
   ->content_type_like ( qr/text\/html/ )->content_like ( qr/\.JPG/ );

 }

 foreach my $search ( @badcombs ) {

  $setup = $oksetups[ rand @oksetups ];
  $txt = text ( substr ( $setup, 0, 2 ) );

  $t->get_ok ( "/$setup/$mode/$search" )->status_is ( 404 );

 }

 if ( $mode eq 'search' ) {

  my $setup = $oksetups[ 0 ];

  # alien paramers gets completely ignored
  $t->get_ok ( "/$setup/$mode?xyz=jadsjajsdf" )->status_is ( 200 );
  $t->get_ok ( "/$setup/$mode?cat=381238" )->status_is     ( 200 );

 }
 else {    # display

  my $setup = $oksetups[ 1 ];

  # alien paramers -> no results
  $t->get_ok ( "/$setup/$mode?xyz=jadsjajsdf" )->status_is ( 404 );
  $t->get_ok ( "/$setup/$mode?cat=381238" )->status_is     ( 404 );

 }

} ## end foreach my $mode ( qw ( search display ))

# the nasty searches

my @chars =
 ( 'a' .. 'z', 'A' .. 'Z', '0' .. '9', qw (å ä ö Å Ä Ö ? - * @ !) );

foreach ( 1 .. 50 ) {

 $setup = $oksetups[ rand @oksetups ];
 $txt = text ( substr ( $setup, 0, 2 ) );

 my $elems = int ( rand ( 50 ) ) + 1;

 my @patt = ();

 foreach ( 1 .. $elems ) {

  my $c = 5 + int ( rand ( 50 ) );

  push @patt, ( join '', map { $chars[ rand @chars ] } ( 1 .. $c ) );

 }

 my $search = join ' ', @patt;

 if ( ( length ( $search ) < 1234 ) and $elems <= 25 ) {

  $t->get_ok ( "/$setup/search?q=" . enurl ( $search ) )->status_is ( 200 )
   ->content_type_like ( qr/text\/html/ )->content_like ( qr/$txt->{CATE}/ )
   ->content_like      ( qr/$txt->{CODE}/ )
   ->content_like      ( qr/$txt->{SEARCH_NOTHING}/ );

 }

 $t->get_ok ( "/$setup/display?q=" . enurl ( $search ) )->status_is ( 404 );

} ## end foreach ( 1 .. 50 )

done_testing;
