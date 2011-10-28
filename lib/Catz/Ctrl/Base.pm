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

 my ( $self, $reason ) = @_;
 
 defined $reason or return; 

 my $origin = ( caller(2) )[3];
 
 # init if needed
 defined $self->{stash}->{reason} or $self->{stash}->{reason} = [];
 
 push @{ $self->{stash}->{reason} }, $origin;
 push @{ $self->{stash}->{reason} }, $reason->[0] // undef;
 push @{ $self->{stash}->{reason} }, $reason->[1] // undef; 
 

}

sub fail { # the fail action for controllers

 my ( $self, $reason ) = @_;
 
 $self->add_reason ( $reason );

 my $origin = ( caller(2) )[3];
  
 # nth level call -> return to upper level with 0 = fail
 # 1st level call -> pass to mojolicious default action
 
 if ( $origin =~ /Catz::Ctrl/ ) { return 0 }
  else { return $self->render_not_found } 

} 

sub done { 1 } # the ok action for nth level controllers

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

 ( $s->{maplink} = $self->fetch ( 'map#link' ) ) or 
  return $self->fail ( 
   [ 'link mappings not found', 'linkkien vastaavuuksia ei ole' ]
  );
 
 ( $s->{mapview} = $self->fetch ( 'map#view' ) ) or 
  return $self->fail ( 
   [ 'view mappings not found', 'näkymien vastaavuuksia ei ole' ]
  ); 
 
 ( $s->{mapdual} = $self->fetch ( 'map#dual' ) ) or 
  return $self->fail ( 
   [ 'dual mappings not found', 'kaksoisvastaavuuksia ei ole' ]
  );
   
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
    
  $s->{x} or return $self->fail ( [
   "photo $s->{id} does not exist", "kuvaa $s->{id} ei ole"
  ] );
          
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
  $s->{runmode} eq 'search' or $s->{x} or 
   return $self->fail ( [ 
    'no first photo in the set', 'kuvajoukossa ei ensimmäistä kuvaa'
   ] );            
 
  # fetch the id corresponding the photo vector pointer x
  $s->{id} = $self->fetch ( $s->{runmode} . '#x2id', $s->{x} ) // undef; 
  
  # if no id was found then it is an error 
  # but not in runmode search 
  #(means that the search returns no hits)
  $s->{runmode} eq 'search' or $s->{id} or 
   return $self->fail ( [
    'photo set mapping failed', 'kuvajoukon kohdistusvirhe'            
   ] );  
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
  ( $s->{ 'dist_count_'. $key } = $self->fetch ( "search#count", @sargs ) )
   or return $self->fail ( [
    "distribution fetch for key '$key' terminated on error",
    "jakauman haku avaimella '$key' päättyi virheeseen"
   ] ); 
 
  $s->{ 'dist_perc_' . $key } = ( 
   ( $s->{ 'dist_perc_'. $key } / $s->{dist_count_all} ) * 100
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