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

use DBI;
use List::Util qw ( shuffle );
use Mojo::Template;
use Mojo::UserAgent;

use Catz::Core::Conf;
use Catz::Core::Text;

use Catz::Util::File qw ( fileread );
use Catz::Load::Data qw ( tolines topiles );
use Catz::Util::Log qw ( logadd logclose logopen logit logdone );
use Catz::Util::Time qw ( dt dtlang );

$| = 1; # unbuffered printing

logopen ( "../log/bcheck.log" );

my $start = dt;

logit '----- catza.net bcheck verifier started at '.dtlang ( 'en' );

my $net = Mojo::UserAgent->new;

#$net->log ( undef );
$net->name( text('en')->{AGENT_NAME} );
$net->keep_alive_timeout( 0 );
$net->max_connections( 1 );
$net->max_redirects( 5 );
$net->ioloop->connect_timeout ( 5 );

open REPORT, '>../log/urlcheck_'.dt.'.html' or die $!;

my $s = {};

foreach my $pile ( topiles ( readfile '../data/mbreeder.txt' ) ) {

 my @lines = tolines ( $pile );
 
 scalar @lines == 3 or 
  die "failed to read data for $lines[0]: invalid number of records";

 $lines[1] =~ /^(.+)\s+(\d{6})\s*$/ and $lines[1] = $1;

    $lines[2] =~ /^(.+)\s+(\d{6})\s*$/ and $lines[2] = $2;
     

}
 
logit 'total ' . (  scalar keys %{ $s } ) . ' breeders';

logit 'initializing';

foreach my $b ( keys %{ $s } ) {

 # initializing records
 
 $s->{$b}->{done} = 0;
 $s->{$b}->{status} = 'UNVERIFIED';
   
}

sub fail {

 my ( $breeder, $status ) = @_;

 $s->{$breeder}->{status} = $status;
 
 logit "$breeder $status";
  
}

sub failf {

 my ( $breeder, $status ) = @_;
  
 fail ( $breeder, $status );
 
 $s->{$breeder}->{done} = 1;

} 

foreach my $r ( 1 .. 3 ) {

 logit "round $r/3";

 foreach my $b ( shuffle keys %{ $s } ) {
    
  if ( $s->{$b}->{done} == 0 ) {
  
   logit "$b ...";
 
   if ( not defined $s->{$b}->{url} ) {
   
    failf ( $b, 'NOURL' );
    
   } elsif ( substr ( $s->{$b}->{url}, 0, 7 ) ne 'http://' ) {
      
    failf ( $b, 'BADSYNTAX' );    
   
   } else {
   
    my $get = $net->get($s->{$b}->{url})->res;

    my $body = $get->body // undef;
    my $code = $get->code // undef ;
    
    if ( $code ) {
    
     if ( $code eq 404 or $code eq 410 ) { # not found -> try once
    
      failf ( $b, 'NOTFOUND' ); 
    
     } elsif ( $code eq 200 ) {
     
      if ( length $body < 50 ) {

       failf ( $b, 'TOOSMALL' );
        
      } elsif ( length $body > 500000 ) { 
           
       failf ( $b, 'TOOLARGE' );  
      
      } else {
      
       if ( $body =~ m|not found|i ) {
       
        failf ( $b, 'CONTENT' );
                     
       } else {
      
        failf ( $b, 'OK' );
         
       }
      
      }
    
     } else {

      if ( $r < 3 ) { # odd codes -> try twice
      
       fail ( $b, 'T_ODDCODE' );
     
      } else {

       failf ( $b, 'ODDCODE' );
      
      }
     
     }
    
    } else {
    
     if ( $r < 3 ) { # odd codes -> try twice
      
      fail ( $b, 'T_NOCONN' );
     
     } else {

      failf ( $b, 'NOCONN' );
      
     }
    }
   }
  }
 }  
}

my $end = dt;

logit 'generating report'; 
 
my $mt = Mojo::Template->new;

my $rep = $mt->render(<<'THEEND',$s,$start,$end);
<!doctype html><html>
% use Catz::Core::Text;
% my $t = text('en');
% use Catz::Util::Time qw ( dtexpand dt2epoch s2dhms );
% my ( $s, $start, $end ) = @_;
% my $exp = { 
%  NOURL => 'URL not defined',
%  BADSYNTAX => 'URL syntax error',
%  NOTFOUND => 'page not found',
%  TOOSMALL => 'content too small',
%  TOOLARGE => 'content too large',
%  CONTENT => 'content indicates an error',
%  OK => 'OK',
%  ODDCODE => 'unexpected response code (3 attempts)',
%  NOCONN => 'unable to connect (3 attempts)'
% };
<head><title><%= $t->{SITE} %> verifier</title></head>
<hr>
<body><h1><%= $t->{SITE} %> verifier</h1>
<div>
started <%= dtexpand $start, 'en' %><br>
finished <%= dtexpand $end, 'en' %><br>
% my @arr = s2dhms ( $end - $start );
<%= "$arr[0] days $arr[1] hours $arr[2] minutes $arr[3] seconds" %><br>
total <%= scalar keys %{ $s } %> breeders
</div>
% foreach my $status ( qw ( 
% BADSYNTAX NOTFOUND NOCONN TOOSMALL TOOLARGE CONTENT ODDCODE OK NOURL ) ) {
<hr width="100%">
<h2><%= $exp->{$status} %></h2>
<table>
%  foreach my $breeder ( sort keys %{ $s } ) {
%   if ( $s->{$breeder}->{status} eq $status ) {
<tr><td align="right"><%= $breeder %></td> 
%    if ( $s->{$breeder}->{url} ) {
<td align="left"><a target="_blank" href="<%= $s->{$breeder}->{url} %>"><%= $s->{$breeder}->{url} %></a></td>
%    } else {
<td>&nbsp;</tD<
% }
<tr>
%   }
%  }
</table>
% }
<hr>
</body>
</html>
THEEND

print REPORT $rep;

close REPORT;

logit "----- catza.net bcheck verifier finished at " . dtlang ( 'en' );

logclose;