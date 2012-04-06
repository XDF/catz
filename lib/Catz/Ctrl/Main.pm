#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2012 Heikki Siltala
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

package Catz::Ctrl::Main;

use 5.14.2;
use strict;
use warnings;

use parent 'Catz::Ctrl::Base';

use Const::Fast;
use I18N::AcceptLanguage;

use Catz::Data::Conf;
use Catz::Data::Result;
use Catz::Data::Search;
use Catz::Data::Setup;
use Catz::Data::Style;

use Catz::Util::String qw ( acceptlang );

sub detect {    # the language detection based on the request headers

 my $self = shift;

 my $target = acceptlang ( $self->req->headers->accept_language );

 $self->visitat ( "/$target/" );

}

sub front {

 my $self = shift;
 my $s    = $self->{ stash };

 $s->{ urlother } = "/$s->{langaother}/";

 $self->f_map or return $self->fail ( 'f_map exit' );

 # load the latest ...

 $s->{ news } = $self->fetch ( 'news#latest', 8 );    # ... news

 $s->{ folders } = $self->fetch ( 'locate#folder', 8 );    # ... albums

 $s->{ pris } = $self->fetch ( 'locate#pris' );

 $s->{ maxx } = $self->fetch ( 'all#maxx' );

 # load style for globe viz img tag height and width
 $s->{ style } = style_get ( $s->{ palette } );

 $self->output ( 'page/front' );

} ## end sub front

sub reset { $_[ 0 ]->render ( template => 'style/reset', format => 'css' ) }

sub base {

 my $self = shift;
 my $s    = $self->{ stash };

 $s->{ st } =
  style_get;    # copy style hashref to stash for stylesheet processing

 $self->render ( template => 'style/base', format => 'css' );

}

const my $RESULT_NA => '<!-- N/A -->';

sub result {

 my $self = shift;
 my $s    = $self->{ stash };

 # result available only without setup
 length $s->{ langa } > 2 and return $self->fail ( 'setup set so stopped' );

 my $key = $self->param ( 'x' ) // undef;

 (    defined $key
   and length $key < 2000
   and $key =~ /^CATZ\_([A-Za-z0-9\-]+)\_([0-9A-F]{32,32})$/ )
   or return $self->render ( text => $RESULT_NA );

 my @keys = result_unpack ( $key );

 scalar @keys == 3
  or $self->render ( text => $RESULT_NA )
  and return;

 # this is a pseudo parameter passed to the model that contains the
 # current dt down to 10 minutes, so this parameter changes in every
 # 10 minutes and this makes cached model data live at most 10 minutes
 my $pseudo = substr ( $self->dt, 0, -3 );

 my $count = $self->fetch ( 'net#count', $keys[ 0 ], $keys[ 1 ], $pseudo )
  // 0;

 $count == 0
  and $self->render ( text => $RESULT_NA )
  and return;

 my $res = $self->fetch ( 'net#data', @keys, $pseudo );

 defined $res and do {

  $s->{ result } = $res->[ 0 ];
  $s->{ attrib } = $res->[ 1 ];

  return $self->output ( 'elem/result' );

 };

 $self->render ( text => $RESULT_NA );

} ## end sub result

const my @CSET => (
 (
  ( 0 .. 9 ),
  ( 'a' .. 'z' ),
  ( 'Z' .. 'Z' ),
  qw ( ! @ $ % & ? . ; : - _ ), ' '
 )
);

sub info {

 my $self = shift;
 my $s    = $self->{ stash };
 my $base = undef;

 # info available only without setup
 length $s->{ langa } > 2 and return $self->fail ( 'setup set so stopped' );

 if ( $s->{ cont } eq 'std' ) { $base = $s->{ t }->{ MAILTO_TEXT } }

 else { return $self->fail ( 'unsupported mode requested' ) }

 # the 0th element
 my $out = $CSET[ rand @CSET ];

 foreach my $key ( split //, $base ) {

  do { $out .= $CSET[ rand @CSET ] }
   foreach ( 1 .. 6 );

  $out .= $key;

 }

 $self->render_text ( text => $out, format => 'txt' );

} ## end sub info


const my $N => 100;

sub sample {

 my $self = shift;
 my $s    = $self->{ stash };
 my $base = undef;

 # samples are available also with setup in order to generate
 # correct links to viewall pages

 $s->{ width } < 200 and return $self->fail ( 'width too small' );

 $s->{ width } > 2000 and return $self->fail ( 'width too large' );

 ( $s->{ width } % 10 == 0 ) or return $self->fail ( 'width not tenths' );

 my $samp = $self->fetch ( 'all#array_rand_n', $N );

 # get thumbnails in random order
 my $th = $self->fetch ( 'photo#thumb', 'rand', @{ $samp } );

 $s->{ thumbs } = $th->[ 0 ];

 $s->{ texts } = $self->fetch ( 'photo#texts', @{ $samp } );

 # overriding the user's setting for the front page
 $s->{ thumbsize } = 100;    # 100px

 $self->output ( 'block/sample' );

} ## end sub sample

1;
