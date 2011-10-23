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

use Catz::Core::Text;

use Catz::Util::String qw ( encode );

my $t = Test::Mojo->new( 'Catz::Core::App' );

# all ok setups must show all photo details
my @oksetups = qw ( en fi en264312 fi384322 );

my @okcombs = qw (
 org/TUROK/146161
 org/SUROK/013090
 title/EC/003028
 date/20100404/147008
 app/a/173004
 folder/20110514tampere/173014
 lens/Canon_EF_85mm_f-0471-0468_USM_-038_Tamron_2X_MC7_C-045AF1_BBAR/061332
 lens/MC_Jupiter-0459_85mm_f-0472-0460/066299
 cat/Piupaws_-034Toykiller-034/081241
 cat/Baila-045Bailan_Rikasr-228m-228el-228m-228/111228
 nat/FR/150036
 breeder/Cat-039s-045JM/123100
 cate/1/179012
 cate/4/009030
);

my @badids = qw (
 org/TUROK/150161
 org/SUROK/018090
 title/EC/003122
 date/20100404/150008
 app/a/173008
 breeder/Cat-039s-045JM/143100
 cate/4/011032
);

my @badcombs = qw (
 cate/x/009030
 folder/20003114tampere/081014
 org/ZUROK/146161
 org/SURO-038/002003
 apa/a/173004
 folder/20110514PAmpere/173014
 cat/Piu?aws_-034Toykiller-034/081241
 283904/9812304/23409234
 +="d"/!!$@!!/~~***
);

my $i = 0; # ok setup pointer  

foreach my $mode ( qw ( browse view ) ) {
 
 foreach my $comp ( @okcombs ) {
 
  my $setup = $oksetups[$i++]; # we loop the setups list

  $i > $#oksetups and $i = 0;
 
  my $txt = text ( substr ( $setup, 0, 2 ) );
 
  my @elem = split m|/|, $comp;

  # just mode -> 404
  $t->get_ok("/$setup/$mode/")->status_is(404);
  
  if ( $mode eq 'browse' ) {
          
   # ok browse with no photo id
   $t->get_ok("/$setup/$mode/$elem[0]/$elem[1]/")
     ->status_is(200)
     ->content_type_like(qr/text\/html/)
     ->content_like(qr/ alt=\"\[/)
     ->content_like(qr/\.JPG/);

   # ok browse with photo id
   $t->get_ok("/$setup/$mode/$elem[0]/$elem[1]/$elem[2]/")
     ->status_is(200)
     ->content_type_like(qr/text\/html/)
     ->content_like(qr/ alt=\"\[/)
     ->content_like(qr/\.JPG/); 

   # check visualization
   if ( $elem[0] eq 'cat' ) { 
   
     $t->get_ok("/$setup/$mode/$elem[0]/$elem[1]/$elem[2]/")
       ->content_like(qr/ class=\"viz/);
    
   };
  
  } else { # view 
  
   # ok view with no photo id     
   $t->get_ok("/$setup/$mode/$elem[0]/$elem[1]/")
     ->status_is(200)
     ->content_type_like(qr/text\/html/)
     ->content_like(qr/$txt->{LOC}/)
     ->content_like(qr/$txt->{ALBUM}/)
     ->content_like(qr/$txt->{PHOTO_ID}/)
     ->content_like(qr/\/.{8}\.JPG/);
  
    # ok view with photo id
    $t->get_ok("/$setup/$mode/$elem[0]/$elem[1]/$elem[2]/")
      ->status_is(200)
      ->content_type_like(qr/text\/html/)
      ->content_like(qr/$txt->{LOC}/)
      ->content_like(qr/$txt->{DATE}/)
      ->content_like(qr/$txt->{PHOTO_ID}/)
      ->content_like(qr/\/.{8}\.JPG/);
  
   }
    
   # no ending slash -> 301
  
   $t->get_ok("/$setup/$mode/$elem[0]/$elem[1]")
     ->status_is(301);

   $t->get_ok("/$setup/$mode/$elem[0]/$elem[1]/$elem[2]")
     ->status_is(301);
     
   # 

 }
     
 foreach my $comp ( @badids ) {
 
  my $setup = $oksetups[$i++]; # we loop the setups list

  $i > $#oksetups and $i = 0;
  
      
  my @elem = split m|/|, $comp;
  
  $t->get_ok("/$setup/$mode/$elem[0]/$elem[1]/$elem[2]/")->status_is(404);

 }
       
 foreach my $comp ( @badcombs ) {
 
  my $setup = $oksetups[$i++]; # we loop the setups list

  $i > $#oksetups and $i = 0;
  
  my @elem = split m|/|, $comp;
  
  $t->get_ok("/$setup/$mode/$elem[0]/$elem[1]/")->status_is(404);
  
  $t->get_ok("/$setup/$mode/$elem[0]/$elem[1]/$elem[2]/")->status_is(404);
 
 }
 
 # stress test
 
 foreach ( 1 .. 50 ) {
 
  my $setup = $oksetups[$i++]; # we loop the setups list

  $i > $#oksetups and $i = 0;  
 
   my $pri = 
    join '', map { chr $_ } map { 49 + int(rand(95)) } 
     ( 1 .. ( 20 + int(rand(200)) ) );
   
   my $prie = encode ( $pri );

   my $sec = 
    join '', map { chr $_ } map { 49 + int(rand(95)) } 
    ( 1 .. ( 20 + int(rand(500)) ) );
   
   my $sece = encode ( $sec ); 

   my $id = 
    join '', map { chr $_ } map { 48 + int(rand(10)) } ( 1 .. 6 );
      
   $t->get_ok("/$setup/$mode/$pri/$sec/")
     ->status_isnt(200)->status_isnt(500);
  
   $t->get_ok("/$setup/$mode/$pri/$sec/$id/")
     ->status_isnt(200)->status_isnt(500);
  
   $t->get_ok("/$setup/$mode/$prie/$sece/")->status_is(404);  

   $t->get_ok("/$setup/$mode/$prie/$sece/$id/")->status_is(404);
             
  }
  
 # english speciality
 
 $t->get_ok("/en/$mode/umb/other/")->status_is(200);  
 $t->get_ok("/en/$mode/umb/muu/")->status_is(404);

 # finnish speciality

 $t->get_ok("/fi/$mode/umb/other/")->status_is(404);  
 $t->get_ok("/fi/$mode/umb/muu/")->status_is(200);

}

done_testing;