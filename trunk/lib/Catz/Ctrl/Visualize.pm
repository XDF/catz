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

package Catz::Ctrl::Visualize;

use 5.10.0; use strict; use warnings;

use parent 'Catz::Core::Ctrl';

use Catz::Core::Conf;

use Catz::Data::Style;


sub do {

 my $self = shift; my $s = $self->{stash};

 $s->{style} = style_get ( $s->{palette} ); 

 $s->{charturl} = conf ( 'url_chart' );

 my $vurl = $self->render ( 
  "viz/$s->{action}", format => 'txt', partial => 1 
 );
  
 return $self->redirect_perm ( $vurl ); 
 
}

sub dist {

 my $self = shift; my $s = $self->{stash};
 
 $s->{total} = $s->{full} + $s->{breed} + $s->{none};

 $s->{maxx} = $self->fetch ( 'all#maxx' );
 
 # the total number of photos must be less or equal to all photos
 $s->{total} <= $s->{maxx} or return $self->render_not_found;
 
 return $self->do;
 
}

sub globe {

 my $self = shift; my $s = $self->{stash};
 
 $s->{nats} = $self->fetch ( 'related#nats' );
 
 return $self->do;

}

sub rank {

 my $self = shift; my $s = $self->{stash};

 $self->fetch( 'pair#verify',$s->{pri} ) or return $self->render_not_found;
 
 $s->{sec} = $self->decode ( $s->{sec} ); # using decode helper
 
 $s->{total} = $self->fetch ( 'pair#count', $s->{pri}, $s->{sec} );

 $s->{total} > 0 or return $self->render_not_found;
 
 $s->{rank} = $self->fetch ( 'related#rank', $s->{pri}, $s->{sec} );
 
 $s->{ranks} = $self->fetch ( 'related#ranks', $s->{pri} );
  
 return $self->do;
 
}

1;

