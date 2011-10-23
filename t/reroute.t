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

my $t = Test::Mojo->new( 'Catz::Core::App' );

$t->max_redirects( 2 );

my $txt = text ( 'en' );

# paths that should lead to front page 
foreach my $path ( qw ( 
 / /index.htm /index.html /stat /stat/ /stat/index.htm /stat/index.html
 /bestofbest /bestofbest/ /bestofbest/index.htm /bestofbest/index.html
 /bestofbest/0001.html /bestofbest/0005.html /bestofbest/0033.html 
) ) {

 $t->get_ok("/reroute$path")
   ->status_is(200)
   ->content_type_like(qr/text\/html/)
   ->content_like(qr/$txt->{NOSCRIPT}/)
   ->content_like(qr/$txt->{SLOGAN}/);

}

# paths that should lead to lists
foreach my $path ( qw ( 
 /dates.htm /dates.html /locations.htm /locations.html /breeders /breeders/ 
 /breeders/index.htm /breeders/index.html /ems/breeders.htm /ems/breeders.html
 /ems /ems/ /ems/index.htm /ems/index.html 
) ) {

 $t->get_ok("/reroute$path")
   ->status_is(200)
   ->content_type_like(qr/text\/html/)
   ->content_like(qr/$txt->{NOSCRIPT}/)
   ->content_like(qr/$txt->{LISTING}/);

}

# path that should work and lead to photo browsing
foreach my $path ( qw ( 
 /breeders/Bodhidharma-039s.html /breeders/MegaMiaow-039s.html
 /breeders/Sic-039an.html /breeders/Is-228-045Brownin.html
 /breeders/Wanderd-252ne-039s.html /breeders/-197bodas.html
 /ems/TUV.html /ems/tuv.html /ems/tuv.html /ems/AbY.htm 
 /ems/bos.html /ems/mco.html /ems/hcs.htm /ems/hcl.html
 /ems/pku.html /ems/pkx.html /ems/lkn.html /ems/lku.html
 /xdf/mimosa /xdf/mimosa%20~0004 /xdf/pilli%20pulla%20monni
 /xdf/%7Bsatinante%7D%20%7Btammikatin%7D%20-%5Bmco%5D%20-%5Bsib%5D
 /xdf/%5Be%5D%20%5Bes%5D%20-(j%F6rgen)%20-(tarzan)%20-j%E4%E4mies%20-unicorn%20-bonus
 /xdf/%5Be%5D%20%5Bes%5D%20-(j%F6rgen)%20-(tarzan)%20-j%E4%E4mies%20-unicorn%20-bonus%20~0001
 /xdf/%5Be%5D%20%5Bes%5D%20-(j%F6rgen)%20-(tarzan)%20-j%E4%E4mies%20-unicorn%20-bonus%20~0002
 /xdf/(ville)%20(kalle)%20(pekka)%20(pentti)%20-(kaisa)
 /xdf/%5Bcrx%5D%20%5Bdrx%5D%20%5Bgrx%5D%20%2B%5B03%5D%20-%5Bb%5D
 /xdf/%5Ba%5D%20%5Bb%5D%20%5Bc%5D%20%5Bd%5D%20%5Be%5D
 /xdf/%2B%5Bn%5D%20%2Bmagic%20%7Bhanni%7D%20%7Bnight%7D 
 /xdf/%2Btassu%20vir%20xin%20bal%20~0001
 /xdf/%2Btassu%20vir%20xin%20bal
 /xdf/%7Bstream%7D%20%7Bmaya%7D%20%7Bcoast%7D%20%2B%7Bgold%7D
 /xdf/%7Bstream%7D%20%7Bmaya%7D%20%7Bcoast%7D%20%2B%7Bgold%7D%20~0001
) ) {

 $t->get_ok("/reroute$path")
   ->status_is(200)
   ->content_type_like(qr/text\/html/)
   ->content_like(qr/$txt->{NOSCRIPT}/)
   ->content_like(qr/$txt->{PAGE_FIRST}/)
   ->content_like(qr/$txt->{PAGE_NEXT}/);
   
}

# old search page should lead to new search page
foreach my $path ( qw ( 
 /xdf /xdf/
) ) {

 $t->get_ok("/reroute$path")
   ->status_is(200)
   ->content_type_like(qr/text\/html/)
   ->content_like(qr/$txt->{NOSCRIPT}/)
   ->content_like(qr/$txt->{SEARCH}/);

}

# classic non-rerouted paths should work too
foreach my $folder ( qw ( 
 around_finland cesmes_b cesmes_c culture_trip_lake_tuusula hel_sto_hel 
) ) {
 
 $t->get_ok("/reroute/$folder")
   ->status_is(200)
   ->content_type_like(qr/text\/html/);
}

foreach my $folder ( qw ( 
 20110612hyvinkaa 20100327turku2 20100327turku_panel 
 20091010kirkkonummi 20100327turku1 20100327turku_misc 
 ) ) {
 
 foreach my $file ( qw ( 
  / /index.htm /index.html /check1.htm /check1.html /check2.htm /check2.html 
  /0001-0012.html /0001-0012.htm /0013-0024.html
 ) ) {

  # paths that should lead to photo browsing
  $t->get_ok("/reroute/$folder$file")
   ->status_is(200)
   ->content_type_like(qr/text\/html/)
   ->content_like(qr/$txt->{NOSCRIPT}/)
   ->content_like(qr/$txt->{PAGE_FIRST}/)
   ->content_like(qr/$txt->{PAGE_NEXT}/);

 }

 # paths that should lead to photo viewing
 foreach my $file ( qw ( 
  /0001.html /0002.html /0004.html /0008.html /0009.htm  
 ) ) {

  $t->get_ok("/reroute/$folder$file")
   ->status_is(200)
   ->content_type_like(qr/text\/html/)
   ->content_like(qr/$txt->{NOSCRIPT}/)
   ->content_like(qr/$txt->{PHOTO_NEXT}/)
   ->content_like(qr/$txt->{PHOTO_LAST}/);

 }
  
}

# static resources
foreach my $static ( qw ( 
 /20040821vantaa/IMAG1009.JPG
 /20050730helsinki1/IMG_4047.JPG
 /20110313helsinki/CFA_6640.JPG
 /20100606hyvinkaa/ERY59700.JPG
 /20080518tampere/IMG_1471.JPG
 /20100606hyvinkaa/ERY59700.jpg
 /20080518tampere/IMG_1471.jpg
) ) {
 
 $t->get_ok("/reroute$static")
   ->status_is(200)
   ->content_type_like(qr/image\/jpeg/);

}

# a few illegal paths

$t->get_ok("/reroute/wont/match/anything.html")->status_is(404);
$t->get_ok("/reroute/jakldsjflkasdf/93939.JPG")->status_is(404);
$t->get_ok("/reroute/jjk3jjj3j")->status_is(404);

done_testing;

