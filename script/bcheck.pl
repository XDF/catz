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
use Catz::Util::Time qw ( dt dtexpand s2dhms );

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

 logit "check round $r/$rounds";

 foreach my $b ( shuffle @{ $s->{bers} } ) {
    
  if ( $s->{breeders}->{$b}->{done} == 0 ) {
  
   logit "$b ...";
   
   my $status = check_url $s->{breeders}->{$b}->{url};
   
   if ( $status eq 'OK' ) { ok ( $s, $b, $status ) } 
    elsif ( $r == $rounds ) { failf ( $s, $b, $status ) }
    else { fail ( $s, $b, $status ) }
    
  }
   
 }
 
}

$s->{ended} = dt;
$s->{ended_en} = dtexpand $s->{ended}, 'en';

$s->{took} = [ s2dhms ( $s->{ended} - $s->{started} ) ];

print REPORT check_report $s;

close REPORT;

logit "----- catza.net bcheck finished at $s->{ended_en}";

__END__






foreach my $r ( 1 .. 3 ) {

 logit "round $r/3";

 foreach my $b ( shuffle keys %{ $s } ) {
    
  if ( $s->{$b}->{done} == 0 ) {
  
   logit "$b ...";
 

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