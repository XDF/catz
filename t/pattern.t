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

use Catz::Util::String qw ( enurl );

my $t = Test::Mojo->new( 'Catz::Core::App' );

my $c = 0;

# searches that return photos

my @ok = (
 'a',
 '"n 22"',
 'mimosa',
 'mimosan',
 'Ipekkedinin',
 '"Ipekkedinin Birinci Bebek"',
 '"Ipe*edin* B?r?nc? *bek"',
 '+MCO d e f -22 -2',
 '-22 aby rag ben +n',
 '+text="* panel*"',
 '+*a??a* +A?? -AB?',
 '+breeder=Mi* date=2010* date=2009* date=2008*',
 'album="Kiss?liiton Vuoden kissa*"',
 '+nick=RäpsY',
 '-nick=RäpsY',
 '+nick=ÖRPPI',
 '*""Toykiller""*'
);

# searches that return no photos

my @non = (
 'oipqwpoiwpoeri',
 'mimosanz',
 'Ipekedinn',
 '"Ipekkedi* Bjri?ci Beblek"',
 '+MCO +TUV +CRX +NFO +SRL +n +22 +lens=Sigma* +org=SUROK',
 'date=2001*',
 'album="Kisaliton Vuoden kisa*"',
 '+roska=CRX',
 'album="Tätä näyttelyä ei koskaan ollut*"',
 'kjasd (/#(/)#/)(#) +!"#¤%¤%& -ÅÄÖ+++---ÅÄÖÅÄÖåäöö +?????"'
);

# known good combinations

my @good = (
 '139024?q=mimosan',
 '122005?q=mimosan',
 '014001?q=%2Blens%3Dsigma* %2Borg%3Dsurok %2Bbreed%3Drus',
 '126133?q=%2Btext%3D"* panel*"',
 '126127?q=%2Btext%3D"* panel*"'
);

# known bad combinations

my @bad = (
 '122001?q=mimosan',
 '100008?q=mimosan',
 '123456?q=%2Blens%3Dsigma* %2Borg%3Dsurok %2Bbreed%3Drus',
 '126001?q=%2Btext%3D"* panel*"',
 '121100?q=%2Btext%3D"* panel*"'
);

foreach my $lang ( qw ( en fi en en264311 fi365312 ) ) {

 my $txt = text ( substr ( $lang, 0, 2 ) );
 
 foreach my $init ( @ok ) {
 
  $t->get_ok("/$lang/search?i=".enurl($init))
    ->status_is(200)
    ->content_type_like(qr/text\/html/);
  
  $c += 3;
    
 }
  
 foreach my $mode ( qw ( search display ) ) {
 
  foreach my $uri ( @good ) {
 
   $t->get_ok("/$lang/$mode/$uri")
     ->status_is(200)
     ->content_type_like(qr/text\/html/)
     ->content_like(qr/ alt=\"\[/)
     ->content_like(qr/\.JPG/);
 
   $c += 5;
     
  }
 
  foreach my $uri ( @bad ) {

   $t->get_ok("/$lang/$mode/$uri")->status_is(404);
   
   $c += 2;
      
  }
  
 }

 foreach my $what ( @ok ) {
    
  $t->get_ok("/$lang/search?q=".enurl($what))
    ->status_is(200)
    ->content_type_like(qr/text\/html/)
    ->element_exists('html body div div a img')
    ->content_like(qr/img alt=\"\[/)
    ->content_like(qr/\.JPG/);

  $c += 6;
  
  $t->get_ok("/$lang/display?q=".enurl($what))
    ->status_is(200)
    ->content_type_like(qr/text\/html/)
    ->content_like(qr/ alt=\"\[/)
    ->content_like(qr/\.JPG/);
    
  $c += 5;
  
 }

 foreach my $what ( @non ) {
  
  $t->get_ok("/$lang/search?q=".enurl($what))
    ->status_is(200)
    ->content_type_like(qr/text\/html/)
    ->element_exists('html body div div')
    ->content_like(qr/$txt->{SEARCH_NOTHING}/);
 
  $c += 5;

  $t->get_ok("/$lang/display?q=".enurl($what))
    ->status_is(404);
  
  $c += 2;
      
 }
 
 # now lets be really bad
 
 foreach my $i ( 1 .. 100 ) {
 
  my $elems = int(rand(50)) + 1;
 
  my @patt = ();
  
  foreach ( 1 .. $elems ) {
  
   my $c = 5 + int(rand(50));
  
   push @patt, 
    ( join '', map { chr $_ } map { 32 + int(rand(95)) } ( 1 .. $c ) ); 
  
  }
  
  my $what = join ' ', @patt;
  
  if ( ( length ( $what ) < 1234 ) and ( $c <= 25 ) ) {
    
   $t->get_ok("/$lang/search?q=".enurl($what))
     ->status_is(200)
     ->content_type_like(qr/text\/html/);

    $c += 3;
    
  } else {
  
    $t->get_ok("/$lang/search?q=".enurl($what));

    $c += 1;
  
  }    
 
 }
 
 # empty
 
 $t->get_ok("/$lang/search?q=")->status_is(200); $c += 2;    

 # just spaces
 
 $t->get_ok("/$lang/search?q=".enurl('    '))->status_is(200); $c += 2;    
 
 # huge
 
 my $what = join '', map { 'x' } ( 1 .. 1900 );
 
 $t->get_ok("/$lang/search?q=$what")
   ->status_is(404);
   
 $c += 2;    
 
 # no slash
 
 $t->get_ok("/$lang/search")->status_is(200); $c += 2;

 # alien param
 
 $t->get_ok("/$lang/search?nat=jadsjajsdf")->status_is(200); $c += 2;

}

done_testing($c);