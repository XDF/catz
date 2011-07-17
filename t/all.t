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

my $t = Test::Mojo->new( 'Catz::Core::App' );

my $c = 0;

my @ok = qw (
 001001 123095 062047 170077 061254 025072 137077 042279 099167 120046
 080121 028049 157077 153128 143160 097022 041235 144058 092351 065137
);

my @bad = qw (
 001600 002600 003600 888888 888000 000000 000001 001000 999000 000999 1 12 
 13 567 98798 12345 abcde a -123123 ===!!! $$~~ CRX TUV lens=Sigma* *he??o*
); 

foreach my $lang ( qw ( en fi en394211 fi211111 ) ) {
 
 foreach my $mode ( qw ( browseall viewall ) ) {
 
  $t->get_ok("/$lang/$mode")->status_is(301); $c += 2;
    
  $t->get_ok("/$lang/$mode/")
    ->status_is(200)
    ->content_type_like(qr/text\/html/)
    ->content_like(qr/ alt=\"\[/)
    ->content_like(qr/\.JPG/);
    
  $c += 5;
  
  foreach my $id ( @ok ) {

   $t->get_ok("/$lang/$mode/$id")->status_is(301); $c += 2;
  
   $t->get_ok("/$lang/$mode/$id/")
     ->status_is(200)
     ->content_type_like(qr/text\/html/)
     ->content_like(qr/ alt=\"\[/)
     ->content_like(qr/\.JPG/);     
    
   $c += 5;
  
  }

  foreach my $id ( @bad ) {
  
   $t->get_ok("/$lang/$mode/$id/")->status_is(404);
   
   $c += 2;
  
  }
 
 
 }
 
 my $mode = 'void';
  
 foreach my $id ( @ok ) {
 
  $t->get_ok("/$lang/$mode/$id/")->status_is(404);
  
  $c += 2;
  
 }
  
}

done_testing($c);