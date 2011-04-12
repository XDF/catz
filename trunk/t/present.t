use Test::More;
use Test::Mojo;
    
my $t = Test::Mojo->new(app => 'Catz');

my $c = 0;

foreach my $lang ( qw ( en fi ) ) {

 foreach my $mode ( qw ( browse inspect show ) ) {

  # no id
  
  $t->get_ok("/$lang/$mode/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $t->get_ok("/$lang/$mode/nick/Mikke/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);
   
  $t->get_ok("/$lang/$mode/cat/Peku/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);
 
  $c=$c+9;

  # with id
  
  $t->get_ok("/$lang/$mode/157164/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $t->get_ok("/$lang/$mode/nick/Mikke/157164/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);
   
  $t->get_ok("/$lang/$mode/cat/Peku/046182/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $c=$c+9;

  # more complex rules

  $t->get_ok("/$lang/$mode/nick/Mikke/ems3/TUV/ems1/d/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $t->get_ok("/$lang/$mode/nick/Mikke/ems3/+TUV/ems1/+d/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $t->get_ok("/$lang/$mode/nick/Mikke/ems3/+TUV/ems1/+d/157164/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);
  
  $t->get_ok("/$lang/$mode/ems3/-TUV/ems1/+d/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);  
 
  $t->get_ok("/$lang/$mode/has/cat/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $t->get_ok("/$lang/$mode/has/ems5/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $t->get_ok("/$lang/$mode/has/cat/170012/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $c=$c+21; 

  # 404
 
  $t->get_ok("/$lang/$mode/nick/Mikke/789321/") # non-existsing id 
   ->status_is(404);

  $t->get_ok("/$lang/$mode/nick/Mikke/046182/") # non-existing id in a set 
   ->status_is(404);

  $t->get_ok("/$lang/$mode/cat/Peku/87/") # too short id
   ->status_is(404);

  $t->get_ok("/$lang/$mode/cat/Peku/0461824/") # too long id
   ->status_is(404);

  $t->get_ok("/$lang/$mode/cat/") # no argument pair
   ->status_is(404);

  $t->get_ok("/$lang/$mode/breeder/just_a_random_text/") # unknown breeder
   ->status_is(404);

  $t->get_ok("/$lang/$mode/breeder/just_a_random_text/046182/") 
   ->status_is(404); # unknown breeder
  
  $t->get_ok("/$lang/$mode/has/-ems3/ems3/+TUV/") # nothing found
   ->status_is(404);
  
  $c=$c+16;
  
 }
 
}

done_testing($c);
      