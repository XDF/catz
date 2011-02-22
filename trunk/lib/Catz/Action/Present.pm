#
# The MIT License
# 
# Copyright (c) 2010-2011 Heikki Siltala
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

package Catz::Action::Present;

use strict;
use warnings;

use parent 'Catz::Action::Base';

use Catz::DB;
use Catz::Model::Meta;
use Catz::Model::Vector;
use Catz::Util qw ( pik2pid );

sub browse {

 my $self = shift;
 
 my $stash = $self->{stash};
   
 my ( $lower, $upper ) = split /\-/, $stash->{range};
 
 # verify the range
 ( ( $lower > 0 ) and ( $upper < meta_maxx + 1 ) and ( ( $lower + 9 ) <= $upper ) and
  ( ( $upper - $lower ) <= 49 ) and ( ( $lower - 1 ) % 5 == 0 ) and ( $upper % 5 == 0 ) )
  or $self->render(status => 404);
 
 my @args = ();
  
 # split arguments into an array, filter out empty arguments
 # if path is not defined then browsing all photos and skip processing
 $stash->{path} and ( @args = grep { defined $_ } split /\//, $stash->{path} );
 
 # store the new argument array back to stash
 $stash->{args_string} = join '/', @args;
 $stash->{args_array} = \@args;
 $stash->{args_count} = scalar @args;
  
 # arguments must come in as pairs
 scalar @args % 2 == 0 or $self->render(status => 404);  
    
 # set this amount of photos to both stash and session
 # so session gets changed automatically by url 
 my $perpage = $upper - $lower + 1;
 $stash->{thumbsperpage} = $perpage; 
 $self->session( thumbsperpage => $perpage );
 
 my ( $total, $page, $pages, $from, $to, $first, $prev, $next, $last, $xs ) = 
  @{ vector_pager( $lower, $upper, $perpage, $stash->{lang}, @args ) };
     
 $total == 0 and $self->render(status => 404); # no photos found by search 
 scalar @{ $xs } == 0 and $self->render(status => 404); # no photos in this page
  
 $stash->{total} = $total;
 $stash->{page} = $page;
 $stash->{pages} = $pages;
 $stash->{perpage} = $perpage;
 $stash->{from} = $from;
 $stash->{to} = $to;
 $stash->{first} = $first;
 $stash->{prev} = $prev;
 $stash->{next} = $next;
 $stash->{last} = $last;
 #$stash->{thumbsize} = $self->session('thumbsize');

 my $thumbs = db_all( "select flesh.fid,album,file||'_LR.JPG',width_lr,height_lr from photo natural join flesh natural join _fid_x where x in (" 
  . ( join ',', @$xs ) .  ') order by x' );

  
 #use Data::Dumper; die Dumper( $thumbs );
     
 $self->{stash}->{thumbs} = $thumbs;
     
 $self->render( template => 'page/browse' );
    
}

sub view {

 my $self = shift;
  
 my $stash = $self->{stash};

 #warn "fik: $stash->{photo}";  

 $stash->{photo} = pik2pid ( $stash->{photo} );
 
 #warn "fid: $stash->{photo}";  
 
 my @args = ();
  
 # split arguments into an array, filter out empty arguments
 # if path is not defined then browsing all photos and skip processing
 $stash->{path} and ( @args = grep { defined $_ } split /\//, $stash->{path} );
 
 # store the new argument array back to stash
 $stash->{args_string} = join '/', @args;
 $stash->{args_array} = \@args;
 $stash->{args_count} = scalar @args;
 
 # arguments must come in as pairs
 # scalar @args % 2 == 0 or $self->render(status => 404);
  
 my $perpage =  $self->session('thumbsperpage');
  
 my ( $total, $pos, $x, $page, $first, $prev, $next, $last ) = @{ vector_pointer( 
  $stash->{photo}, $perpage, $stash->{lang}, split /\//, $stash->{args} 
 ) };

 #warn "x: $x";
 
 my $details = db_all ( qq{select pri,sec_$self->{stash}->{lang} from _class_pri_sec_x where x=? order by class,pri,sec_$self->{stash}->{lang}}, $x );

 my $texts = db_col ( qq{select sec_$self->{stash}->{lang} from _class_pri_sec_x where x=? and pri='cat'}, $x );

 my $image = db_row ( 'select folder,file_hr,width_hr,height_hr from _x_photo where x=?',$x);
  
 $self->{stash}->{total} = $total;
 $self->{stash}->{pos} = $pos;
 $self->{stash}->{page} = $page;
 $self->{stash}->{perpage} = $perpage;
 $self->{stash}->{first} = $first;
 $self->{stash}->{prev} = $prev;
 $self->{stash}->{next} = $next;
 $self->{stash}->{last} = $last;
 
 $self->{stash}->{texts} = $texts;
 $self->{stash}->{details} = $details;
 $self->{stash}->{image} = $image;
     
 $self->render( template => 'page/view' );

}

1;

