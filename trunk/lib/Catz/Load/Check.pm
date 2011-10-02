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

package Catz::Load::Check;

use 5.10.0; use strict; use warnings;

use parent 'Exporter';

our @EXPORT = qw ( check_init check_url check_report );

use DBI;
use LWP::UserAgent;
use Mojo::Template;

use Catz::Core::Text;
use Catz::Util::File qw ( findlatest );

our $status = [ qw (
 BADSYNTAX NOTFOUND FORBIDDEN NOCONN TOOSMALL 
 TOOLARGE CONTENT ODDCODE NOURL NEWCOMER FRESH OK
) ];

our $strings = { 
 NOURL => 'URL not defined',
 BADSYNTAX => 'URL syntax error',
 NOTFOUND => 'page not found',
 FORBIDDEN => 'access forbidden',
 TOOSMALL => 'content too small',
 TOOLARGE => 'content too large',
 CONTENT => 'content indicates an error',
 OK => 'OK',
 ODDCODE => 'unexpected response code',
 NOCONN => 'unable to connect',
 FRESH => 'marked and fresh',
 NEWCOMER => 'is in data but not in meta'
};

do {
 defined $strings->{$_} or die
  "status $_ defined but has no string"; 
} foreach @{ $status };

my $ua = LWP::UserAgent->new ( 
 agent => text('en')->{SITE} . ' ' . __PACKAGE__ . ' LWP::UserAgent Perl5',
 timeout => 10,
 max_redirect => 6  
);

my $mt = Mojo::Template->new;

sub check_init {

 my $s = shift;
 
 $s->{status} = $status; $s->{strings} = $strings;
 
 $s->{fresh} = 180; # a mark is fresh for 180 days

 my $dbfile = findlatest ( '../db', 'db' );

 my $dbc = DBI->connect( 
  'dbi:SQLite:dbname=' . $dbfile , undef, undef, 
  { AutoCommit => 0, RaiseError => 1, PrintError => 1 } 
 )  or die "unable to connect to database $dbfile: $DBI::errstr";

 # load breeders meta to stash
 $s->{breeders} = 
  $dbc->selectall_hashref ( qq {
   select breeder as breeder,url as url,nat as nat,url_ok as url_ok,
   nat_ok as nat_ok,0 as done, 'UNVERIFIED' as status,0 as failcount  
   from mbreeder order by breeder
 }, 'breeder' );
   
 # load nations to stash
 $s->{nats} = 
  $dbc->selectall_hashref ( 'select nat as nat from mnat', 'nat' );
  
 # load breeders from data that are not defined in meta
 $s->{newcomers} = $dbc->selectcol_arrayref ( qq {
  select sec from sec_en where pid in 
   ( select pid from pri where pri='breeder' )
  order by sort
 } );
   
 $dbc->disconnect;
 
 # we also store an array of breeder names
 $s->{bers} = [ sort keys %{ $s->{breeders} } ]; 

 foreach my $b ( @{ $s->{newcomers} } ) {

  # add record for each newcomer breeder 

  defined $s->{breeders}->{$b} or
   $s->{breeders}->{$b} = { status => 'NEWCOMER', done => 1 };
 
 }
 
 # quick check nations - errors are fatal
 foreach my $b ( @{ $s->{bers} } ) {
   
  defined $s->{breeders}->{ $b }->{nat} and do {
  
    defined $s->{nats}->{ $s->{breeders}->{$b}->{nat} } or
     die "nation $s->{breeders}->{ $b }->{nat} not defined";
  
  }; 
 
 }
   
}

