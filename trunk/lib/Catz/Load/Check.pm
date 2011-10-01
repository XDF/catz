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
 BADSYNTAX NOTFOUND FORBIDDEN NOCONN TOOSMALL TOOLARGE CONTENT ODDCODE OK NOURL
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

 my $dbfile = findlatest ( '../db', 'db' );

 my $dbc = DBI->connect( 
  'dbi:SQLite:dbname=' . $dbfile , undef, undef, 
  { AutoCommit => 0, RaiseError => 1, PrintError => 1 } 
 )  or die "unable to connect to database $dbfile: $DBI::errstr";

 # load breeders to stash
 $s->{breeders} = 
  $dbc->selectall_hashref ( qq {
   select breeder as breeder,url as url,nat as nat,url_ok as url_ok,
   nat_ok as nat_ok,0 as done, 'UNVERIFIED' as status,0 as failcount  
   from mbreeder order by random() desc limit 25 
  }, 'breeder' );
  
 # we also store an array of breeder names
 $s->{bers} = [ sort keys %{ $s->{breeders} } ];
 
 # load nations to stash
 $s->{nats} = 
  $dbc->selectall_hashref ( 'select nat as nat from mnat', 'nat' );
  
 $dbc->disconnect;
 
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
  $_[0], text('en') );
   
}
 
__DATA__
% my ( $s, $t ) = @_;
<!doctype html><html>
<head><title><%= $t->{SITE} %> checker</title></head>
<hr>
<body><h1><%= $t->{SITE} %> checker</h1>
<div>
started <%= $s->{started_en} %><br>
finished <%= $s->{ended_en} %><br>
<%= $s->{took}->[0] %> <%= $t->{DAYS} %>
<%= $s->{took}->[1] %> <%= $t->{HOURS} %>
<%= $s->{took}->[2] %> <%= $t->{MINUTES} %>
<%= $s->{took}->[3] %> <%= $t->{SECONDS} %><br>
total <%= scalar @{ $s->{bers} } %> breeders
</div>
% foreach my $st ( @{ $s->{status} } ) {
<hr width="100%">
<h2><%= $s->{strings}->{$st} %></h2>
<table>
%  foreach my $b ( @{ $s->{bers} } ) {
%   if ( $s->{breeders}->{$b}->{status} eq $st ) {
<tr><td align="right"><%= $b %></td> 
%    if ( $s->{breeders}->{$b}->{url} ) {
<td align="left"><a target="_blank" href="<%= $s->{breeders}->{$b}->{url} %>">
<%= $s->{breeders}->{$b}->{url} %></a></td>
%    } else {
<td>&nbsp;</td>
%    }
<tr>
%   }
%  }
</table>
% } 
<hr width="100%">
</body>
</html>