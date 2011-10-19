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

package Catz::Core::Ctrl;

# the base class for all controllers in the system
# all controlles must inherit from this 

use 5.10.0; use strict; use warnings;

# all controllers are of course also Mojolicious controllers 
use parent 'Mojolicious::Controller';

use List::MoreUtils qw ( none );

use Catz::Core::Conf;

use Catz::Util::File qw ( findfiles );
use Catz::Util::String qw ( clean noxss trim );

# this is how we load and access models: when this module gets compiled
# all models get loaded, instantiated and store to a static hashref  

my $models = {}; # model instances are kept here

# skip these models, this contains abstract models that
# are not to be instantiated and accessed directly
my $noload = { 'Common' => 1, 'Vector' => 1 }; 

my $mpath =  '../lib/Catz/Model';

# we seek the model directory
foreach my $mfile ( findfiles ( $mpath ) ) {

 # process the filename to a plain class name
 my $class = $mfile; $class =~ s|$mpath/||; $class =~ s|\.pm$||; 
  
 $noload->{$class} or do {
 
  # load
  require $mfile;

  # instantiate, use lower case name as key    
  $models->{ lc ( $class ) } = "Catz::Model::$class"->new;  
 
 }; 
 
}

sub redirect_perm { # permanent redirect 301

 # this is a modified copy from Mojolicious core

 my ( $self, $to ) = @_;
 
 my $res = $self->res; $res->code( 301 );
 
 my $headers = $res->headers;
 
 $headers->location( $to );
 
 $headers->content_length( 0 ); 
 
 $self->rendered;

 return $self;
 
}

sub redirect_temp { # temporary redirect 302

 # this is a modified copy from Mojolicious core  

 my ( $self, $to ) = @_;
 
 my $res = $self->res; $res->code( 302 );
 
 my $headers = $res->headers;
 
 $headers->location( $to );
 
 $headers->content_length( 0 ); 
 
 $self->rendered;

 return $self;
 
}

sub not_found {

 my $self = shift;

 # using the Mojolicious built-in feature
 $self->render_not_found;
 
 # we return true to make "$self->not_found and return;"
 # to work at controller
 1; 
 
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

sub safeq {

 # process and sanitize search patterns
 
 my ( $self, $source, $target ) = @_;  my $s = $self->{stash};
 
 $s->{$target} = $self->param($source) // undef;
 
 $s->{$target} and do {
 
  # sanity check
  ( length $s->{$target} > 1234 ) and return 0;

  # it appears that browsers typcially send UTF-8 encoded 
  # data when the origin page is UTF-8 -> we decode the data now   
  utf8::decode ( $s->{what} );

  # remove all unnecessary whitespaces     
  $s->{what} = noxss clean trim $s->{what};
    
  # we don't allow '', we set it to undef
  $s->{what} eq '' and $s->{what} = undef;
 
 };
 
 $s->{init} and do {
 
  # sanity check
  ( length $s->{init} > 1234 ) and return 0;

  # it appears that browsers typcially send UTF-8 encoded 
  # data when the origin page is UTF-8 -> we decode the data now   
  utf8::decode ( $s->{init} );

  # remove all unnecessary whitespaces and prevent XSS   
  $s->{init} = noxss clean trim $s->{init};
    
  # not for robots when with init parameter
  $s->{init} and do {  $s->{meta_index} = 0; $s->{meta_follow} = 0 };

  # we don't allow '', we set it to undef
  $s->{init} eq '' and $s->{init} = undef;
 
 }; 

}

1;