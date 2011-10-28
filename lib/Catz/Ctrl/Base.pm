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

package Catz::Ctrl::Base;

#
# the base class for all controllers in the system
# provides the core services required
#
# all controlles must inherit from this 
#

use 5.12.0; use strict; use warnings;

# all controllers are of course also Mojolicious controllers 
use parent 'Mojolicious::Controller';

use Catz::Data::Conf;
use Catz::Data::Dist;
use Catz::Data::Search;
use Catz::Data::Style;

use Catz::Util::File qw ( findfiles );

#
# loading of models
#

# when this module gets compiled all models get loaded, 
# instantiated and stores to a static hashref  

my $models = {}; # model instances are kept here

# define models to be skipped, like 
# abstract models that are not to be instantiated
my $noload = { Base => 1, Common => 1, Vector => 1 };

# if $noload is not up to date, the warnings like
# Subroutine db_run redefined at ...
# are printed when the system starts 

# disk path to models
my $mpath =  '../lib/Catz/Model';

# we seek the model directory
foreach my $mfile ( findfiles ( $mpath ) ) {

 # process the filename to a plain class name
 my $class = $mfile; $class =~ s|$mpath/||; $class =~ s|\.pm$||; 
  
 $noload->{$class} or do {
 
  require $mfile; # load

  # instantiate, use lower case name as key    
  $models->{ lc ( $class ) } = "Catz::Model::$class"->new;  
 
 }; 
 
}

sub fetch {

 # fetch data from any Model to any Controller 
 # expects model and sub as 'model#sub' and an argument list
 
 my ( $self, $target, @args ) = @_; my $s = $self->{stash};

 my ( $model, $sub ) = split /#/, $target;
 
 ( $model and $sub ) or die "illegal target '$target'";
 
 defined $models->{$model} or die "model '$model' is not bind";
  
 $models->{$model}->fetch( $s->{version}, $s->{lang}, $sub, @args );
   
}

sub goto {

 my ( $self, $code, $to ) = @_;
 
 # written after studying the Mojolicious core code
 
 $self->res->code ( $code );
 
 $self->res->headers->location ( $to );
 
 $self->res->headers->content_length ( 0 ); 
 
 $self->rendered;

 return $self;

}

sub visitat { $_[0]->goto ( 301, $_[1] ) } # permanent redirect 301 

sub moveto { $_[0]->goto ( 302, $_[1] ) } # temporary redirect 302

