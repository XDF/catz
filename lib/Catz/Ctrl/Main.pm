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

package Catz::Ctrl::Main;

use 5.12.0; use strict; use warnings;

use parent 'Catz::Ctrl::Base';

use I18N::AcceptLanguage;

use Catz::Data::Conf;
use Catz::Data::Result;
use Catz::Data::Search;
use Catz::Data::Setup;
use Catz::Data::Style;

use Catz::Util::Number qw ( fmt round );

my $langs = [ 'en', 'fi' ];
 
my $i18n = 
 I18N::AcceptLanguage->new( defaultLangauge => 'en', strict => 0 );

sub detect { # the language detection based on the request headers 
 
 my $self = shift;

 # it was noted with some wget tests that the target appeared to be unset
 # so we now set 'en' if undef is returned 
 my $target = $i18n->accepts ( 
  $self->req->headers->accept_language, $langs 
 ) // 'en';
 
 $self->visitat ( "/$target/" );

}

sub front {

 my $self = shift; my $s = $self->{stash};
  
 $s->{urlother} = "/$s->{langaother}/";
 
 $s->{seal} = conf ( 'key_seal' );
  
 $self->f_map or return $self->fail ( 'f_map exit' );
 
 # load the latest ...
 
 $s->{news} = $self->fetch ( 'news#latest', 8 ); # ... news
 
 $s->{folders} = $self->fetch ( 'locate#folder', 8 ); # ... albums

 $s->{pris} =  $self->fetch ( 'locate#pris' ); 

 $s->{maxx} = $self->fetch ( 'all#maxx' );
 
 my $samp = $self->fetch ( 'all#array_rand_n', 40 );
 
 my $th = $self->fetch ( 'photo#thumb', @{ $samp } );

 $s->{thumbs} = $th->[0];

 $s->{texts} = $self->fetch ( 'photo#texts', @{ $samp } );
 
  # overriding the user's setting for the front page
 $s->{thumbsize} = 100; # 100px
 
 # load style for globe viz img tag height and width 
 $s->{style} = style_get ( $s->{palette} );
     
 $self->render( template => 'page/front', format => 'html' );
 
}

sub reset { $_[0]->render ( template => 'style/reset', format => 'css' ) }

sub base {

 my $self = shift; my $s = $self->{stash};
  
 $s->{st} = style_get; # copy style hashref to stash for stylesheet processing
  
 $self->render ( template => 'style/base', format => 'css' );

}

use constant RESULT_NA => '<!-- N/A -->';

sub result {

 my $self = shift; my $s = $self->{stash};
 
 # result available only without setup
 length $s->{langa} > 2 and return $self->fail ( 'setup set so stopped' );

 my $key = $self->param( 'x' ) // undef;

 (
   defined $key and length $key < 2000 
   and $key =~ /^CATZ\-([A-Z2-7]+)\-([0-9A-F]{32,32})$/ 
 ) or $self->render( text => RESULT_NA ) and return;

 my @keys = result_unpack ( $key );
   
 scalar @keys == 3 or 
  $self->render( text => RESULT_NA ) and return;
 
 # this is a pseudo parameter passed to the model that contains the
 # current dt down to 10 minutes, so this parameter changes in every
 # 10 minutes and this makes cached model data live at most 10 minutes
 my $pseudo = substr ( $self->dt, 0, -3 );
  
 my $count = $self->fetch ( 'net#count', $keys[0], $keys[1], $pseudo ) // 0;
  
 $count == 0 and 
  $self->render( text => RESULT_NA ) and return;

 my $res = $self->fetch ( 'net#data', @keys, $pseudo );
 
 defined $res and do {
  
  $s->{result} = $res->[0];
  $s->{attrib} = $res->[1];
 
  return $self->output ( 'elem/result' );
 
 };
 
 $self->render( text => RESULT_NA );
 
}

my $cset = [ (
 ( 0 .. 9 ),
 ( 'a' .. 'z' ),
 ( 'Z' .. 'Z' ),
 qw ( ! @ $ % & ? . ; : - _ ),
 ' '
) ];

sub info {

 my $self = shift; my $s = $self->{stash}; my $base = undef;
 
 # info available only without setup
 length $s->{langa} > 2 and return $self->fail ( 'setup set so stopped' );

 if ( $s->{cont} eq 'std' ) { $base = $s->{t}->{MAILTO_TEXT} }
   
  else { return $self->fail ( 'unsupported mode requested' ) }
  
  # the 0th element
  my $out = $cset->[ rand @{ $cset } ];
    
  foreach my $key ( split //, $base ) {
 
   do { $out .= $cset->[ rand @{ $cset } ] } foreach ( 1 .. 6 );
     
   $out .= $key;
    
  }
 
 $self->render_text ( text => $out, format => 'txt' ); 
 
}

1;