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

use 5.10.0;
use strict;
use warnings;

use parent 'Catz::Core::Ctrl';

use I18N::AcceptLanguage;

use Catz::Core::Conf;
use Catz::Data::List qw ( list_matrix );
use Catz::Data::Result;
use Catz::Data::Setup;
use Catz::Data::Style;
use Catz::Util::Number qw ( fmt round );

my $langs = [ 'en', 'fi' ];
 
my $acc = I18N::AcceptLanguage->new( defaultLangauge => 'en', strict => 0 );

sub detect {
  
 my $self = shift;
  
 my $lang = $acc->accepts(
  $self->req->headers->accept_language, $langs
 );
  
 $self->redirect_temp( "/$lang/" ); 
  
}

sub front {

 my $self = shift; my $s = $self->{stash};
 
 $s->{news} = $self->fetch ( 'news#latest', 8 );
 
 $s->{albums} = $self->fetch ( 'locate#album' );
 
 $s->{pris} =  $self->fetch ( 'locate#pris' ); 

 $s->{maxx} = $self->fetch ( 'common#maxx' );
  
 $s->{matrix} = list_matrix;
    
 $self->render( template => 'page/front' );
 
}

sub reset { $_[0]->render ( template => 'style/reset', format => 'css' ) }

sub base {

 my $self = shift; my $s = $self->{stash};

 setup_verify ( 'palette', $s->{palette} ) or ( $self->not_found and return );
 
 $s->{st} = style_get; # copy style hashref to stash for stylesheet processing
  
 $self->render ( template => 'style/base', format => 'css' );

}

sub set {

 my $self = shift;

 my @params = $self->param;

 my $i = 0; # counts accepted parameters

 foreach my $key ( @params ) {

  # attempt to set the parameter, increase accepted counter if success 
  setup_set ( $self, $key, $self->param( $key ) ) and $i++;
 
 }
 
 # at least one set was done -> OK
 $i and $self->render( text => 'OK' ) and return;
  
 $self->render( text => 'FAILED' ); 
 
}

use constant RESULT_NA => '';

sub result {

 my $self = shift; my $s = $self->{stash};

 my $key = $self->param( 'key' ) // undef;

 ( defined $key and length $key < 2000 and $key =~ /^[A-Z2-7]+$/ ) or
  $self->render( text => RESULT_NA ) and return;

 my @keys = result_unpack ( $key );
  
 scalar @keys == 3 or $self->render( text => RESULT_NA ) and return;
 
 my $count = $self->fetch ( 'result#count', $keys[0], $keys[1] ) // 0;
 
 $count == 0 and $self->render( text => RESULT_NA ) and return;

 my $res = $self->fetch ( 'result#data', @keys );

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

1;