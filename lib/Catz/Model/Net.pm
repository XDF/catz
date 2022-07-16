#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2022 Heikki Siltala
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

use 5.14.2;
use strict;
use warnings;

use parent 'Catz::Model::Base';

use Const::Fast;
use LWP::UserAgent;

use Catz::Data::Conf;
use Catz::Data::Text;
use Catz::Data::Result;

use Catz::Util::String qw ( enurl );

const my $URL_COUNT => conf ( 'result_url_count' );
const my $URL_DATA  => conf ( 'result_url_data' );
const my $KEY_DATE  => conf ( 'result_param_date' );
const my $KEY_LOC   => conf ( 'result_param_loc' );
const my $KEY_NAME  => conf ( 'result_param_name' );

const my $AGENT => text ( 'en' )->{ SITE } . ' '
 . __PACKAGE__
 . ' LWP::UserAgent Perl5';

my $ua = LWP::UserAgent->new (
 agent        => $AGENT,
 timeout      => 10,
 max_redirect => 5
);

sub body {

 my ( $self, $url ) = @_;

 my $res = $ua->get ( $url );

 $res->is_success and return $res->content;

 return undef;    ## no critic

}

sub urlc {

 my ( $head, $date, $loc ) = @_;

 $head . '?'
  . $KEY_DATE . '='
  . enurl ( $date ) . '&'
  . $KEY_LOC . '='
  . enurl ( $loc );
}

sub urld {

 my ( $head, $date, $loc, $name ) = @_;

 $head . '?'
  . $KEY_DATE . '='
  . enurl ( $date ) . '&'
  . $KEY_LOC . '='
  . enurl ( $loc ) . '&'
  . $KEY_NAME . '='
  . enurl ( $name );

}

sub _data {

 # pseudo parameter is not used
 my ( $self, $date, $loc, $name, $pseudo ) = @_;
 
 # 16.7.2022 no longer used
 return undef;

 my $url = urld ( $URL_DATA, $date, $loc, $name );

 my $res = $self->body ( $url );

 $res
  and ( length ( $res ) > 3 )
  and return ( result_process ( $res ) );

 return undef;    ## no critic

}

sub _count {

 # pseudo parameter is not used
 my ( $self, $date, $loc, $pseudo ) = @_;
 
 # 16.7.2022 no longer used
 return undef;

 my $url = urlc ( $URL_COUNT, $date, $loc );

 my $res = $self->body ( $url );

 $res and length ( $res ) > 0 and return int ( $res );

 return undef;    ## no critic

}

sub _get {

 my ( $self, $url ) = @_;

 $self->body ( $url );

}

1;
