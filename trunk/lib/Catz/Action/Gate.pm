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

package Catz::Action::Gate;

use strict; 
use warnings;

use Catz::DB;
use Catz::Model::Vector;

use parent 'Catz::Action::Base';

sub sample {

 my $self = shift;
 
 my $stash = $self->{stash};
 
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
 
 my $xs = vector_array_random ( $stash->{lang}, @args );
 
 warn 'count ' . $stash->{count};
 
 my @set = @{ $xs } [ 0 .. $stash->{count} - 1 ];
 
 $stash->{thumbs} = db_all( "select flesh.fid,album,file||'_LR.JPG',width_lr,height_lr from photo natural join flesh natural join _fid_x where x in (" 
  . ( join ',', @set ) .  ') order by x' );
 
 $self->render( template => 'elem/sample' );
      
}

1; 