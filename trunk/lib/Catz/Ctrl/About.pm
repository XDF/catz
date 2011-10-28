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

package Catz::Ctrl::About;

use 5.12.0; use strict; use warnings;

use parent 'Catz::Ctrl::Base';

use I18N::AcceptLanguage;

use Catz::Data::Conf;
use Catz::Data::Result;
use Catz::Data::Search;
use Catz::Data::Setup;
use Catz::Data::Style;

use Catz::Util::Number qw ( fmt round );
use Catz::Util::Time qw ( dt );

sub about { 

 my $self = shift; my $s = $self->{stash};
  
 $s->{urlother} = $self->fuse ( $s->{langaother}, 'about', $s->{topic} );
 
 if ( $s->{topic} eq 'contrib' ) {
 
  $s->{breeds} = $self->fetch ( 'related#breeds' );
  
  foreach my $breed ( @{ $s->{breeds} } ) {
  
   $s->{'url_breed_'.$breed} = join '/', 
    ( '', $s->{langa}, 'search?q='. $self->enurl ( 
     "+breed=$breed -has=cat" 
    ) );
    
  }

  $s->{cates} = $self->fetch ( 'related#cates' );
  
  foreach my $cate( @{ $s->{cates} } ) {
  
   $s->{'url_cate_'.$cate->[0]} = join '/', 
    ( '', $s->{langa}, 'search?q='. $self->enurl ( 
     "+cate=$cate->[0] -has=cat" 
    ) );
    
  }
   
  $s->{count_total} = $self->fetch ( 'all#maxx' );
  
  $s->{search_none} = '-has=text';  
  $s->{search_breed} = '+has=breed -has=cat';
  
  foreach my $key ( qw ( none breed ) ) {
  
   $s->{'url_'.$key} = join '/', 
    ( '', $s->{langa}, 'search?q='. $self->enurl ( $s->{'search_'.$key} ) );
  
   $s->{'count_'.$key} = 
    $self->fetch ( "search#count", @{ search2args $s->{'search_'.$key} } );
   
   $s->{'perc_'.$key} = 
    ( ( $s->{'count_'.$key} / $s->{count_total} ) * 100 );
  
  }  
  
 }
   
 $self->render( template => 'page/about', format => 'html' );

}

1;