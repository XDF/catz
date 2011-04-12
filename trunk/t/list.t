use Test::More;
use Test::Mojo;
    
my $t = Test::Mojo->new(app => 'Catz');

my $c = 0;

foreach my $lang ( qw ( en fi ) ) {

 $t->get_ok("/$lang/list/cat/a2z/")->status_is(200);
 $t->get_ok("/$lang/list/ems4/top/")->status_is(200);
 $t->get_ok("/$lang/list/breeder/a2z/")->status_is(200);
 $t->get_ok("/$lang/list/ems5/top/")->status_is(200);

 $c=$c+8;
 
}

done_testing($c);