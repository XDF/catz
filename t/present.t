use Test::More;
use Test::Mojo;
    
my $t = Test::Mojo->new(app => 'Catz');

my $c = 0;

# typical browsing scenarios

$t->get_ok('/fi/show/nick/Mikke/1-5/')->status_is(404);
$t->get_ok('/en/show/nick/Mikke/100-200/')->status_is(404);
$t->get_ok('/fi/show/nick/Mikke/')->status_is(404);

$c += 6;

$t->get_ok('/fi/show/1-5/')->status_is(404);
$t->get_ok('/fi/show/100-200/')->status_is(404);

$c += 4;

$t->get_ok('/fi/show/1-45/')->status_is(200)->content_like(qr/img src/);
$t->get_ok('/en/show/101-145/')->status_is(200)->content_like(qr/img src/);

$c += 6;

$t->get_ok('/fi/show/nick/Mikke/1-45/')->status_is(200)->content_like(qr/img src/);
$t->get_ok('/en/show/nick/Mikke/101-145/')->status_is(200)->content_like(qr/img src/);

$c += 6;

# typical viewing scenarios

# some error in implementation, these give 200 not 404
$t->get_ok('/fi/show/nick/Mikke/adsf3rasdfa/')->status_is(404);
$t->get_ok('/en/show/nick/Mikke/23293929/')->status_is(404);

$c += 4;

$t->get_ok('/fi/show/83a83d89/')->status_is(404);

$c += 2;

$t->get_ok('/fi/show/nick/Mimosa/12057/')->status_is(200)->content_like(qr/img src/);
$t->get_ok('/en/show/nick/Mimosa/29095/')->status_is(200)->content_like(qr/img src/);

$c += 6;

$t->get_ok('/fi/sample/nick/Mimosa/5/')->status_is(200)->content_like(qr/img src/);
$t->get_ok('/en/sample/15/')->status_is(200)->content_like(qr/img src/);

$c += 6;

$t->get_ok('/fi/suggest/ol/')->status_is(200);
$t->get_ok('/en/suggest/s/')->status_is(200);
$t->get_ok('/en/suggest/mik/')->status_is(200);

$c += 6;

done_testing($c);
      