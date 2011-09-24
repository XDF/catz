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

use Catz::Data::Setup;
use Catz::Data::Style;

use Catz::Util::Number qw ( fmt round );
use Catz::Util::Time qw ( dt );

my $langs = [ 'en', 'fi' ];
 
my $i18n = 
 I18N::AcceptLanguage->new( defaultLangauge => 'en', strict => 0 );

sub detect { # the language detection based on the request headers 
 
 my $self = shift;
 
 my $target = $i18n->accepts( $self->req->headers->accept_language, $langs );
 
 # it was noted with some wget tests that the target can be unset
 # so we must check it and default to English if needed 
 ( $target and length ( $target ) > 1 ) or $target = 'en'; 
 
 $self->redirect_temp ( "/$target/" );

}

sub front {

 my $self = shift; my $s = $self->{stash};
 
 $s->{urlother} = '/' . $s->{langaother} . '/';
 
 $s->{mapview} = $self->fetch ( 'map#view' );
 $s->{mapdual} = $self->fetch ( 'map#dual' );
 
 $s->{seal_id} = conf ( 'seal_id' );
 
 $s->{news} = $self->fetch ( 'news#latest', 8 );
 
 $s->{folders} = $self->fetch ( 'locate#folder', 8 );
 
 $s->{pris} =  $self->fetch ( 'locate#pris' ); 

 $s->{maxx} = $self->fetch ( 'all#maxx' );
 
 my $samp = $self->fetch ( 'all#array_rand_n', 40 );
 
 my $th = $self->fetch ( 'photo#thumb', @{ $samp } );

 $s->{thumbs} = $th->[0];

 $s->{texts} = $self->fetch ( 'photo#texts', @{ $samp } );
 
 # overriding the user's setting for the front page
 $s->{thumbsize} = 100; # 100px

 # load style for globe img tag height and width 
 $s->{style} = style_get ( $s->{palette} );
     
 $self->render( template => 'page/front' );
 
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