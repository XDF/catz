use Test::More;
use Test::Mojo;
    
my $t = Test::Mojo->new(app => 'Catz');

my $c = 0;

foreach my $lang ( qw ( en fi ) ) {

 $t->get_ok("/$lang/sample/")
  ->status_is(200)
  ->content_like(qr/\.JPG/);
   
 $c=$c+3;
  

 foreach my $n ( qw ( 10 20 25 30 50 99 ) ) {

  $t->get_ok("/$lang/sample/$n/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $c=$c+3;
 
 }
 
 foreach my $what ( qw ( thisisnotfound and888this99 ) ) {

  $t->get_ok("/$lang/sample/$what/")
   ->status_is(404);
   
  $c=$c+2;
 
 }
 
 foreach my $what ( qw ( a s miu mim o 12 'e 200 ilt tavi ) ) {

  $t->get_ok("/$lang/sample/$what/")
   ->status_is(200)
   ->content_like(qr/\.JPG/);
   
  $c=$c+3;

  foreach my $n ( qw ( 10 20 25 30 50 99 ) ) {

   $t->get_ok("/$lang/sample/$what/$n/")
    ->status_is(200)
    ->content_like(qr/\.JPG/);
    
   $c=$c+3;
    
  }
 
  foreach my $n ( qw ( 0 1 100 200 10000 ) ) {
  
   $t->get_ok("/$lang/sample/$what/$n/")
    ->status_is(404);
  
   $c=$c+2;
  
  }
  
 }
 
} 


done_testing($c);
      