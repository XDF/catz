#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2019 Heikki Siltala
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

use 5.14.2;
use strict;
use warnings;

do '../script/core.pl';

# unbuffered outputs
# from http://perldoc.perl.org/functions/open.html
select STDERR;
$| = 1;
select STDOUT;
$| = 1;

use Test::More;
use Test::Mojo;

use Catz::Data::Conf;

my $t = Test::Mojo->new ( conf ( 'app' ) );

my @oksetups = qw ( en fi en264312 fi384321 );

my @oksets = qw (
 breed/MCO/breeder
 date/20120114/umb
 cat/Miisu/breed
 cat/INRxS_Xenon_of_Windseeker/code
 nick/Mikke/cat
 lens/Canon_EF_50mm_f-0471-0468_II/fnum
 feat/a/app
) ;

my @badsets = qw (
 breed/MCO/roska
 date/201114/umb
 catw2/Miisu/breed
 folder/20110918orimattila/breeder
 nick/Mikkedewe8/cat
 lens/Canon_EF_50mm_f-047-0471-0468_II/cat
 feat/a/lens
 9039394u4h
 asdfasdfasdfasdfuaiouasdofuasodufaosdufaoisudfoasdfasdfklasdkfjaldjkfalkdlka
 jaskdf7awu-203/-202-201-202
);

$t->get_ok ( "/fi384321/expand/cat/Miisu/loc" )->status_is ( 301 );
$t->get_ok ( "/en/expand/cat/Miisu/loc" )->status_is ( 301 );

# this organizer only has one location -> no expand available
$t->get_ok ( "/fi/expand/org/Pyh-228_Birman_Kissa_-045yhdistys/loc/")->status_is ( 200 );

# language is invalid
$t->get_ok ( "/if/expand/org/Pyh-228_Birman_Kissa_-045yhdistys/loc/")->status_is ( 404 );

# this organizer is not valid in english
$t->get_ok ( "/en/expand/org/Pyh-228_Birman_Kissa_-045yhdistys/loc/")->status_is ( 404 );

my $lang;

foreach my $comb ( @oksets ) {

 $lang = @oksetups[ rand @oksetups ];

 $t->get_ok ( "/$lang/expand/$comb/" )
   ->status_is ( 200 )
   ->content_type_like ( qr/text\/html/ )
   ->content_like ( qr/catzExpandDismiss/ )
   ->content_like ( qr/a href/ );
}

foreach my $comb ( @badsets ) {

 $lang = @oksetups[ rand @oksetups ];

 $t->get_ok ( "/$lang/expand/$comb/" )->status_is ( 404 );
 
}

done_testing;
