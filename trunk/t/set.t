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

use lib '../lib';

use Test::More;
use Test::Mojo;

use Catz::Data::Setup;

use Catz::Util::String qw ( enurl );

my $t = Test::Mojo->new( app => 'Catz::Core::App' );

my $setup = setup_values;

my $c = 0;

# no key

$t->get_ok('/set/')
  ->status_is(200)
  ->content_type_like(qr/text\/plain/)
  ->content_is('FAILED');
   
$c += 4;

# huge key
 
my $key = join '', map { 'x' } ( 1 .. 1900 );
 
$t->get_ok('/set?'.$key.'=200')
  ->status_is(200)
  ->content_type_like(qr/text\/plain/)
  ->content_is('FAILED');
   
$c += 4;

foreach my $key ( keys %{ $setup } ) {

 # correct key but invalid value
 
 foreach my $val ( map { enurl $_ } qw (
  ///// jakldsfj +++++++?? ??? %%%%____* *___* *_ÄdÅÄö åääö ÅÄÖÅÄ1222X a b 1 2
 ) ) {

  $t->get_ok('/set?'.$key.'='.$val)
   ->status_is(200)
   ->content_type_like(qr/text\/plain/)
   ->content_is('FAILED');
   
  $c += 4;
 
 }
 
 # no value / 1
 
 $t->get_ok('/set?'.$key)
   ->status_is(200)
   ->content_type_like(qr/text\/plain/)
   ->content_is('FAILED');
   
 $c += 4;

 # no value / 2
 
 $t->get_ok('/set?'.$key.'=')
   ->status_is(200)
   ->content_type_like(qr/text\/plain/)
   ->content_is('FAILED');
   
 $c += 4;

 # huge values
 
 my $val = join '', map { 'x' } ( 1 .. 1900 );
 
 $t->get_ok('/set?'.$key.'='.$val)
  ->status_is(200)
  ->content_type_like(qr/text\/plain/)
  ->content_is('FAILED');
   
 $c += 4;
       
 foreach my $val ( @{ $setup->{$key} } ) {
 
  $t->get_ok('/set?'.$key.'='.$val)
    ->status_is(200)
    ->content_type_like(qr/text\/plain/)
    ->content_is('OK'); 
    
  $c += 4;
  
  $t->get_ok('/set?'.$val.'='.$key) # reversed val and key -> invalid comb
    ->status_is(200)
    ->content_type_like(qr/text\/plain/)
    ->content_is('FAILED'); 
    
  $c += 4;
  
  my $def = setup_default ( $key );
  
  $t->get_ok('/set?'.$key.'='.$def)
    ->status_is(200)
    ->content_type_like(qr/text\/plain/)
    ->content_is('OK');
    
  $c += 4;   
 
 }

}

done_testing($c);