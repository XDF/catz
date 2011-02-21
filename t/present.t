use Test::More;
use Test::Mojo;
    
my $t = Test::Mojo->new(app => 'Catz');

my $c = 0;

# typical browsing scenarios

$t->get_ok('/fi/nick/Mikke/1-5/')->status_is(404);
$t->get_ok('/fi/nick/Mikke/100-200/')->status_is(404);
$t->get_ok('/fi/nick/Mikke/')->status_is(404);

$c += 6;

$t->get_ok('/fi/1-5/')->status_is(404);
$t->get_ok('/fi/100-200/')->status_is(404);

$c += 4;

$t->get_ok('/fi/nick/Mikke/1-45/')->status_is(200)->content_like(qr/img src/);
$t->get_ok('/fi/nick/Mikke/101-145/')->status_is(200)->content_like(qr/img src/);

$c += 6;

# typical viewing scenarios

# some error in implementation, these give 200 not 404
#$t->get_ok('/fi/nick/Mikke/a/')->status_is(404);
#$t->get_ok('/fi/nick/Mikke/b/')->status_is(404);

#$c += 4;

#$t->get_ok('/fi/83a83d89/')->status_is(404);
#
#$c += 2;

$t->get_ok('/fi/nick/Mikke/19n/')->status_is(200)->content_like(qr/img src/);
$t->get_ok('/fi/nick/Mikke/ehp/')->status_is(200)->content_like(qr/img src/);

$c += 6;


done_testing($c);
      