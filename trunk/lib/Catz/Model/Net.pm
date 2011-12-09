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

package Catz::Model::Net;

use 5.12.0;
use strict;
use warnings;

use parent 'Catz::Model::Base';

use LWP::UserAgent;

use Catz::Data::Conf;
use Catz::Data::Text;
use Catz::Data::Result;

use Catz::Util::String qw ( enurl );

my $url_count = conf ( 'result_url_count' );
my $url_data  = conf ( 'result_url_data' );

my $key_date = conf ( 'result_param_date' );
my $key_loc  = conf ( 'result_param_loc' );
my $key_name = conf ( 'result_param_name' );

my $agent =
 text ( 'en' )->{ SITE } . ' ' . __PACKAGE__ . ' LWP::UserAgent Perl5';

my $ua = LWP::UserAgent->new (
 agent        => $agent,
 timeout      => 10,
 max_redirect => 5
);

sub body {

 my ( $self, $url ) = @_;

 my $res = $ua->get ( $url );

 $res->is_success and return $res->content;

 return undef;

}

sub urlc {

 my ( $head, $date, $loc ) = @_;

 $head . '?'
  . $key_date . '='
  . enurl ( $date ) . '&'
  . $key_loc . '='
  . enurl ( $loc );
}

sub urld {

 my ( $head, $date, $loc, $name ) = @_;

 $head . '?'
  . $key_date . '='
  . enurl ( $date ) . '&'
  . $key_loc . '='
  . enurl ( $loc ) . '&'
  . $key_name . '='
  . enurl ( $name );

}

sub _data {

 my ( $self, $date, $loc, $name, $pseudo ) =
  @_;    # pseudo parameter is not used

 my $url = urld ( $url_data, $date, $loc, $name );

 my $res = $self->body ( $url );

 $res
  and ( length ( $res ) > 3 )
  and return ( result_process ( $res ) );

 return undef;

}

sub _count {

 my ( $self, $date, $loc, $pseudo ) = @_;    # pseudo parameter is not used

 my $url = urlc ( $url_count, $date, $loc );

 my $res = $self->body ( $url );

 $res and length ( $res ) > 0 and return int ( $res );

 return undef;

}

sub _get {

 my ( $self, $url ) = @_;

 $self->body ( $url );

}

1;
