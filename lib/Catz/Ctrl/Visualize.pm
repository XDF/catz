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

use Catz::Util::String qw ( enurl limit );

sub pre_pair {

 my $self = shift; my $s = $self->{stash};

 $self->fetch('pair#verify',$s->{pri}) or return 0;
 
 $s->{sec} = $self->decode ( $s->{sec} ); # using decode helper
 
 $s->{total} = $self->fetch('pair#count',$s->{pri},$s->{sec});
 
 $s->{total} > 0 or return 0;
 
 return 1;

}

sub pre_ddist {

 my $self = shift; my $s = $self->{stash};

 $s->{style} = style_get ( $s->{palette} ); 

 $s->{charturl} = conf ( 'url_chart' );
 
 $s->{width} = 180; $s->{height} = 220; # these must match to img tag

}

sub post_ddist {

 my $self = shift;

 my $vurl = $self->render ( 'viz/ddist', format => 'txt', partial => 1 );
  
 return $self->redirect_perm ( $vurl );

}

sub ddist_pair {

 my $self = shift; my $s = $self->{stash};

 $self->pre_pair or return $self->not_found;
 
 $self->pre_ddist;

 my @extra = qw ( -has text );

 $s->{cover_notext} = 
  $self->fetch ( "search#count", "+$s->{pri}", $s->{sec}, @extra );
   
 @extra = qw ( +has breed -has cat );

 $s->{cover_nocat} = 
   $self->fetch ( "search#count", "+$s->{pri}", $s->{sec}, @extra );

 return $self->post_ddist;
       
}

sub ddist_all {

 my $self = shift; my $s = $self->{stash};

 $s->{total} = $self->fetch('all#count');
  
 $self->pre_ddist;
 
 $s->{cover_notext} = 
  $self->fetch ( "search#count", qw ( -has text ) );
   
 $s->{cover_nocat} = 
  $self->fetch ( "search#count", qw ( +has breed -has cat ) );
     
 return $self->post_ddist;

}

sub rank_pair {

 my $self = shift; my $s = $self->{stash};

 $self->pre_pair or return $self->not_found;
 
 $s->{style} = style_get ( $s->{palette} ); 

 $s->{charturl} = conf ( 'url_chart' );
 
 $s->{width} = 200; $s->{height} = 200; # these must match to img tag

 my $ranks = $self->fetch ( "related#ranks", $s->{pri}, $s->{sec} );
 
 $s->{rank} = shift @$ranks;
 
 $s->{ranks} = $ranks;
 
 my $vurl = $self->render ( 'viz/rank', format => 'txt', partial => 1 );
  
 return $self->redirect_perm ( $vurl );
 
}

sub cover {

 my $self = shift; my $s = $self->{stash};
 
 $s->{maxx} = $self->fetch ( 'all#maxx' );

 $s->{total} > $s->{maxx} and return $self->not_found;
 
 $s->{style} = style_get ( $s->{palette} ); 

 $s->{charturl} = conf ( 'url_chart' );
 
 $s->{width} = 180; $s->{height} = 220; # these must match to img tag
 
 my $vurl = $self->render ( 'viz/cover', format => 'txt', partial => 1 );
  
 return $self->redirect_perm ( $vurl ); 

}

1;

