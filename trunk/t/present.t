use Test::More;
use Test::Mojo;
    
my $t = Test::Mojo->new(app => 'Catz');

my $c = 0;

# typical browsing scenarios

$t->get_ok('/fi/browse/nick/Mikke/1-5/')->status_is(404); # too few photos
$t->get_ok('/en/browse/nick/Mikke/100-200/')->status_is(404); # too much photos
$t->get_ok('/fi/browse/nick/Mikke/')->status_is(404); # no photos

$c += 6;

$t->get_ok('/fi/browse/1-5/')->status_is(404);
$t->get_ok('/fi/browse/100-200/')->status_is(404);
$t->get_ok('/fi/browse/101-200/')->status_is(404);

$c += 6;

$t->get_ok('/fi/browse/1-45/')->status_is(200)->status_is(200);
$t->get_ok('/en/browse/101-145/')->status_is(200)->status_is(200);

$c += 6;

$t->get_ok('/fi/browse/nick/Mikke/1-45/')->status_is(200)->content_like(qr/img src/);
$t->get_ok('/en/browse/nick/Mikke/101-145/')->status_is(200)->content_like(qr/img src/);

$c += 6;

# typical viewing scenarios

$t->get_ok('/fi/view/nick/Mikke/adsf3rasdfa/')->status_is(404);
$t->get_ok('/en/view/nick/Mikke/23293929/')->status_is(404);

$c += 4;

$t->get_ok('/fi/view/83a83d89/')->status_is(404);
$t->get_ok('/fi/view/93k-1000/')->status_is(404);

$c += 4;

$t->get_ok('/fi/view/nick/Mimosa/20090802helsinki/168/')->status_is(200)->content_like(qr/img src/);
$t->get_ok('/en/view/breeder/Cesmes/20090802helsinki/168/')->status_is(200)->content_like(qr/img src/);

$c += 6;

$t->get_ok('/en/view/breeder/20090802helsinki/168/')->status_is(404);
$t->get_ok('/en/view/Cesmes/20090802helsinki/168/')->status_is(404);
$t->get_ok('/en/view/breeder/1-20/')->status_is(404);
$t->get_ok('/en/view/Cesmes/1-20/')->status_is(404);

$c += 8;

$t->get_ok('/fi/sample/nick/Mimosa/5/')->status_is(200)->content_like(qr/img src/);
$t->get_ok('/en/sample/15/')->status_is(200)->content_like(qr/img src/);

$c += 6;

$t->get_ok('/en/sample/')->status_is(404);

$c += 2;

$t->get_ok('/fi/suggest/ol/')->status_is(200);
$t->get_ok('/en/suggest/s/')->status_is(200);
$t->get_ok('/en/suggest/mik/')->status_is(200);

$c += 6;

done_testing($c);
      