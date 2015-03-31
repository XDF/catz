#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2013 Heikki Siltala
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

use 5.16.2;
use strict;
use warnings;

# all controllers are of course also Mojolicious controllers
use parent 'Mojolicious::Controller';

use Const::Fast;

use Catz::Data::Conf;
use Catz::Data::Dist;
use Catz::Data::Search;
use Catz::Data::Style;

use Catz::Util::File qw ( findfiles );
use Catz::Util::String qw ( clean noxss trim );

#
# loading of models
#

# when this module gets compiled all models get loaded,
# instantiated and stores to a static hashref

my $models = {};    # model instances are kept here

# define models to be skipped, like
# abstract models that are not to be instantiated
const my $NOLOAD => { Base => 1, Common => 1, Vector => 1 };

# if $noload is not up to date, the warnings like
# Subroutine db_run redefined at ...
# are printed when the system starts

# disk path to models
const my $MPATH => '../lib/Catz/Model';

# we seek the model directory
foreach my $mfile ( findfiles ( $MPATH ) ) {

 # process the filename to a plain class name
 my $class = $mfile;
 $class =~ s|$MPATH/||;
 $class =~ s|\.pm$||;

 exists $NOLOAD->{ $class } or do {

  require $mfile;    # load

  # instantiate, use lower case name as key
  $models->{ lc ( $class ) } = "Catz::Model::$class"->new;

 };

}

