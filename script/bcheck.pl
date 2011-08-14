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
use Mojo::UserAgent;

use Catz::Core::Conf;
use Catz::Core::Text;

use Catz::Util::File qw ( findlatest );
use Catz::Util::Log qw ( logadd logclose logopen logit );
use Catz::Util::Time qw ( dtlang );

$| = 1; # unbuffered printing

logopen ( "../log/bcheck.log" );

logit "----- catza.net bcheck verifier started at " . dtlang ( 'en' );

my $net = Mojo::UserAgent->new;

$net->log ( undef );

$net->name( text('en')->{SITE} . ' Perl Mojo::UserAgent' );
 
$net->keep_alive_timeout( 0 );
$net->max_connections( 1 );
$net->max_redirects( 5 );

my $dbfile = findlatest ( '../db', 'db' );

my $dbc = DBI->connect( 
 'dbi:SQLite:dbname=' . $dbfile , undef, undef, 
 { AutoCommit => 0, RaiseError => 1, PrintError => 1 } 
)  or die "unable to connect to database $dbfile: $DBI::errstr";

my $res = $dbc->selectall_arrayref ( 'select breeder,url from mbreeder where url is not null order by random() limit 30' );

$dbc->disconnect;

my @ok = ();
my @notfound = ();
my @strange = ();
my @connect = ();
my @short = ();

logadd '----- verifying ' . scalar ( @$res ) . ' breeder urls ';

foreach my $row ( @$res ) {

 my $breeder = shift @$row;
 my $url = shift @$row;

 my $re = $net->get($url)->res;

 my $body = $re->body // undef;
 my $code = $re->code // undef ;

 if ( $code ) {

  if ( $code eq 404 ) {

   push @notfound, "$breeder $url";

  } elsif ( $code ne 200 ) {

   push @strange, "$breeder $url";

  } elsif ( length $body < 50 ) {

   push @short, "$breeder $url";

  } else {

   push @ok, "$breeder $url";

  }

 } else {

  push @connect, "$breeder $url";

 }


 logadd '.';

}

logit '';

logit '----- 200 OK WITH CONTENT';
logit join "\n", @ok;

logit "----- CONNECT FAILED";
logit join "\n", @connect;

logit "----- 404 NOT FOUND";
logit join "\n", @notfound;

logit "----- STRANGE CODE";
logit join "\n", @strange;

logit "----- CONTENT TOO SHORT";
logit join "\n", @short;

logit "----- catza.net bcheck verifier finished at " . dtlang ( 'en' );

logclose;
