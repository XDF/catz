#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2011 Heikki Siltala
# Licensed under The MIT License
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

use 5.10.0; use strict; use warnings;

use lib '../lib'; use lib '../libi';

use List::Util qw ( shuffle );

use Catz::Core::Conf;
use Catz::Load::Check;

use Catz::Util::Log qw ( logadd logclose logopen logit logdone );
use Catz::Util::Time qw ( dt dtexpand s2dhms dt2epoch );

sub ok {

 my ( $s, $breeder, $status ) = @_;

 $s->{breeders}->{$breeder}->{status} = $status;
 
 logit "$breeder $status";
 
 $s->{breeders}->{$breeder}->{done} = 1;
  
}

sub fail {

 my ( $s, $breeder, $status ) = @_;

 $s->{breeders}->{$breeder}->{status} = $status;
 
 logit "$breeder $status";
  
}

sub failf {

 my ( $s, $breeder, $status ) = @_;
  
 fail ( $s, $breeder, $status );
 
 $s->{breeders}->{$breeder}->{done} = 1;

} 

$| = 1; # unbuffered printing

logopen ( "../log/bcheck.log" );

# we use a MVC-like stash to hold data
my $s = {};

$s->{started} = dt;
$s->{started_en} = dtexpand $s->{started}, 'en';

logit "----- catza.net bcheck started at $s->{started_en}"; 

# open report file at early stage so if it 
# doesn't open then the check is aborted
open REPORT, '>../log/bheck.html' or die $!;

logit 'initializing';

check_init ( $s );

logit 'total ' . (  scalar keys %{ $s->{breeders} } ) . ' breeders';

my $rounds = 3;

foreach my $r ( 1 .. $rounds ) {

 logit "--- check round $r/$rounds";

 foreach my $b ( shuffle @{ $s->{bers} } ) {
      
  if ( $s->{breeders}->{$b}->{done} == 0 ) {

   logit "$b ...";
      
   if ( 
   defined $s->{breeders}->{$b}->{url_ok} and (
   (
    dt2epoch ( $s->{started} ) - 
    dt2epoch ( $s->{breeders}->{$b}->{url_ok} . '000000' ) )  
    < 60 * 60 * 24 * $s->{fresh} # skip for 180 days
   ) ) {
   
    ok ( $s, $b, 'FRESH' )
    
   } else {
   
    my $status = check_url $s->{breeders}->{$b}->{url};
   
    if ( $status eq 'OK' ) { ok ( $s, $b, $status ) } 
     elsif ( $r == $rounds ) { failf ( $s, $b, $status ) }
     else { fail ( $s, $b, $status ) }
     
    }
    
  }
   
 }
 
}

$s->{ended} = dt;
$s->{ended_en} = dtexpand $s->{ended}, 'en';

$s->{took} = [ s2dhms ( $s->{ended} - $s->{started} ) ];

print REPORT check_report $s;

close REPORT;

logit "----- catza.net bcheck finished at $s->{ended_en}";

logclose;