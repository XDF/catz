use Test::More;
use Test::Mojo;

use Catz::Util::String qw ( enurl );
    
my $t = Test::Mojo->new(app => 'Catz::Core::App');

my $c = 0;

foreach my $lang ( qw ( en fi ) ) {

 $t->get_ok("/$lang/sample/")
  ->status_is(200)
  ->content_like(qr/\.JPG/);
   
 $c=$c+3;
  

 foreach my $n ( qw ( 100 300 500 1111 1582 2222 ) ) {

  $t->get_ok("/$lang/sample?width=$n")
   ->status_is(200)
   ->content_like(qr/\.JPG/);

  $c=$c+3;
 
 }
 
 foreach my $what ( qw ( thisisnotfound and888this99 ) ) {

  $t->get_ok("/$lang/sample?what=$what")
   ->status_is(200);
   
  $c=$c+2;
 
 }
 
 foreach my $what ( qw ( a s miu mim o 12 'e 200 ilt tavi ) ) {

  $t->get_ok("/$lang/sample?what=".enurl($what))
   ->status_is(200)
   ->content_like(qr/\.JPG/);
   
  $c=$c+3;

  foreach my $n ( qw ( 100 300 500 1111 1582 2222 ) ) {
  
   my $url = "/$lang/sample?what=".enurl($what).'&width='.$n;
   
   $t->get_ok($url)
     ->status_is(200)
     ->content_like(qr/\.JPG/);
    
    $c=$c+3;
    
  }
   
 }
 
} 


done_testing($c);
      