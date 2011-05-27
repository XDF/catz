use Test::More;
use Test::Mojo;
    
my $t = Test::Mojo->new(app => 'Catz::Core::App');

my $c = 0;

foreach my $lang ( qw ( en fi ) ) {

 $t->get_ok("/$lang/list/cat/a2z/")->status_is(200);
 $t->get_ok("/$lang/list/app/top/")->status_is(200);
 $t->get_ok("/$lang/list/breeder/a2z/")->status_is(200);
 $t->get_ok("/$lang/list/code/top/")->status_is(200);

 $c=$c+8;
  
 $t->get_ok("/$lang/list/text/top/")->status_is(404);
 $t->get_ok("/$lang/list/folder/a2z/")->status_is(404);
 $t->get_ok("/$lang/list/rindom/top/")->status_is(404);
 $t->get_ok("/$lang/list/cat/894/")->status_is(404);

 $c=$c+8;
 
}

done_testing($c);