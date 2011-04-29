use Test::More;
use Test::Mojo;
use Catz::Util::String qw ( enurl );
    
my $t = Test::Mojo->new(app => 'Catz');

my $c = 0;

foreach my $lang ( qw ( en fi ) ) {

 foreach my $what ( qw ( a s miu mim o 12 'e 100 200 ilt tavi 1/ / & ) ) {

  $t->get_ok("/$lang/find?what=".enurl($what))->status_is(200);
   
  $c=$c+2;

 } 

}

done_testing($c);
      