use Test::More;
use Test::Mojo;
    
my $t = Test::Mojo->new(app => 'Catz');

my $c = 0;

# auto language selection

$t->get_ok('/')->status_is(302);

$c += 2;

# root
    
$t->get_ok('/en/')->status_is(200);
$t->get_ok('/fi/')->status_is(200);

$c += 4;

# style

$t->get_ok('/style/bright/')->status_is(200)->content_type_is('text/css');
$t->get_ok('/style/dark/')->status_is(200)->content_type_is('text/css');
$t->get_ok('/style/reset/')->status_is(200)->content_type_is('text/css');

$c += 9;

# setup

$t->get_ok('/en/setup/')->status_is(200);
$t->get_ok('/fi/setup/')->status_is(200);

$c += 4;

$t->get_ok('/en/setup/reset/')->status_is(200);
$t->get_ok('/en/setup/thumbsperpage/30/')->status_is(200);
$t->get_ok('/en/setup/palette/bright/')->status_is(200);

$c += 6;

# news

$t->get_ok('/en/news/')->status_is(200);
$t->get_ok('/fi/news/')->status_is(200);

$c += 4;

done_testing($c);
      