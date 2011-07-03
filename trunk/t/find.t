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

use Catz::Util::String qw ( enurl );

my $t = Test::Mojo->new( app => 'Catz::Core::App' );
                  
my $c = 0;

foreach my $lang ( qw ( en fi ) ) {

 # should return results in both languages

 foreach my $find ( map { enurl $_ } qw (
  i il ilt ilta 2 20 201 2011 T TÄHTI Tähti 50mm tassu CRX fish FISH ÖRppI öRP    
  30 5 kää HYVINkää HyVINkÄÄ jÄMSä åker SUROK surok pirok FIFE FifE TIcA TicA
 ) ) {
  
 $t->get_ok("/$lang/find?s=$find")
   ->status_is(200)
   ->content_type_like(qr/text\/html/)
   ->element_exists('div[class~="rounded"] a');
   
 $c += 4;
  
 }
 
 # also some wildcards should work
 
 foreach my $find ( map { enurl $_ } qw (
  SIGM* ??GMA ??GMA ?rppi ÖRPP? ÖR* *Ö* ??? ???? ????? ?????? mimos? mimo* *san
 ) ) {
  
 $t->get_ok("/$lang/find?s=$find")
   ->status_is(200)
   ->content_type_like(qr/text\/html/)
   ->element_exists('div[class~="rounded"] a');
   
 $c += 4;
  
 }
 
 # should return no results but should still give 200 

 foreach my $find ( map { enurl $_ } qw (
  %$@OIIKKKJ MIIMUUXxde poi%lk%%jd 798_3h_3hj //;;;: -öÅÄÖåäö// ?=?=?=??=
 ) ) {
  
  $t->get_ok("/$lang/find?s=$find")
   ->status_is(200)
   ->content_type_like(qr/text\/html/)
   ->content_is('');
   
  $c += 4;
  
 }
 
 # up to a gigantic length, all values are too long
 
 foreach my $i ( 1 .. 19 ) {
 
  $i *= 100;
 
  my $url = join '', map { 'x' } ( 1 .. $i );
  
  $t->get_ok("/$lang/find?s=$url")
   ->status_is(200)
   ->content_is('');
   
  $c += 3;
    
 }

}

# english specific

$t->get_ok("/en/find?s=".enurl('2010-'))
  ->status_is(200)
  ->content_type_like(qr/text\/html/)
  ->element_exists('div[class~="rounded"] a');
   
$c += 4;

$t->get_ok("/en/find?s=".enurl('2005-07-'))
  ->status_is(200)
  ->content_type_like(qr/text\/html/)
  ->element_exists('div[class~="rounded"] a');
   
$c += 4;

$t->get_ok("/en/find?s=".enurl('association'))
  ->status_is(200)
  ->content_type_like(qr/text\/html/)
  ->element_exists('div[class~="rounded"] a');
   
$c += 4;

$t->get_ok("/en/find?s=".enurl('10.10.'))
  ->status_is(200)
  ->content_type_like(qr/text\/html/)
  ->content_is('');

$c += 4;
   
$t->get_ok("/en/find?s=".enurl('7.2005'))
  ->status_is(200)
  ->content_type_like(qr/text\/html/)
  ->content_is('');

$c += 4;

$t->get_ok("/en/find?s=".enurl('yhdistys'))
  ->status_is(200)
  ->content_type_like(qr/text\/html/)
  ->content_is('');

$c += 4;


# finnish specific

$t->get_ok("/fi/find?s=".enurl('2010-'))
  ->status_is(200)
  ->content_type_like(qr/text\/html/)
  ->content_is('');
   
$c += 4;

$t->get_ok("/fi/find?s=".enurl('2005-07-'))
  ->status_is(200)
  ->content_type_like(qr/text\/html/)
  ->content_is('');
   
$c += 4;

$t->get_ok("/fi/find?s=".enurl('association'))
  ->status_is(200)
  ->content_type_like(qr/text\/html/)
  ->content_is('');
   
$c += 4;

$t->get_ok("/fi/find?s=".enurl('10.10.'))
  ->status_is(200)
  ->content_type_like(qr/text\/html/)
  ->element_exists('div[class~="rounded"] a');

$c += 4;
   
$t->get_ok("/fi/find?s=".enurl('7.2005'))
  ->status_is(200)
  ->content_type_like(qr/text\/html/)
  ->element_exists('div[class~="rounded"] a');

$c += 4;

$t->get_ok("/fi/find?s=".enurl('yhdistys'))
  ->status_is(200)
  ->content_type_like(qr/text\/html/)
  ->element_exists('div[class~="rounded"] a');

$c += 4;

done_testing($c);