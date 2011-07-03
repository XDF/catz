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

use 5.10.0; use strict; use warnings;

use parent 'Catz::Core::Ctrl';

use I18N::AcceptLanguage;

use Catz::Core::Conf;
use Catz::Data::Result;
use Catz::Data::Setup;
use Catz::Data::Style;
use Catz::Util::Number qw ( fmt round );
use Catz::Util::Time qw ( dt );

my $langs = [ 'en', 'fi' ];
 
my $i18n = 
 I18N::AcceptLanguage->new( defaultLangauge => 'en', strict => 0 );

# the language detection based on the request headers
sub detect { 
 
 my $self = shift;
 
 $self->redirect_temp( 
  '/'.
  $i18n->accepts( $self->req->headers->accept_language, $langs )
  .'/'
 );

}

sub front {

 my $self = shift; my $s = $self->{stash};
 
 $s->{urlother} = '/' . $s->{langaother} . '/';
 
 $s->{mapview} = $self->fetch ( 'map#view' );
 $s->{mapdual} = $self->fetch ( 'map#dual' );
 
 $s->{news} = $self->fetch ( 'news#latest', 8 );
 
 $s->{folders} = $self->fetch ( 'locate#folder', 8 );
 
 $s->{pris} =  $self->fetch ( 'locate#pris' ); 

 $s->{maxx} = $self->fetch ( 'all#maxx' );
 
 my $samp = $self->fetch ( 'all#array_rand_n', 45 );
 
 my $th = $self->fetch ( 'photo#thumb', @{ $samp } );

 $s->{thumbs} = $th->[0];
 
 $s->{texts} = $self->fetch ( 'photo#texts', @{ $samp } );
 
 # overriding the user's setting for the front page
 $s->{thumbsize} = 100; # 100px
     
 $self->render( template => 'page/front' );
 
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
 $s->{langa} ne $s->{lang} and ( $self->not_found and return );

 my $key = $self->param( 'key' ) // undef;

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
 my $pseudo = substr ( dt, 0, -3 );
 # combined to the bypassed page cache and max-age 9 minutes it is
 # 19 minutes and so it can be said that results are no older than 20
 # minutes
  
 my $count = $self->fetch ( 'net#count', $keys[0], $keys[1], $pseudo ) // 0;
  
 $count == 0 and 
  $self->render( text => RESULT_NA ) and return;

 my $res = $self->fetch ( 'net#data', @keys, $pseudo );
 
 defined $res and do {
 
  $s->{result} = $res->[0];
  $s->{attrib} = $res->[1];
 
  $self->render( template => 'elem/result' ) and return;
 
 };
 
 $self->render( text => RESULT_NA );
 
}

sub lastshow {

 my $self = shift; my $s = $self->{stash};
 
 my $cont = $self->fetch ( 'locate#lastshow' );
 
 $s->{list} = $cont;
 
 $s->{site} = conf ( 'url_site' );
 
 $self->render( template => 'block/lastshow', format => 'txt' );
 
}

sub verify {

 my $self = shift; my $s = $self->{stash};
 
 $s->{auth} eq conf ( 'key_tools' ) or ( $self->not_found and return );

 my $out = $self->fetch ( 'tool#verify' );   
  
 $self->render( text => $out, format => 'txt' );

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
 $s->{langa} ne $s->{lang} and ( $self->not_found and return );

 if ( $s->{cont} eq 'std' ) { $base = $s->{t}->{MAILTO_TEXT} }
   
  else { $self->not_found and return }
  
  # the 0th element
  my $out = $cset->[ rand @{ $cset } ];
    
  foreach my $key ( split //, $base ) {
 
   do { $out .= $cset->[ rand @{ $cset } ] } foreach ( 1 .. 6 );
     
   $out .= $key;
    
  }
 
 $self->render_text ( text => $out, format => 'txt' ); 
 
}

1;