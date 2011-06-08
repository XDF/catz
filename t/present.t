use Test::More;
use Test::Mojo;
    
my $t = Test::Mojo->new(app => 'Catz::Core::App');

my $c = 0;

foreach my $lang ( qw ( en fi ) ) {

 foreach my $mode ( qw ( browse view ) ) {

  # no id
  
  $t->get_ok("/$lang/$mode".'all/')
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $t->get_ok("/$lang/$mode/nickname/Mikke/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);
   
  $t->get_ok("/$lang/$mode/catname/Peku/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);
 
  $c=$c+9;

  # with id
  
  $t->get_ok("/$lang/$mode".'all/157164/')
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $t->get_ok("/$lang/$mode/nickname/Mikke/157164/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);
   
  $t->get_ok("/$lang/$mode/catname/Peku/046182/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $c=$c+9;
  
  # 404
 
  $t->get_ok("/$lang/$mode/nickname/Mikke/789321/") # non-existsing id 
   ->status_is(404);

  $t->get_ok("/$lang/$mode/nickname/Mikke/046182/") # non-existing id in a set 
   ->status_is(404);

  $t->get_ok("/$lang/$mode/catname/Peku/87/") # too short id
   ->status_is(404);

  $t->get_ok("/$lang/$mode/catname/Peku/04618234/") # too long id
   ->status_is(404);
   
  $t->get_ok("/$lang/$mode/breeder/just_a_random_text/") # unknown breeder
   ->status_is(404);

  $t->get_ok("/$lang/$mode/breeder/just_a_random_text/046182/") 
   ->status_is(404); # unknown breeder
    
  $c=$c+12;
  
 }
 
}

done_testing($c);
      