use Test::More;
use Test::Mojo;
    
my $t = Test::Mojo->new(app => 'Catz::Core::App');

my $c = 0;

foreach my $lang ( qw ( en fi ) ) {

 foreach my $mode ( qw ( browse view ) ) {

  # no id
  
  $t->get_ok("/$lang/$mode/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $t->get_ok("/$lang/$mode?nick=Mikke")
   ->status_is(200)
   ->content_like(qr/\.JPG/);
   
  $t->get_ok("/$lang/$mode?cat=Peku")
   ->status_is(200)
   ->content_like(qr/\.JPG/);
 
  $c=$c+9;

  # with id
  
  $t->get_ok("/$lang/$mode?id=157164")
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $t->get_ok("/$lang/$mode?nick=Mikke&id=157164")
   ->status_is(200)
   ->content_like(qr/\.JPG/);
   
  $t->get_ok("/$lang/$mode?cat=Peku&id=046182")
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $c=$c+9;

  # more complex rules

  $t->get_ok("/$lang/$mode?nick=Mikke&bcode=TUV&feat=d")
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $t->get_ok("/$lang/$mode?nick=Mikke&bcode=TUV&feat=%2Bd")
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $t->get_ok("/$lang/$mode?nick=Mikke&bcode=%2BTUV&feat=%2Bd&id=157164")
   ->status_is(200)
   ->content_like(qr/\.JPG/);
  
  $t->get_ok("/$lang/$mode?bcode=-TUV&feat=%2Bd")
   ->status_is(200)
   ->content_like(qr/\.JPG/);  
 
  $t->get_ok("/$lang/$mode?has=cat")
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $t->get_ok("/$lang/$mode?has=code")
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $t->get_ok("/$lang/$mode?has=cat&id=170012")
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $c=$c+21; 

  # 404
 
  $t->get_ok("/$lang/$mode?nick=Mikke&id=789321") # non-existsing id 
   ->status_is(404);

  $t->get_ok("/$lang/$mode?nick=Mikke&id=046182") # non-existing id in a set 
   ->status_is(404);

  $t->get_ok("/$lang/$mode?cat=Peku&id=87") # too short id
   ->status_is(404);

  $t->get_ok("/$lang/$mode?cat=Peku&id=04618234") # too long id
   ->status_is(404);

  $t->get_ok("/$lang/$mode?cat=") # empty argument
   ->status_is(404);

  $t->get_ok("/$lang/$mode?breeder=just_a_random_text") # unknown breeder
   ->status_is(404);

  $t->get_ok("/$lang/$mode?breeder=just_a_random_text&id=046182") 
   ->status_is(404); # unknown breeder
  
  $t->get_ok("/$lang/$mode?has=-bcode&bcode=%2BTUV") # nothing found
   ->status_is(404);
  
  $c=$c+16;
  
 }
 
}

done_testing($c);
      