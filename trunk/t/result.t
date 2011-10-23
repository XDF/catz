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

# unbuffered outputs
# from http://perldoc.perl.org/functions/open.html
select STDERR; $| = 1; 
select STDOUT; $| = 1; 

use Test::More;
use Test::Mojo;

use Catz::Core::Text;

my $t = Test::Mojo->new( 'Catz::Core::App' );

use constant RESULT_NA => '<!-- N/A -->';

# some working keys

my @ok = qw (
 CATZ-KNQWY5DFMRPV6E5XV5DPSEXHL54MK6LVC3XRGN22ZKJAF2JYLQASEZQ2BCTMUY2XOWA6W3DLMW66VPFAFAMDFNT5J2WK6NRVETOAMHY-433AE89FE61846F29F6BB6E7211E114C 
 CATZ-KNQWY5DFMRPV6BIEYZCPK62UNZYDJN4PZDPRCDUQWTHJF6HYXIVH6UVQMZOMJUX3VIMEF5XKXLP2QK3XHRH76ZJ3WM-68599A93057342F613E17FD12E072834
 CATZ-KNQWY5DFMRPV6XC6EXEFFN7QHBSH2DLFUITYCUTWPV2TEA23K5W7TFWYH7N5AI3ADB3KIL2QRTP2RVSIOIAU3CMMBA3AKDCRNNW375I-C3785C8DBDAB2684CAF22D79217002BA
 CATZ-KNQWY5DFMRPV6KQTC5REO335CKLKBVFO6QDXS3Y5ZUU4THCSA5ZW4X73VAHFJ7VB7W44VFYNTDFZPGQHGNBAVPINZA-B69A694C280269304CA795FAB9616418
 CATZ-KNQWY5DFMRPV7TDY4AW5QM2FQ5XU643BLG6POEV5IOHFS37JYI5QWH3ZAGKYYFYJWJWLH4DGJKGMC33MW4S2HPKHDHDIG42BDOLRWZI-95FA25FD510CC80C94023D8BE21240A4
 CATZ-KNQWY5DFMRPV6CK4WQ7JKCCQWHGU2AY6VDHXKQCSNJC5DFO7LHQAZX6D7D5IINXXITMYAOZNOMCD5CHOI2FFLFYQKI-2A7DA534C0D07DB11B320B1282DD186A
 CATZ-KNQWY5DFMRPV7UW2I62SRG2URCQBMAHJEOUBIG37OKRMGRNNNPW5VRY5P2VCIAFE4FQ6DNN3AZY7RPQHWRI3DRFJLNN4MO547K2VTCI-8B9468E11C32FBC41755B8F0E418E54D
);

# some real keys but no results found

my @no = qw (
 CATZ-KNQWY5DFMRPV7S7QNQUA5DLQLHEJGLY7UM3KIQ42FRKRA5YTRCAQIRB7T4MPXFNUJRZ3ZE7F32TNK652WOAO7USQ74-120F3FC4354D4C93C2E5F70EFEFAFF36
 CATZ-KNQWY5DFMRPV7I5NFM4OJK5IEGROY6DMWMTM5NG2NUIO5YCDFMDI46TJ753V66BSHN3VGPGVYC63UAKIIAZI3E6URI-38825A917B93F07AAD548676C07E6A99
 CATZ-KNQWY5DFMRPV7BD6LU2DQXUANFJ4OAQW5PNSZYV22PGJFKW73OR4GDUF5AVGAJOBPLRS4VXG46JZRNMXJEYVPK4YNU-D92EAFA672BF1AC91D885A1386BF764C
);

# some keys that look fine but have a checksum mismatch