sub fetch {

 # fetch data from any Model to any Controller
 # expects model and sub as 'model#sub' and an argument list

 my ( $self, $target, @args ) = @_;
 my $s = $self->{ stash };

 my ( $model, $sub ) = split /#/, $target;

 ( $model and $sub ) or die "illegal target '$target'";

 defined $models->{ $model } or die "model '$model' is not bind";

 $models->{ $model }->fetch ( $s->{ version }, $s->{ lang }, $sub, @args );

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

sub moveto { $_[ 0 ]->goto ( 301, $_[ 1 ] ) }    # permanent redirect 301

sub visitat { $_[ 0 ]->goto ( 302, $_[ 1 ] ) }   # temporary redirect 302

sub add_reason {

 my ( $self, $reason ) = @_;
 my $s = $self->{ stash };

 # get subroutine
 my $origin = ( caller ( 2 ) )[ 3 ];

 # init if needed
 defined $self->{ stash }->{ reason } or $self->{ stash }->{ reason } = [];

 push @{ $self->{ stash }->{ reason } }, $origin;

 push @{ $self->{ stash }->{ reason } }, $reason;

}

sub fail {    # the fail action for controllers

 my ( $self, $reason ) = @_;

 $self->add_reason ( $reason );

 my $origin = ( caller ( 2 ) )[ 3 ];

 # nth level call -> return to upper level with 0 = fail
 # 1st level call -> pass to mojolicious default action

 if   ( $origin =~ /Catz::Ctrl/ ) { return 0 }
 else                             { return $self->reply->not_found }

}

sub done { 1 }    # the ok action for nth level controllers

sub output {

 my ( $self, $template, $format ) = @_;

 $self->render ( template => $template, format => $format // 'html' );

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

 my $self = shift;
 my $s    = $self->{ stash };

 foreach my $var (
  qw (
  runmode origin init what refines breedernat viz_rank trans nats maxx 
  total dist cover_full cover_partial cover_cate cover_breed cover_none
  url_full url_partial url_cate url_breed url_none
  )
  )
 {
  $s->{ $var } = undef;
 }

 defined $s->{ pri } or $s->{ pri } = undef;
 defined $s->{ sec } or $s->{ sec } = undef;

 $s->{ args_array } = [];
 $s->{ args_count } = 0;

 $s->{ maxx } = $self->fetch ( 'all#maxx' );

 return $self->done;

} ## end sub f_init

sub f_map {    # load mappings

 my $self = shift;
 my $s    = $self->{ stash };

 $s->{ action } eq 'find' and goto SKIP_TO_DUAL;

 ( $s->{ maplink } = $self->fetch ( 'map#link' ) )
  or return $self->fail ( 'map#link exit' );

 ( $s->{ mapview } = $self->fetch ( 'map#view' ) )
  or return $self->fail ( 'map#view exit' );

 SKIP_TO_DUAL:

 ( $s->{ mapdual } = $self->fetch ( 'map#dual' ) )
  or return $self->fail ( 'map#dual exit' );

 return $self->done;

} ## end sub f_map

sub f_origin {

 #
 # the photo vector pointer x must be resolved
 # in order to browse or view photos
 #
 # we resolve it from icnoming photo id or from the data
 #

 my $self = shift;
 my $s    = $self->{ stash };

 if ( $s->{ id } ) {    # the request has the photo id defined

  $s->{ origin } = 'id';    # mark that this request had an id

  # fetch the corresponding photo vector pointer x
  $s->{ x } = $self->fetch ( $s->{ runmode } . '#id2x', $s->{ id } );

  $s->{ x } or return $self->fail ( 'unknown photo id' );

 }
 else {

  # no id was given in the request so we point to
  # the id of the first photo in the current set

  $s->{ origin } = 'x';    # mark that we resolved the photo

  # fetch the first photo vector pointer x in the current photo set
  $s->{ x } =
   $self->fetch ( $s->{ runmode } . '#first', @{ $s->{ args_array } } )
   // undef;

  # if no first x was not found then it is an error
  # but not in runmode search
  # (means that the search returns no hits)
  $s->{ runmode } eq 'search'
   or $s->{ x }
   or return $self->fail ( 'no data' );

  # fetch the id corresponding the photo vector pointer x
  $s->{ id } = $self->fetch ( $s->{ runmode } . '#x2id', $s->{ x } ) // undef;

  # if no id was found then it is an error
  # but not in runmode search
  #(means that the search returns no hits)
  $s->{ runmode } eq 'search'
   or $s->{ id }
   or return $self->fail ( 'no data' );
 } ## end else [ if ( $s->{ id } ) ]

 return $self->done;

} ## end sub f_origin

sub f_vizinit {

 # prepare visualization related stuff

 my $self = shift;
 my $s    = $self->{ stash };

 $s->{ vizmode } = 'none';

 if ( $s->{ runmode } eq 'all' ) {

  $s->{ vizmode } = 'dist';

 }
 elsif ( $s->{ runmode } eq 'pair' ) {

  if ( $s->{ pri } eq 'folder' or $s->{ pri } eq 'date' ) {

   $s->{ vizmode } = 'dist';

  }
  else {

   ( $self->fetch ( 'related#seccnt', $s->{ pri } ) > 9 )
    and $s->{ vizmode } = 'rank';

  }

 }

 # load style (for viz img tags)
 $s->{ style } = style_get ( $s->{ palette } );

 return $self->done;

} ## end sub f_vizinit

sub f_dist {

 # get stuff required by distribution visualization a.k.a the pie diagram

 my $self = shift;
 my $s    = $self->{ stash };

 $s->{ dist } = dist_conf;

 $s->{ dist_count_all } = $s->{ maxx };    # copy total count

 foreach my $key ( @{ $s->{ dist }->{ sets }->{ pie } } ) {

  # merge real request arguments with distribution arguments
  $s->{ 'drillargs_' . $key } =
   [ @{ $s->{ args_array } }, @{ $s->{ dist }->{ slices }->{ $key } } ];

  # fetch counts
  $s->{ 'dist_count_' . $key } =
   $self->fetch ( "search#count", @{ $s->{ 'drillargs_' . $key } } );

 }

 dist_prep $s;    # do the rest of preparations

 return $self->done;

} ## end sub f_dist

sub f_pair_start {

 my $self = shift;
 my $s    = $self->{ stash };

 $s->{ runmode } = 'pair';

 # check that pri is acceptable
 $self->fetch ( 'pair#verify', $s->{ pri } )
  or return $self->fail ( 'illegal concept' );
  
 #use Data::Dumper; warn "SECa ". Dumper $s->{ sec };

 $s->{ sec } = $self->decode ( $s->{ sec } );

 #use Data::Dumper; warn "SECb ". Dumper $s->{ sec };

 $s->{ args_array } = [ $s->{ pri }, $s->{ sec } ];
 $s->{ args_count } = 2;

 return $self->done;

}

sub f_search_ok {

 # verifies and processed a search parameter
 # and copies it to stash

 my ( $self, $par, $var ) = @_;
 my $s = $self->{ stash };

 $s->{ $var } = $self->param ( $par ) // undef;

 defined $s->{ $var } or return $self->done;

 # length sanity check 1/2
 length $s->{ $var } > 2000 and return $self->fail ( 'search too long' );

 # it appears that browsers typcially send UTF-8 encoded
 # data when the origin page is UTF-8 -> we decode the data now
 utf8::decode ( $s->{ $var } );

 # length sanity check 2/2
 length $s->{ $var } > 1234 and return $self->fail ( 'too many characters' );

 # remove all unnecessary whitespaces
 $s->{ $var } = noxss clean trim $s->{ $var };

 $s->{ $var } eq '' and $s->{ $var } = undef;

 return $self->done;

} ## end sub f_search_ok

sub f_search_args {

 # prorcess a search string to arguments

 my $self = shift;
 my $s    = $self->{ stash };

 # convert search to an argument array
 $s->{ args_array } = search2args ( $s->{ what } );

 # store argument count separately to stash
 $s->{ args_count } = scalar @{ $s->{ args_array } };

 return $self->done;

}

1;
