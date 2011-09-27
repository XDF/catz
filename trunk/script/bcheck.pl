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

use Catz::Util::File qw ( findlatest );
use Catz::Util::Log qw ( logadd logclose logopen logit logdone );
use Catz::Util::Time qw ( dt dtlang );

$| = 1; # unbuffered printing

logopen ( "../log/bcheck.log" );

logit "----- catza.net bcheck verifier started at " . dtlang ( 'en' );

my $net = Mojo::UserAgent->new;

#$net->log ( undef );
$net->name( text('en')->{AGENT_NAME} );
$net->keep_alive_timeout( 0 );
$net->max_connections( 1 );
$net->max_redirects( 5 );
$net->ioloop->connect_timeout ( 5 );

my $dbfile = findlatest ( '../db', 'db' );

my $dbc = DBI->connect( 
 'dbi:SQLite:dbname=' . $dbfile , undef, undef, 
 { AutoCommit => 0, RaiseError => 1, PrintError => 1 } 
)  or die "unable to connect to database $dbfile: $DBI::errstr";

my $s = $dbc->selectall_hashref ( 'select breeder as breeder,url as url from mbreeder order by breeder desc limit 15 offset 30', 'breeder' );

$dbc->disconnect;

open REPORT, '>../log/urlcheck_'.dt.'.html' or die $!;

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

logit 'generating report'; 
 
my $mt = Mojo::Template->new;

my $rep = $mt->render(<<'THEEND',$s);
<!doctype html><html>
% use Catz::Util::Time qw ( dtlang );
% my $s = shift;
% my $titl = "catza.net verifier ".dtlang ( 'en' );
% my $exp = { 
%  NOURL => 'URL not set in file',
%  BADSYNTAX => 'URL syntax error in file',
%  NOTFOUND => 'page not found',
%  TOOSMALL => 'content too small',
%  TOOLARGE => 'content too large',
%  CONTENT => 'content indicates an error',
%  OK => 'OK',
%  ODDCODE => 'strange response code',
%  NOCONN => 'unable to connect'
% };
<head><title><%= $titl %></title></head>
<body><h1><%= $titl %></h1></body>
<div><%= scalar keys %{ $s } %> breeders</div>
% foreach my $status ( qw ( 
% BADSYNTAX NOTFOUND NOCONN TOOSMALL TOOLARGE CONTENT ODDCODE OK NOURL ) ) {
<h2><%= $exp->{$status} %></h2>
%  foreach my $breeder ( sort keys %{ $s } ) {
%   if ( $s->{$breeder}->{status} eq $status ) {
<div><%= $breeder %> 
%    if ( $s->{$breeder}->{url} ) {
<a target="_blank" href="<%= $s->{$breeder}->{url} %>"><%= $s->{$breeder}->{url} %></a>
%    }
</div>
%   }
%  }
% }
</html>
THEEND

print REPORT $rep;

close REPORT;

logit "----- catza.net bcheck verifier finished at " . dtlang ( 'en' );

logclose;