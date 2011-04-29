use Test::More;
use Test::Mojo;
    
my $t = Test::Mojo->new(app => 'Catz');

my $c = 0;

foreach my $lang ( qw ( en fi ) ) {

 $t->get_ok("/$lang/search/")->status_is(200);
 $t->get_ok("/$lang/search?what=cat%3D*s*+%2Bems3%3D%3F%3FO")->status_is(200);

 $c += 4;
 
}

done_testing($c);
      