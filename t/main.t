use Test::More;
use Test::Mojo;
    
my $t = Test::Mojo->new(app => 'Catz::Core::App');

my $c = 0;

# auto language selection
$t->get_ok('/')->status_is(302);
$c += 2;

# root
$t->get_ok('/en')->status_is(301);
$t->get_ok('/fi')->status_is(301);    
$t->get_ok('/en/')->status_is(200);
$t->get_ok('/fi/')->status_is(200);

$c += 8;

# style

$t->get_ok('/style/bright/')->status_is(200)->content_type_is('text/css');
$t->get_ok('/style/neutral/')->status_is(200)->content_type_is('text/css');
$t->get_ok('/style/dark/')->status_is(200)->content_type_is('text/css');
$t->get_ok('/style/reset/')->status_is(200)->content_type_is('text/css');

$c += 12;

$t->get_ok('/style/stupidvalue/')->status_is(404);

$c += 2;

# setup

$t->get_ok('/set?display=none')->status_is(200)->content_like(qr/OK/);
$t->get_ok('/set?display=full')->status_is(200)->content_like(qr/OK/);
$t->get_ok('/set?palette=bright')->status_is(200)->content_like(qr/OK/);
$t->get_ok('/set?palette=dark')->status_is(200)->content_like(qr/OK/);
$t->get_ok('/set?palette=neutral')->status_is(200)->content_like(qr/OK/);
$t->get_ok('/set?photosize=fit')->status_is(200)->content_like(qr/OK/);
$t->get_ok('/set?photosize=original')->status_is(200)->content_like(qr/OK/);
$t->get_ok('/set?perpage=20')->status_is(200)->content_like(qr/OK/);
$t->get_ok('/set?perpage=40')->status_is(200)->content_like(qr/OK/);
$t->get_ok('/set?thumbsize=200')->status_is(200)->content_like(qr/OK/);
$t->get_ok('/set?thumbsize=150')->status_is(200)->content_like(qr/OK/);
$t->get_ok('/set?thumbsize=100')->status_is(200)->content_like(qr/OK/);
$t->get_ok('/set?peek=0')->status_is(200)->content_like(qr/OK/);

$c += 13 * 3;

# unknown keys
$t->get_ok('/set?nokey=novalue')->status_is(200)->content_like(qr/FAILED/);
$t->get_ok('/set?nokey=89023492234')->status_is(200)->content_like(qr/FAILED/);
$c += 2*3;

# too long key
$t->get_ok('/set?xyz1234567890123456789012345678901234567890123456789012345678901234567890=dark')->status_is(200)->content_like(qr/FAILED/);
$c += 3;

# too long value
$t->get_ok('/set?palette=1234567890123456789012345678901234567890123456789012345678901234567890')->status_is(200)->content_like(qr/FAILED/);
$c += 3;

# unset key
$t->get_ok('/set?=bright')->status_is(200)->content_like(qr/FAILED/);
$c += 3;

# unset value
$t->get_ok('/set?palette=')->status_is(200)->content_like(qr/FAILED/);
$c += 3;

# illegal values
$t->get_ok('/set?display=novalue')->status_is(200)->content_like(qr/FAILED/);
$t->get_ok('/set?palette=klajsdf')->status_is(200)->content_like(qr/FAILED/);
$t->get_ok('/set?photosize=89342342')->status_is(200)->content_like(qr/FAILED/);
$t->get_ok('/set?perpage=1000')->status_is(200)->content_like(qr/FAILED/);
$t->get_ok('/set?thumbsize=900')->status_is(200)->content_like(qr/FAILED/);
$t->get_ok('/set?peek=21343')->status_is(200)->content_like(qr/FAILED/);
$t->get_ok('/set?peek=auaiHHHS88')->status_is(200)->content_like(qr/FAILED/);
$c += 7*3;

# news
$t->get_ok('/en/news/')->status_is(200);
$t->get_ok('/fi/news/')->status_is(200);
$t->get_ok('/en/feed/')->status_is(200);
$t->get_ok('/fi/feed/')->status_is(200);
$t->get_ok('/en/news')->status_is(301);
$t->get_ok('/fi/news')->status_is(301);
$c += 6*2;

done_testing($c);
      