package Catz::Brick::Run;

use 5.12.2;
use strict;
use warnings;

use parent 'Exporter';

our @EXPORT = qw ( run );

# *** HIGHLY IMPORTANT ***
# classic static use of all Brick modules here
# otherwise their subs are not found at runtime
use Catz::Brick::Style;

sub run {

 my $sys = shift;

 { 

  no strict 'refs';

  $res = $sub->( $dbs->{$dt}, $lang, @args );
 
 }


}

 my ( $dt, $lang, $sub, @args ) = @_;
 
 my $res;
 
 if ( conf('cache_model' ) ) {
 
  # try to get the requested result from the cache
  
  $res = cache_get ( $dt, $lang, $sub, @args );
 
  $res and return $res; # if cache hit then done
 
 }
 
 # if database is unknown for this dt then create new database connetion
 $dbs->{$dt} or ( $dbs->{$dt} = Catz::Data::Databse->new ( $dt ) );
 

 
 if ( conf('cache_model' ) ) {
  cache_set ( $dt, $lang, $sub, @args, $res );
 }
 
 return $res; 

}

1;