sub add_reason {

 my ( $self, @reason ) = @_; my $s = $self->{stash};
 
 # get subroutine and line number
 my $origin = ( caller(2) )[3] . '[' . ( caller(2) )[2] . ']';
 
 # init if needed
 defined $self->{stash}->{reason} or $self->{stash}->{reason} = [];
 
 push @{ $self->{stash}->{reason} }, $origin;
 
 my $tag = 'FAIL_' . ( shift @reason // 'PASSTHRU' );
 
 my $en = $s->{ten}->{ $tag } // ''; my $fi = $s->{tfi}->{ $tag } // '';
 
 my $ext = join ', ', map { "'$_'" } @reason;
 
 $ext and $ext .= " $ext";
 
 push @{ $self->{stash}->{reason} }, $en.$ext;
 push @{ $self->{stash}->{reason} }, $fi.$ext; 
 

}

sub fail { # the fail action for controllers

 my ( $self, @reason ) = @_;
 
 $self->add_reason ( @reason );

 my $origin = ( caller(2) )[3];
  
 # nth level call -> return to upper level with 0 = fail
 # 1st level call -> pass to mojolicious default action
 
 if ( $origin =~ /Catz::Ctrl/ ) { return 0 }
  else { return $self->render_not_found } 

} 

sub done { 1 } # the ok action for nth level controllers

sub output {

 my ( $self, $template, $format ) = @_;
 
 $self->render( template => $template, format => $format // 'html' );

}

#
# subs starting with f_ are functional subs = ment to add functionality
# that other controllers can use
#
# it is a simple way to collect them all to the base controller
# it is not an elegant way
#

sub f_init {

 # general initalization for controller actions

 my $self = shift; my $s = $self->{stash};
 
 foreach my $var ( qw ( 
  runmode origin what refines breedernat viz_rank trans nats maxx total dist
  cover_full cover_partial cover_cate cover_breed cover_none
  url_full url_partial url_cate url_breed url_none 
 ) ) { $s->{$var} = undef }
  
 defined $s->{pri} or $s->{pri} = undef;
 defined $s->{sec} or $s->{sec} = undef;
   
 $s->{args_array} = []; 
 $s->{args_count} = 0;
 
 $s->{maxx} = $self->fetch ( 'all#maxx' ); 
 
 return $self->done;
            
}
              
sub f_map { # load mappings

 my $self = shift; my $s = $self->{stash};
 
 $s->{action} eq 'find' and goto SKIP_TO_DUAL;

 ( $s->{maplink} = $self->fetch ( 'map#link' ) ) or 
  return $self->fail ( 'MAPP_LINK' );
 
 ( $s->{mapview} = $self->fetch ( 'map#view' ) ) or 
  return $self->fail ( 'MAPP_VIEW' );

 SKIP_TO_DUAL:
 
 ( $s->{mapdual} = $self->fetch ( 'map#dual' ) ) or 
  return $self->fail ( 'MAPP_DUAL' );
   
 return $self->done;
 
}

sub f_origin {

 #
 # the photo vector pointer x must be resolved 
 # in order to browse or view photos
 #
 # we resolve it from icnoming photo id or from the data  
 # 
 
 my $self = shift; my $s = $self->{stash};
 
 if ( $s->{id} ) { # the request has the photo id defined 

  $s->{origin} = 'id'; # mark that this request had an id
  
  # fetch the corresponding photo vector pointer x 
  $s->{x} = $self->fetch( $s->{runmode} . '#id2x', $s->{id} );
    
  $s->{x} or return $self->fail ( 'NODATA' );
          
 } else { 
 
  # no id was given in the request so we point to
  # the id of the first photo in the current set
 
  $s->{origin} = 'x'; # mark that we resolved the photo 
  
  # fetch the first photo vector pointer x in the current photo set
  $s->{x} = 
   $self->fetch ( $s->{runmode} . '#first', @{ $s->{args_array} } ) // undef;
  
  # if no first x was not found then it is an error
  # but not in runmode search 
  # (means that the search returns no hits)
  $s->{runmode} eq 'search' or $s->{x} or return $self->fail ( 'NODATA' );           
 
  # fetch the id corresponding the photo vector pointer x
  $s->{id} = $self->fetch ( $s->{runmode} . '#x2id', $s->{x} ) // undef; 
  
  # if no id was found then it is an error 
  # but not in runmode search 
  #(means that the search returns no hits)
  $s->{runmode} eq 'search' or $s->{id} or return $self->fail ( 'NODATA' );  
 }
 
 return $self->done;

}


sub f_vizinit {

 # prepare visualization related stuff
 
 my $self = shift; my $s = $self->{stash};

 $s->{vizmode} = 'none';
 
 if ( $s->{runmode} eq 'all' ) {
 
  $s->{vizmode} = 'dist'; 
 
 } elsif ( $s->{runmode} eq 'pair' ) { 
 
  if ( $s->{pri} eq 'folder' or $s->{pri} eq 'date' ) {
  
   $s->{vizmode} = 'dist';
  
  } else {

   ( $self->fetch ( 'related#seccnt', $s->{pri} ) > 9 ) and
    $s->{vizmode} = 'rank';
   
  }

 }
 
 # load style (for viz img tags)
 $s->{style} = style_get ( $s->{palette} );
 
 return $self->done;

}
 
sub f_vizdist {

 # get stuff required by distribution visualization a.k.a the pie diagram

 my $self = shift; my $s = $self->{stash};

 $s->{dist} = dist_conf;
 
 $s->{dist_count_all} = $s->{maxx}; # copy total count 
   
 foreach my $key ( @{ $s->{dist}->{keysall} } ) {
  
  # merge real request arguments with distribution arguments
  my @sargs = ( 
   @{ $s->{args_array} }, @{ $s->{dist}->{blocks}->{$key} }  
  );
    
  # prepare coverage counts
  $s->{ 'dist_count_'. $key } = $self->fetch ( "search#count", @sargs );
   
  $s->{ 'dist_perc_' . $key } = ( 
   ( $s->{ 'dist_count_'. $key } / $s->{dist_count_all} ) * 100
   );
   
  # prepare coverage drill parameters to make urls     
  $s->{ 'dist_url_'. $key } = $self->fuseq ( 
   $s->{langa}, ( 'search?q=' . $self->enurl ( args2search ( @sargs ) ) )
  );
  
  $s->{ 'dist_text_'. $key } = $s->{t}->{ 'HAS' . uc ( $key ) .
   ( $s->{ 'dist_count_'. $key } == 1 ? 'A' : '' ) };
      
 }

 return $self->done;
  
}

1;