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

use 5.10.0;
use strict;
use warnings;
 
use parent 'Mojolicious::Controller';

use List::MoreUtils qw ( none );

use Catz::Data::Conf;
use Catz::Util::File qw ( findfiles );

# automatic static preloading and instantiating of all models

my $mpath =  conf ( 'path_model' );

my @noload = qw ( Base Misc ); # skip these models

my $models = {}; # model instances are kept here

foreach my $mfile ( findfiles ( $mpath ) ) {

 my $class = $mfile; $class =~ s|$mpath/||; $class =~ s|\.pm$||;
  
 none { $class eq $_ } @noload and do {
 
  require $mfile;
    
  $models->{ lc ( $class ) } = "Catz::Model::$class"->new;  
 
 }; 
 
}

sub redirect_perm { # permanent redirect 301

 # this is a modified copy from Mojolicious core

 my $self = shift;
 my $res = $self->res;
 
 $res->code(301);

 my $headers = $res->headers;
 $headers->location($self->url_for(@_)->to_abs);
 $headers->content_length(0);

 $self->rendered;

 return $self;
 
}

sub redirect_temp { # temporary redirect 302

 # this is a modified copy from Mojolicious core  

 my $self = shift;
 my $res = $self->res;
 
 $res->code(302);

 my $headers = $res->headers;
 $headers->location($self->url_for(@_)->to_abs);
 $headers->content_length(0);

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
   
 $s->{lang} = 'en';
 
 $s->{version} = '20110505234303';
 
 my ( $model, $sub ) = split /#/, $target;
 
 ( $model and $sub ) or die "unable to access target '$target'";
 
 defined $models->{$model} or die "model '$model' is not bind";
  
 $models->{$model}->fetch( $s->{version}, $s->{lang}, $sub, @args );
   
}

1;

