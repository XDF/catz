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

package Catz::Ctrl::More;

use 5.12.0; use strict; use warnings;

use parent 'Catz::Ctrl::Base';

use I18N::AcceptLanguage;

use Catz::Data::Conf;
use Catz::Data::Search;
use Catz::Data::Style;

sub contrib { 

 my $self = shift; my $s = $self->{stash};
 
 $s->{topic} = 'contrib';
 
 $self->f_init or return $self->fail ( 'f_init exit' );
 
 $self->f_dist or return $self->fail ( 'dist exit' );
 
 $s->{style} = style_get;
   
 $s->{breeds} = $self->fetch ( 'related#breeds' );
 
 foreach my $breed ( @{ $s->{breeds} } ) {
 
  $s->{'dist_url_'.$breed} = $self->fuseq ( 
   $s->{langa}, ( 'search?q=' . $self->enurl ( 
    args2search (  
     @{ $s->{dist}->{blocks}->{tailer} },
     '+breed', $breed 
    ) ) ) );
 
 }
  
 $s->{cates} = $self->fetch ( 'related#cates' );

 foreach my $cate ( @{ $s->{cates} } ) {
 
  $s->{'dist_url_'.$cate->[0]} = $self->fuseq ( 
   $s->{langa}, ( 'search?q=' . $self->enurl ( 
    args2search ( 
     @{ $s->{dist}->{blocks}->{tailer} }, 
    '+cate', $cate->[0] 
   ) ) ) );
 
 }
     
 $self->common;

}

sub quality {

 my $self = shift; my $s = $self->{stash};
 
 # reject, added temporarily 2011-11-25
 return $self->fail ( 'quality reports temporarily disabled' );
 
 $s->{topic} = 'quality';
 
 $self->f_init or return $self->fail ( 'f_init exit' );
 
 foreach my $item ( qw ( dt detail ) ) {
 
  $s->{ "qa$item" } = $self->fetch ( "bulk#qa$item" );
 
 }
 
 $self->common;

}

sub common {

 my $self = shift; my $s = $self->{stash};

 $s->{urlother} = $self->fuse ( 
  $s->{langaother}, 'more', $s->{topic} 
 );
 
 $self->render( template => 'page/more', format => 'html' );

}

1;