sub check_url {

 my $url = shift // undef;
  
defined $url or return 'NOURL';
 
 ( ( substr $url, 7 ) eq 'http://' ) and return 'BADSYNTAX';    
      
 my $res = $ua->get( $url );
  
 my $code = $res->code // undef ;
 my $cont = $res->content // undef;
 
 $code or return 'NOCONN';
 
 ( $code eq '404' or $code eq '410' ) and return 'NOTFOUND';
 
 $code eq '403' and return 'FORBIDDEN';
 
 $code ne '200' and return 'ODDCODE';
 
 length $cont < 70 and return 'TOOSMALL';
 
 length $cont > 200_000 and return 'TOOLARGE';
  
 $cont =~ m|not found|i and return 'CONTENT';
 $cont =~ m|ei löydy|i and return 'CONTENT';      

 return 'OK';      
    
}

sub check_report {

 return $mt->render( 
  ( join "\n", map { chomp $_; $_ } <DATA> ), 
  $_[0], text('en') 
 );
   
}

1;
 
__DATA__
% my ( $s, $t ) = @_;
% use Catz::Util::String qw ( enurl );
<% my $google = begin %>
% my ( $s, $l, $q ) = @_;
http://www.google.fi/search?&client=<%= enurl $s %>&rls=<%= enurl $l %>&q=<%= enurl $q %>
<% end %>
<!doctype html><html>
% my $slogan =  'breeder URL check';
<head><title><%= $t->{SITE} %> <%= $slogan %></title></head>
<body><h1><%= $t->{SITE} %> <%= $slogan %></h1>
<style type="text/css">
body {
 font-family: verdana;
 font-size: 88%;
}
table {
	border-width: 1px;
	border-spacing: 10px;
	border-style: solid;
	border-color: gray;
	border-collapse: collapse;
}
table td {
	border-width: 1px;
	padding: 10px;
	border-style: solid;
	border-color: gray;
}
</style>
<div>
<table><tr>
<td>started <%= $s->{started_en} %></td>
<td>finished <%= $s->{ended_en} %></td>
<td>took <%= $s->{took}->[0] %> <%= $t->{DAYS} %>
<%= $s->{took}->[1] %> <%= $t->{HOURS} %>
<%= $s->{took}->[2] %> <%= $t->{MINUTES} %>
<%= $s->{took}->[3] %> <%= $t->{SECONDS} %></td></tr>
<tr><td colspan="3">total <%= scalar keys %{ $s->{breeders} } %> breeder(s)</td></tr>
</table>
% foreach my $st ( @{ $s->{status} } ) {
<h2><%= $s->{strings}->{$st} %>
% if ( $st eq 'FRESH' ) {
(<%= $s->{fresh} %> <%= $t->{DAYS} %>) 
% }
</h2>
<table>
% my $i = 0;
%  foreach my $b ( sort keys %{ $s->{breeders} } ) {
%   if ( $s->{breeders}->{$b}->{status} eq $st ) {
%    $i++;
<tr><td align="right"><%= $b %></td> 
%    if ( $s->{breeders}->{$b}->{url} ) {
<td align="left"><a target="_blank" href="<%= $s->{breeders}->{$b}->{url} %>">
<%= $s->{breeders}->{$b}->{url} %></a></td>
%    } else {
<td>-</td>
%    }
<td>
<a target="_blank" href="<%= $google->($t->{SITE},'fi',"$b kissala") %>">Google kissala</a>
<a target="_blank" href="<%= $google->($t->{SITE},'en',"$b cattery") %>">Google cattery</a>
</td>
<tr>
%   }
%  }
% if ( $i == 0 ) {
<tr><td>-</td></tr>
% } else {
<tr><td colspan="3">total <%= $i %> breeder(s)</td></tr>
% }
% $s->{counters}->{$st} = $i;
</table>
% }
<h2><%= $t->{SUMMARY} %></h2>
<table>
% foreach my $st ( @{ $s->{status} } ) {
<tr><td><%= $s->{strings}->{$st} %></td>
<td><%= $s->{counters}->{$st} %></td></tr>
% }
<tr><td><b>total<b></td><td><b><%= scalar keys %{ $s->{breeders} } %></b></td></tr> 
</table>
</body>
</html>