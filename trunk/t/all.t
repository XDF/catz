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

my $t = Test::Mojo->new ( conf ( 'app' ) );

$t->max_redirects ( 0 );

use Catz::Util::String qw ( enurl );

my @okids = qw ( 001001 123095 061254 182107 057179 );

my @badids = qw (
 002600 888888 1 12 98793  -123123 ===!!! $~ *he??o* +++^$@ text=*pa*
);

my @oksetups = qw ( en fi en394211 fi211111 );

my @okmodes = qw ( browseall viewall );

my $setup;

foreach my $mode ( @okmodes ) {

 $setup = @oksetups[ rand @oksetups ];

 $t->get_ok ( "/$setup/$mode/" )->status_is ( 200 )
  ->content_type_like ( qr/text\/html/ )
  ->content_like      ( qr/alt=\"\w{4,5} \d{6}/ )    # photo alt text
  ->content_like      ( qr/\.JPG/ );

 $t->get_ok ( "/$setup/$mode" )->status_is ( 301 );

 foreach my $id ( @okids ) {

  $setup = @oksetups[ rand @oksetups ];

  $t->get_ok ( "/$setup/$mode/$id/" )->status_is ( 200 )
   ->content_type_like ( qr/text\/html/ )
   ->content_like      ( qr/alt=\"\w{4,5} \d{6}/ )    # photo alt text
   ->content_like      ( qr/\.JPG/ );

  $t->get_ok ( "/$setup/$mode/$id" )->status_is ( 301 );

 }

 foreach my $id ( @badids ) {

  $setup = @oksetups[ rand @oksetups ];

  $t->get_ok ( "/$setup/$mode/$id/" )->status_is ( 404 );

  $t->get_ok ( "/$setup/$mode/" . ( enurl $id ) . '/' )->status_is ( 404 );

 }

} ## end foreach my $mode ( @okmodes)

done_testing;
