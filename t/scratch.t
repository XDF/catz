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

use 5.12.0;
use strict;
use warnings;

# unbuffered outputs
# from http://perldoc.perl.org/functions/open.html
select STDERR;
$| = 1;
select STDOUT;
$| = 1;

use Test::More;
use Test::Mojo;

use Catz::Data::Conf;
use Catz::Data::Text;

use Catz::Util::String qw ( encode enurl );

my $t = Test::Mojo->new ( conf ( 'app' ) );

my @miscsetups = qw (
 en fi en264312 fi264322 en897123 fi189492 fi2643a2 en1 ann
);

my @badplain = qw (
 x void pointless 0 123 web_inf 8092384u23u4u232u323u4 TUUUEUJXASDASEWRAWSDAS
);

my @badspecial = qw (
 ? = + o%uyl--&?? *34-@$$5== Hdd2EU-+´~@^^ =__!?+09~ *-ÅÄÖåä&&ö
);

foreach ( 1 .. 10 ) {

 foreach my $i ( 1 .. 5 ) {

  $t->get_ok (
   '/' . ( join '/', map { $badplain[ rand @badplain ] } ( 1 .. $i ) ) . '/' )
   ->status_is ( 404 );

  $t->get_ok (
   '/'
    . (
    join '/', map { enurl ( $badspecial[ rand @badspecial ] ) } ( 1 .. $i )
    )
    . '/'
  )->status_is ( 404 );

  foreach my $setup ( @miscsetups ) {

   $t->get_ok ( "/$setup/"
     . ( join '/', map { $badplain[ rand @badplain ] } ( 1 .. $i ) )
     . '/' )->status_is ( 404 );

   $t->get_ok (
    "/$setup/"
     . (
     join '/', map { enurl ( $badspecial[ rand @badspecial ] ) } ( 1 .. $i )
     )
     . '/'
   )->status_is ( 404 );

   # the big one

   $t->get_ok ( "/$setup/"
     . ( join '/', map { $badplain[ rand @badplain ] } ( 1 .. 50 ) )
     . '/' )->status_is ( 404 );

  } ## end foreach my $setup ( @miscsetups)

 } ## end foreach my $i ( 1 .. 5 )

} ## end foreach ( 1 .. 10 )

# test some routings with dots

foreach my $setup ( qw ( en fi en264312 fi264322 ) ) {

 $t->get_ok ( "/$setup/viewall.txt" )->status_is ( 404 );

 $t->get_ok ( "/$setup/browseall.iltavilli" )->status_is ( 404 );

 $t->get_ok ( "/$setup/search.xs?q=mimosan" )->status_is         ( 404 );
 $t->get_ok ( "/$setup/search?q=mimo.san" )->status_is           ( 200 );
 $t->get_ok ( "/$setup/search?q=mimo.s.an .san an." )->status_is ( 200 );
 $t->get_ok ( "/$setup/search.java?q=mimo.san" )->status_is      ( 404 );

}

done_testing;
