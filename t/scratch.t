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

use Catz::Core::Conf;
use Catz::Core::Text;

use Catz::Util::String qw ( encode enurl );

my $t = Test::Mojo->new( 'Catz::Core::App' );

my $c = 0;

# stupid urls no encoding

foreach my $url ( qw ( a b x void pointless 0 1 123 web_inf pOKWj3jk33lkJ ) ) {

 $t->get_ok("/$url/")->status_is(404); $c += 2; 
 $t->get_ok("/$url/$url/")->status_is(404); $c += 2;
 $t->get_ok("/$url/$url/$url/")->status_is(404); $c += 2;
  
 foreach my $lang ( qw ( en fi en264312 fi264322 en897123 fi189492 fi2643a2 en12 ) ) {
   
  $t->get_ok("/$lang/$url/")->status_is(404); $c += 2;
  $t->get_ok("/$lang/$url/$url/")->status_is(404); $c += 2;
  $t->get_ok("/$lang/$url/$url/$url/")->status_is(404); $c += 2;
   
 }
 
}

# stupid urls with encoding

foreach my $uri ( qw ( oiuy//&?? *345== HEU@^^ !?+09~ *-ÅÄÖåäö ) ) {

 my $url = enurl ( $uri );

 $t->get_ok("/$url/")->status_is(404); $c += 2; 
 $t->get_ok("/$url/$url/")->status_is(404); $c += 2;
 $t->get_ok("/$url/$url/$url/")->status_is(404); $c += 2;
 
 foreach my $lang ( qw ( en fi en211211 fi171212 en914311 en123123123 fi929 enneen ) ) { 
  
  $t->get_ok("/$lang/$url/")->status_is(404); $c += 2;
  $t->get_ok("/$lang/$url/$url/")->status_is(404); $c += 2;
  $t->get_ok("/$lang/$url/$url/$url/")->status_is(404); $c += 2;

  $t->get_ok("/e/")->status_is(404); $c += 2;

 }
 
}

# make it big from 100 to 1900

foreach my $val ( 1 .. 19 ) {

 my $url = join '', map { 'x' } ( 1 .. $val * 100 );
 
 $t->get_ok("/$url/")->status_is(404); $c += 2;
 
 foreach my $lang ( qw ( en fi en211211 fi171212 ) ) {
 
  $t->get_ok("/$lang/$url/")->status_is(404); $c += 2;
 
 }

}
  
# stress with force
 
foreach my $i ( 1 .. 100 ) {
 
 my $elems = int(rand(30)) + 1;
 
 my @patt = ();
   
 foreach ( 1 .. $elems ) {

  my $c = 10 + int(rand(40));
  
  push @patt, 
   ( join '', map { chr $_ } map { 33 + int(rand(95)) } ( 1 .. $c ) ); 
  
 }
  
 my $pata = join '/', map { enurl $_ } @patt;
  
 my $patb = join '/', map { encode $_ } @patt; 
    
 $t->get_ok("/$pata/")->status_is(404); $c += 2;
 $t->get_ok("/en/$pata/")->status_is(404); $c += 2;
 $t->get_ok("/en211211/$pata/")->status_is(404); $c += 2;
 $t->get_ok("/en211x11/$pata/")->status_is(404); $c += 2;
 $t->get_ok("/fi/$pata/")->status_is(404); $c += 2;    

 $t->get_ok("/$patb/")->status_is(404); $c += 2;
 $t->get_ok("/en/$patb/")->status_is(404); $c += 2;
 $t->get_ok("/fi/$patb/")->status_is(404); $c += 2;
 $t->get_ok("/fi171212/$patb/")->status_is(404); $c += 2;
 $t->get_ok("/fi17122232/$patb/")->status_is(404); $c += 2;    

 
}

foreach my $lang ( qw ( en fi en264312 fi264322 ) ) {
     
  $t->get_ok("/$lang/viewall.txt")->status_is(200); $c += 2;
  $t->get_ok("/$lang/browseall.iltavilli")->status_is(200); $c += 2;
  $t->get_ok("/$lang/search.xs?q=mimosan")->status_is(200); $c += 2;
  $t->get_ok("/$lang/search.js?q=mimo.san")->status_is(200); $c += 2;
  $t->get_ok("/$lang/search.java?q=mimo.san")->status_is(200); $c += 2;
     
}

foreach my $lang ( qw ( x fi189492 fi2643a2 en12 ) ) {
     
  $t->get_ok("/$lang/viewall.txt")->status_is(404); $c += 2;
  $t->get_ok("/$lang/browseall.iltavilli")->status_is(404); $c += 2;
  $t->get_ok("/$lang/search.xs?q=mimosan")->status_is(404); $c += 2;
  $t->get_ok("/$lang/search.js?q=mimo.san")->status_is(404); $c += 2;
  $t->get_ok("/$lang/search.java?q=mimo.san")->status_is(404); $c += 2;
     
}


# 2011-10-04 testing that some static resources dispatch properly

$t->get_ok('/robots.txt')->status_is(200); $c += 2;
$t->get_ok('/favicon.ico')->status_is(200); $c += 2;
$t->get_ok('/js_lib/jquery.js')->status_is(200); $c += 2;
$t->get_ok('/js_site/find.js')->status_is(200); $c += 2;

done_testing( $c );