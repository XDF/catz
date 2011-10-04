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

use Catz::Util::String qw ( encode );

my $t = Test::Mojo->new( 'Catz::Core::App' );

my $c = 0;

my @ok = qw (
 org/TUROK/146161
 org/TUROK/146180
 org/SUROK/013090
 title/EC/171059
 title/EC/043287
 title/EC/003028
 date/20100404/147008
 app/a/173004
 folder/20110514tampere/173014
 lens/Canon_EF_85mm_f-0471-0468_USM_-038_Tamron_2X_MC7_C-045AF1_BBAR/061332
 lens/MC_Jupiter-0459_85mm_f-0472-0460/066299
 cat/Piupaws_-034Toykiller-034/085182
 cat/Piupaws_-034Toykiller-034/081241
 cat/Baila-045Bailan_Rikasr-228m-228el-228m-228/111228
 nat/FR/150036
 breeder/Cat-039s-045JM/123100
);

my @bad = qw (
 org/TUROK/001180
 org/SUROK/013987
 title/EC/147008
 date/20100404/111008
 folder/20110514tampere/081014
 lens/Canon_EF_85mm_f-0471-0468_USM_-038_Tamron_2X_MC7_C-045AF1_BBAR/146161
 cat/Piupaws_-034Toykiller-034/111182
 org/ZUROK/146161
 org/SURO-038/002003
 title/EEC/003028
 date/20010404/147008
 apa/a/173004
 folder/20110514PAmpere/173014
 lens/Canon_EF_86mm_f-0471-0468_USM_-038_Tamron_2X_MC7_C-045AF1_BBAR/061332
 cat/Piu?aws_-034Toykiller-034/081241
 void/void/void
 283904/9812304/23409234
 =="d"/!!!!!/~~***
); 
 
foreach my $lang ( qw ( en fi en264312 fi384322 ) ) {

 my $txt = text ( substr ( $lang, 0, 2 ) );
 
 foreach my $set ( @ok ) {

  my @elem = split /\//, $set;
       
  $t->get_ok("/$lang/view/$elem[0]/$elem[1]/")
    ->content_like(qr/$txt->{LOC}/)
    ->content_like(qr/$txt->{ALBUM}/)
    ->content_like(qr/$txt->{ORG}/)
    ->content_like(qr/$txt->{DATE}/)
    ->content_like(qr/$txt->{UMB}/)
    ->content_like(qr/$txt->{PHOTO_ID}/)
    ->content_like(qr/\/.{8}\.JPG/);
     
  $c += 8;

  $t->get_ok("/$lang/view/$elem[0]/$elem[1]/$elem[2]/")
    ->content_like(qr/$txt->{LOC}/)
    ->content_like(qr/$txt->{ALBUM}/)
    ->content_like(qr/$txt->{ORG}/)
    ->content_like(qr/$txt->{DATE}/)
    ->content_like(qr/$txt->{UMB}/)
    ->content_like(qr/$txt->{PHOTO_ID}/)
    ->content_like(qr/\/.{8}\.JPG/);

  $c += 8;
   
 } 
  
 foreach my $mode ( qw ( browse view ) ) {
 
  $t->get_ok("/$lang/$mode/")->status_is(404); $c += 2;
 
  foreach my $set ( @ok ) {
  
   my @elem = split /\//, $set;
   
   $t->get_ok("/$lang/$mode/$elem[0]/")->status_is(404); $c += 2;
   
   $t->get_ok("/$lang/$mode/$elem[1]/")->status_is(404); $c += 2;
   
   $t->get_ok("/$lang/$mode/$elem[0]/$elem[1]")->status_is(200); $c += 2;
     
   $t->get_ok("/$lang/$mode/$elem[0]/$elem[1]/")
     ->status_is(200)
     ->content_type_like(qr/text\/html/)
     ->content_like(qr/ alt=\"\[/)
     ->content_like(qr/\.JPG/);

   $c += 5;

   $t->get_ok("/$lang/$mode/$elem[0]/$elem[1]/$elem[2]/")
     ->status_is(200)
     ->content_type_like(qr/text\/html/)
     ->content_like(qr/ alt=\"\[/)
      ->content_like(qr/\.JPG/);

   $c += 5;
   
   $mode eq 'browse' and do { # check that visualization exists
   
    $t->get_ok("/$lang/$mode/$elem[0]/$elem[1]/$elem[2]/")
     ->content_like(qr/ class=\"viz/);
   
    $c += 2;
    
   };
   
  }

  foreach my $set ( @bad ) {
  
   my @elem = split /\//, $set;
     
   $t->get_ok("/$lang/$mode/$elem[0]/$elem[1]/$elem[2]/")->status_is(404);
  
   $c += 2;
   
  }

  # now some stress testing
  
  foreach ( 1 .. 100 ) {  
 
   my $pri = 
    join '', map { chr $_ } map { 49 + int(rand(95)) } 
    ( 1 .. ( 20 + int(rand(1000)) ) );
   
   my $prie = encode ( $pri );

   my $sec = 
    join '', map { chr $_ } map { 49 + int(rand(95)) } 
    ( 1 .. ( 20 + int(rand(1000)) ) );
   
   my $sece = encode ( $sec ); 

   my $id = 
    join '', map { chr $_ } map { 49 + int(rand(95)) } 
    ( 1 .. ( 20 + int(rand(100)) ) );
      
   $t->get_ok("/$lang/$mode/$pri/$sec/")->status_is(404); $c += 2;
  
   $t->get_ok("/$lang/$mode/$pri/$sec/$id/")->status_is(404); $c += 2;
  
   $t->get_ok("/$lang/$mode/$prie/$sece/")->status_is(404); $c += 2;  

   $t->get_ok("/$lang/$mode/$prie/$sece/$id/")->status_is(404); $c += 2;
             
  }

 }
 
}
 
done_testing($c);