my @bad = qw (
 CATZ-KNQWY5DFMRPV7S7QNQUA5DLQLHEJGLY7UM3KIQ42FRKRA5YTRCAQIRB7T4MPXFNUJRZ3ZE7F32TNK652WOAO7USQ74-433AE89FE61846F29F6BB6E7211E114C
 CATZ-KNQWY5DFMRPV6KQTC5REO335CKLKBVFO6QDXS3Y5ZUU4THCSA5ZW4X73VAHFJ7VB7W44VFYNTDFZPGQHGNBAVPINZA-D92EAFA672BF1AC91D885A1386BF764C
 CATZ-KNQWY5DFMRPV6KQTC5REO335CKLKBVFO6QDXS3Y5ZUU4THCSA5ZW4X73VAHFJ7VB7WUU4THCSA5ZW4X73VAHFJ7VB7W44VFYN44VFYNTDFZPGQHGNBAVPINZA-D92EAFA672BF1AC91D885A1386BF764C
 CATZ-KNQWY5DFMRPV6KQTC5VPINZA-D92EAFA672BF1AC91D885A1386BF764C
);

# some malformed keys

my @mal = qw (
 CATZ-KNQWY5DFMRPV6KQTC5REO335CKLKBVFO6QDXS3Y5ZUU4THCSA5ZW4X73VAHFJ7VB7W44VFYNTDFZPGQHGNBAVPINZA-D92EAFA672BF1AC91D885A1386B4C
 CATZ-KNQWY5DFMRPV6KQTC5REO335CKLKBVFO6QDXS3Y5ZUU4THCSA5ZW4X73VAHFJ7VB7W44VFYNTDFZPGQHGNBAVPINZA-D92EAFA672BF1AC91D885A1386B4C2BF1AC91D885A1386B
 ZTAC-KNQWY5DFMRPV6XC6EXEFFN7QHBSH2DLFUITYCUTWPV2TEA23K5W7TFWYH7N5AI3ADB3KIL2QRTP2RVSIOIAU3CMMBA3AKDCRNNW375I-C3785C8DBDAB2684CAF22D79217002BA
 KNQWY5DFMRPV6XC6EXEFFN7QHBSH2DLFUITYCUTWPV2TEA23K5W7TFWYH7N5AI3ADB3KIL2QRTP2RVSIOIAU3CMMBA3AKDCRNNW375I-C3785C8DBDAB2684CAF22D79217002BA
 KNQWY5DFMRPV6XC6EXEFFN7QHBSH2DLFUITYCUTWPV2TEA23K5W7TFWYH7N5AI3ADB3KIL2QRTP2RVSIOIAU3CMMBA3AKDCRNNW375IC3785C8DBDAB2684CAF22D79217002BA
 jasdfkljasdfk23lk2j3l4k2j34lkj23lk4j234lkj23lk4j23lk4j2lk341212jdjJJJJ
 m3kj3k3jlk3jlk3KJLKWJALKJAWKKLJWLW
);

my @chars = ( 'a'..'z','A'..'Z','0'..'9',qw (å ä ö Å Ä Ö ? - * @ !));

my @huges = ();

foreach ( 1 .. 20 ) {

 my $key = join '', 
  map { $chars[ rand @chars ] } ( 1 .. ( 50 + int ( rand ( 950 ) ) ) );

 push @huges, $key;
 
} 
 
foreach my $lang ( qw ( en fi ) ) {

 my $txt = text ( $lang );

 # no key / 1
 $t->get_ok("/$lang/result/")
  ->status_is(200)
  ->content_type_like(qr/text\/html/)
  ->content_is(RESULT_NA);

 # empty key
 $t->get_ok("/$lang/result?x=")
  ->status_is(200)
  ->content_type_like(qr/text\/html/)
  ->content_is(RESULT_NA);
 
 foreach my $key ( @ok ) {
 
  $t->get_ok("/$lang/result?x=$key")
    ->status_is(200)
    ->content_type_like(qr/text\/html/)
    ->content_like(qr/$txt->{RESULT_CREDIT_URL}/);

 }
 
 foreach my $key ( @bad, @mal, @huges ) {
 
  $t->get_ok("/$lang/result?x=$key")
    ->status_is(200)
    ->content_type_like(qr/text\/html/)
    ->content_is(RESULT_NA);
 
 }

}

done_testing;