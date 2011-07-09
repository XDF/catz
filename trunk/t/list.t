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

use Catz::Data::List;

my $t = Test::Mojo->new( app => 'Catz::Core::App' );

my $matrix = list_matrix;

my $c = 0;

foreach my $lang ( qw ( en fi en234212 ) ) {

 my $txt = text ( $lang );

 $t->get_ok("/$lang/lists")->status_is(301); $c += 2;

 $t->get_ok("/$lang/lists/")
   ->status_is(200)
   ->content_type_like(qr/text\/html/)
   ->content_like(qr/$txt->{LISTINGS}/);

 $c += 4;
 
 foreach my $mode ( @{ $matrix->{album}->{modes} } ) {
 
  # illegal list should be 404
  
  $t->get_ok("/$lang/list/stupid/$mode/")->status_is(404); $c += 2;
  
 }
 
 foreach my $list ( sort keys %{ $matrix } ) {
 
  # no mode should give 404
  
  $t->get_ok("/$lang/list/$list/")->status_is(404); $c += 2;
  
  # illegal mode should give 404
  
  $t->get_ok("/$lang/list/$list/oiklg/")->status_is(404); $c += 2;
  
  my $had_first = 0;
  
  foreach my $mode ( @{ $matrix->{$list}->{modes} } ) {
  
   $mode eq 'first' and $had_first = 1;

   # no slash should give perm redirect
   
   $t->get_ok("/$lang/list/$list/$mode")->status_is(301); $c += 2;

   $t->get_ok("/$lang/list/$list/$mode/")
     ->status_is(200)
     ->content_type_like(qr/text\/html/)
     ->element_exists('html body div[class="inner"]')
     ->text_like('html body h1'=>qr/$txt->{'MODE_'.uc($mode)}/);
     
   $c += 5;
  
   if ( $matrix->{$list}->{dividers} ) {
   
    $t->get_ok("/$lang/list/$list/$mode/")
      ->element_exists('html body div div div[class~="outer"]');
    
     $c += 2;
   
   }
  
  }
  
  if ( not $had_first ) {
  
   # illegal mode 'first' should give 404
  
   $t->get_ok("/$lang/list/$list/first/")->status_is(404); $c += 2;
   
  }
 
 }
 
}

# without language

$t->get_ok("/list/")->status_is(404); $c += 2;

foreach my $list ( sort keys %{ $matrix } ) {

 $t->get_ok("/list/$list/")->status_is(404); $c += 2;

 foreach my $mode ( @{ $matrix->{$list}->{modes} } ) {
  
  $t->get_ok("/list/$list/$mode/")->status_is(404); $c += 2;
  
 }

}

done_testing($c);