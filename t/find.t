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

use Catz::Util::String qw ( enurl );

my $t = Test::Mojo->new( 'Catz::Core::App' );

my @oklangs = qw ( en fi );

# these should return results in both languages
my @oktexts = qw ( 
 i ilt ilta 2 5 201 2011 T TÄHTI Tähti 50mm tassu CRX fish FISH öRppI öRP    
 kää HYVINkää jÄMSä åker surok FIFE FifE tica SIGM mimo imosa f/2 ISO
);

# should return empty result but should still return ok 
my @badtexts = qw ( %$@43IKKKJ MIImUUXxde p;/%lkö-jd ???__Xå++_ );

# english only, finnish bad
my @mixa = qw ( 2010- 2005-07- associati category shorthair );

# finnish only, english bad
my @mixb = qw ( 10.10. 7.2005 yhdistys kategoria lyhytkarva );

foreach my $lang ( @oklangs ) {

 foreach my $find ( map { enurl $_ } @oktexts ) {
  
 $t->get_ok("/$lang/find?s=$find")
   ->status_is(200)
   ->content_type_like(qr/text\/html/)
   ->element_exists('div[class~="rounded"] a');
  
 }
  

 foreach my $find ( map { enurl $_ } @badtexts ) {
  
  $t->get_ok("/$lang/find?s=$find")
   ->status_is(200)
   ->content_type_like(qr/text\/html/)
   ->content_is('');
  
 }
 
 foreach my $mix ( @mixa ) {

  if ( $lang eq 'en' ) {
 
   $t->get_ok("/$lang/find?s=$mix")
    ->status_is(200)
    ->content_type_like(qr/text\/html/)
    ->element_exists('div[class~="rounded"] a');
   
  } else {
 
   $t->get_ok("/$lang/find?s=$mix")
    ->status_is(200)
    ->content_type_like(qr/text\/html/)
    ->content_is(''); 
  }
 
 }
 
 foreach my $mix ( @mixb ) {
 
  if ( $lang eq 'fi' ) {
 
   $t->get_ok("/$lang/find?s=$mix")
    ->status_is(200)
    ->content_type_like(qr/text\/html/)
    ->element_exists('div[class~="rounded"] a');
   
  } else {
 
   $t->get_ok("/$lang/find?s=$mix")
    ->status_is(200)
    ->content_type_like(qr/text\/html/)
    ->content_is(''); 
  } 
 
 }

}

# stress test

foreach my $lang ( @oklangs ) {

 foreach my $i ( 1 .. 50 ) {

  my $c = 20 + int(rand(20));
   
  $t->get_ok("/$lang/find?s=".enurl
   ( join '', map { chr $_ } map { 33 + int(rand(95)) } ( 1 .. $c ) )
   )->content_type_like(qr/text\/html/)
    ->content_is(''); 
  
 }
 
}

done_testing;