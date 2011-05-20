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

#
# This module is inspired by MojoX::Renderer::Xslate
# http://search.cpan.org/~gray/MojoX-Renderer-Xslate/ by gray
#

package Catz::Core::Renderer;

use 5.10.0; use strict; use warnings;

use parent 'Exporter';

our @EXPORT = qw ( render );

use Text::Xslate;

use Catz::Core::Conf;

my $tx = Text::Xslate->new(
 cache => conf ( 'cache_renderer' ),
 path => conf ( 'path_renderer' ),
 cache_dir => conf ( 'path_tmp' ) 
);

sub render {
 
 #warn join "\n", @_;
 
 my ( $renderer, $c, $output, $opts ) = @_;
             
 eval {
  $$output = $tx->render( $renderer->template_name( $opts ), $c->stash );
 };
   
 if ( $@ ) {
 
  $c->render_exception( $@ );
  $output = '';
  0;
 
 } else {
 
  1;
  
 }
  
}


1;