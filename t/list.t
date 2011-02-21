use Test::More;
use Test::Mojo;
    
my $t = Test::Mojo->new(app => 'Catz');
    
$t->get_ok('/en/list/cat/a2z/')->status_is(200);
$t->get_ok('/fi/list/cat/a2z/')->status_is(200);

done_testing(4);