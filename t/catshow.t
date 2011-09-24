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

use Catz::Load::Data qw ( loc );

use Catz::Util::String qw ( enurl );
use Catz::Util::Time qw ( dtexpand );

sub splitf {

 $_[0] =~ m|^(.{8})(.+)$|;
 
 my $date = $1; my $loc = $2;
 
 $date = dtexpand ( $date, 'en' );
 
 $loc = loc $loc; 
 
 return ( $date, $loc );  

}

my $t = Test::Mojo->new( 'Catz::Core::App' );

my $c = 0;
 
$t->get_ok('/lastshow')->status_is(301); $c += 2;

$t->get_ok('/lastshow/')
 ->status_is(200)
 ->content_type_like(qr/text\/plain/)
 ->content_like(qr/generated at/)
 ->content_like(qr/\.JPG/);
 
$c += 5;

my @ok = qw (
 20040801helsinki 20050220jyvaskyla 20050925orimattila
 20060910orimattila 20070707kempele 20070708kempele
 20100307seinajoki 20101002porvoo 20110910kemio
);

my @bad = qw (
 20040805helsinki 20030101tampere 99998877roska
 20110504kiiminki 20110919orimattila 20120101stockholm
 jasldkfjalkdjfla 832832833883385555 //%%23_-%X....**
 //%?+23_-%X.&&@@^ /3/%?+523_-a%Xdddu3uJJJJJejjj.&&@@^
 
);

foreach ( @ok ) {

 my ( $date, $loc ) = splitf $_;
 
 $t->get_ok( "/anyshow/$date/".enurl($loc) )->status_is(301); $c += 2; 

 $t->get_ok( "/anyshow/$date/".enurl($loc).'/' )
  ->status_is(200)
  ->content_type_like(qr/text\/plain/)
  ->content_like(qr/generated at/)
  ->content_like(qr/\.JPG/); 
  
  $c += 5;
  
}

foreach ( @bad ) {

 my ( $date, $loc ) = splitf $_;

 $t->get_ok( "/anyshow/$date/".enurl($loc).'/' )
  ->status_is(404);
  
 $c += 2;

}

    
done_testing($c);