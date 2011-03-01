use Test::More;
use Test::Mojo;
    
my $t = Test::Mojo->new(app => 'Catz');

my $c = 0;

$t->get_ok('/en/search/')->status_is(200);
$t->get_ok('/fi/search/?what=cat%3D*s*+%2Bems3%3D%3F%3FO')->status_is(200);

$c += 4;

done_testing($c);
      