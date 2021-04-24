#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2019 Heikki Siltala
# Licensed under The MIT License
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
use Catz::Data::Text;

my $t = Test::Mojo->new ( conf ( 'app' ) );

use constant RESULT_NA => '<!-- N/A -->';

# some working keys

my @ok = qw (
 CATZ_U2FsdGVkX1-0477-0471c-0477nNUeY27fECUQiulGaVnCybW9OPosmsUSJyDA2MyIxwkzdFu-0474fJF9-0476Yvw-061-010_DD0A19AD40CDBDC4C4C342D0C50C9AD3
 CATZ_U2FsdGVkX1-043Wr53wtlp-047irJ-043ztBErMoS-047btXe9c2CRdcR0Nhqq3J9ssP-0434gDUPWmkcUWqWwHL5M-061-010_7F66992E4745C287980FADF5B4A0A25F
 CATZ_U2FsdGVkX1-043-043YXwWIg66EDIvIzBEbZijFADhj5TZuZTb8bb5wylMaCl-043CmZzYHe4-010_D417AAAC6405BBE84E5EF3DD7C885126
 CATZ_U2FsdGVkX18n4Ss-047pawbNcmjE-043fyJWf1QfcojfcCGQfLXgEpCT8-047GlmunMP-047SSySEmSpAzKh7ss-061-010_45155ACE59B3B1807672A21E78F7D633
 CATZ_U2FsdGVkX19cv82WKc65D18lRvSy2m0v5pt2nfFiY2W36dpJqnHeQg-061-061-010_22FBD021DA1305BB12F17C02CE8628D8
 CATZ_U2FsdGVkX19KyAYTRw6nTBemTufs5JZ2LwA91iBYtvhbjitV50zbXD3wYa5hWbWf-047qIoF-043zq-047-043e3-010RzEq-043krm218IyqplBZ8J-010_2C53412138204019B2C53C8B675497E8
 CATZ_U2FsdGVkX18t235Q7aEW4nwAiuUYJ-0476aoaGuAOoWV160GkNXa2Dpex3m211URU0mZY5RPvkkDlg-061-010_9078D69211CC6A800F275C727DBAC743
);

# some real keys but no results found

my @no = qw (
 CATZ_U2FsdGVkX1-043Grdiy3E5rhJnPQx2cRgXFoacicwCW7skwHKJ9w5a0OEJckoJPukurga0UNdylrnk-061-010_BC2EFEC6238340FFEACED4F7A98AC139
 CATZ_U2FsdGVkX19cnJRPTu8j7z-047bpSpcheWY0FViDh9WM-047r9Pzi1GnW5qy4L3t4rPDrVGZBUxy9U3uU-061-010_D80FF9B51E383910680A4D18250A0DB4
 CATZ_U2FsdGVkX19w2-0439bq-043SXW7dV5lP3Pk5Z8lG3E8KzkVXuiCHQNTH8RQsBoQz-043IiMwYvD9cu3bz04R-010k0gxMk3tzA-061-061-010_FA89005DEFA7E5F44E7F82F67450F938
);

# some keys that look fine but have a checksum mismatch

my @bad = qw (
 CATZ_U2FsdGVkX18n4Ss-047pawbNcmjE-043fyJWf1QfcojfcCGQfLXgEpCT8-047GlmunMP-047SSySEmSpAzKh7ss-061-010_45155BCE59B3B1807672A21E78F7D633
 CATZ_U2FsdGVkX19cv82rdc65D18lRvSy2m0v5pt2nfFiY2W36dpJqnHeQg-061-061-010_22FBD021DA1305BB12F17C02CE8628D8
 CATZ_U2FsdGVkX19KyAYTRw6-022nTBemTufs5JZ2LwA91iBYtvhbjitV50zbXD3wYa5hWbWf-055qIoF-043zq-047-043e3-010RzEq-043krm218IyqplBZ8J-010_2C53412138204019B2C53C8B675497E8
  CATZ_U2FsdGVkX19w2-0439bq-043SXW7dV5lP3Pk5Z8lG3E8KzkVXuiCHQNTH8RQsBoQz-043IiMwYvD9cu3bz04R-010k0gxMk3tzA-061-061-010_FA8910EDEFA7E5F44E7F82F97450F938
);

# some malformed keys

my @mal = qw (
 jaksdjflkasjdflkjasdl93290230320923890432809234908kajsdöfl
 U2FsdGVkX1-0477-0471c-0477nNUeY27fECUQiulGaVnCybW9OPosmsUSJyDA2MyIxwkzdFu-0474fJF9-0476Yvw-061-010_DD0A19AD40CDBDC4C4C342D0C50C9AD3
 CATZ_U2FsdGVkX19cv82.Kc65D18lRvSy2m0v5pt2nfFiY2W36dpJq.nHeQg-061-061-010_22FBD021DA1305BB12F17C02CE8628D8
 CATZ_U2FsdGVkX19cv82WKc65D18lRvSy2m0v5pt2nfFiY2W36dpJqnHeQg-061-061-010_22FBD021DA1305BBZ2F17C02CE8628X8
 CATZ_U2FsdGVkX19KyAYTRw6nTBemTufs5JZ2LwA91iBYtvhbjitV50zbXD3wYa5hWbWf-047qIoF-043zq-047-043e3-010RzEq-043krm218IyqplBZ8J-010_2C53412138204019B2C53C8B675497E8_832230328032093280
 CATZ_U2FsdGVkX1-043-043YXwWIg66EDIvIzBEbZijFADhj5TZuZTb8bb5wylMaCl-043CmZzYHe4-010_D417AAAC6405BBE84E5EF3DD7C8851263DE
);

my @chars =
 ( 'a' .. 'z', 'A' .. 'Z', '0' .. '9', qw (å ä ö Å Ä Ö ? - * @ !) );

my @huges = ();

foreach ( 1 .. 20 ) {

 my $key = join '',
  map { $chars[ rand @chars ] } ( 1 .. ( 50 + int ( rand ( 950 ) ) ) );

 push @huges, $key;

}

# with setup should fail
$t->get_ok ( "/en122111/result?x=" . $ok[ 1 ] )->status_is ( 404 );

foreach my $lang ( qw ( en fi ) ) {

 my $txt = text ( $lang );

 # no key / 1
 $t->get_ok ( "/$lang/result/" )->status_is ( 200 )
  ->content_type_like ( qr/text\/html/ )->content_is ( RESULT_NA );

 # empty key
 $t->get_ok ( "/$lang/result?x=" )->status_is ( 200 )
  ->content_type_like ( qr/text\/html/ )->content_is ( RESULT_NA );

 foreach my $key ( @ok ) {

  $t->get_ok ( "/$lang/result?x=$key" )->status_is ( 200 )
   ->content_type_like ( qr/text\/html/ );
   # disabled 8.5.2020
   #->content_like ( qr/$txt->{RESULT_CREDIT_URL}/ );

 }

 foreach my $key ( @bad, @mal, @huges ) {

  $t->get_ok ( "/$lang/result?x=$key" )->status_is ( 200 )
   ->content_type_like ( qr/text\/html/ )->content_is ( RESULT_NA );

 }

} ## end foreach my $lang ( qw ( en fi ))

done_testing;
