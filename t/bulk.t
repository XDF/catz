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

use Catz::Load::Data qw ( loc );

use Catz::Util::String qw ( enurl ucc );
use Catz::Util::Time qw ( dtexpand );

sub splitf {

 $_[0] =~ m|^(.{8})(.+)$|;
 
 my $date = $1; my $loc = $2;
 
 my $datel = dtexpand ( $date, 'en' );
  
 return ( $date, $datel, $loc );  

}

my $t = Test::Mojo->new( 'Catz::Core::App' );

my $c = 0;

my @ok = qw ( 20040801helsinki 20050220jyvaskyla 20050925orimattila 
20101002porvoo 20060910orimattila 20070707kempele 20070708kempele
20110910kemio 20100307seinajoki 20100327turku );

my @bad = qw (
 20040805helsinki 20030101tampere 99998877roska
 20110504kiiminki 20110919orimattila 20120101stockholm
 jasldkfjalkdjfla 832832833883385555 //%%23_-%X....**
 //%?+23_-%X.&&@@^ /3/%?+523_-a%Xdddu3uJJJJJejjj.&&@@^
);

# no language
$t->get_ok( "/bulk/photolist/" )->status_is(404); $c += 2;

# with setup
$t->get_ok( "/en264311/bulk/photolist/" )->status_is(404); $c += 2;
$t->get_ok( "/fi365312/bulk/photolist/" )->status_is(404); $c += 2;

foreach my $lang ( qw ( en fi ) ) {
 
 $t->get_ok( "/$lang/bulk/photolist" )->status_is(301);  $c += 2;

 $t->get_ok( "/$lang/bulk/photolist/" )
  ->status_is(200)
  ->content_type_like(qr/text\/plain/)
  ->content_like(qr/\.JPG/);
 
 $c += 4; 
  
 foreach my $data ( @ok ) {

  my ( $date, $datel, $loc ) = splitf $data;
 
  $date = enurl ( $date );
  $datel = enurl ( $datel );
  my $loc2 = loc $loc;
  my $loc3 = ucc ( $loc ); 
  $loc = enurl ( $loc );
 
  foreach my $dat ( ( $date, $datel ) ) {

   $t->get_ok( "/$lang/bulk/photolist?d=$dat&l=$loc" )
    ->status_is(200)
    ->content_type_like(qr/text\/plain/)
    ->content_like(qr/\.JPG/); 
  
   $c += 4;
   
   $t->get_ok( "/$lang/bulk/photolist?d=$dat&l=$loc2" )
    ->status_is(200)
    ->content_type_like(qr/text\/plain/)
    ->content_like(qr/\.JPG/); 
  
   $c += 4;

   $t->get_ok( "/$lang/bulk/photolist?d=$dat&l=$loc3" )
    ->status_is(200)
    ->content_type_like(qr/text\/plain/)
    ->content_like(qr/\.JPG/); 
  
   $c += 4;
              
   $t->get_ok( "/$lang/bulk/photolist?d=$dat" )->status_is(404); $c += 2;
  
   $t->get_ok( "/$lang/bulk/photolist?l=$loc" )->status_is(404); $c += 2;
   
  }
   
 }

 foreach my $data ( @bad ) {

  my ( $date, $datel, $loc ) = splitf $data;
 
  $date = enurl ( $date );
  $datel = enurl ( $datel );
  $loc = enurl ( $loc );
 
  foreach my $dat ( ( $date, $datel ) ) { 
 
   $t->get_ok( "/$lang/bulk/photolist?d=$dat&l=$loc" )->status_is(404); $c += 2;
  
   $t->get_ok( "/$lang/bulk/photolist?d=$dat" )->status_is(404); $c += 2;
  
   $t->get_ok( "/$lang/bulk/photolist?l=$loc" )->status_is(404); $c += 2;
   
  }

 }

}    
 
done_testing($c);