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

package Catz::Action::Search;

use strict;
use warnings;

use parent 'Catz::Action::Base';

use Catz::Util;

use Catz::Model::Provider;

my $p = Catz::Model::Provider->new();

sub search2args {

 # the search string parser

 my $self = shift;

 my $search = $self->stash->{search};
 
 defined $search or return;

 $search = trim( $search ); 
 $search =~ s/ +/ /g;
 
 my @ag = split / /, $search;
 
 my @args = ();
 
 foreach my $arg ( @ag ) {
 
  my ( $key, $value ) = split /=/, $arg;
  
  push @args, ( $key, $value );
 
 } 
 
 $self->{stash}->{args} = join '/', @args;

}

sub main {

 my $self = shift;
 
 $self->{stash}->{search} = $self->param('search') // undef;
 
 $self->search2args;
 
 my $total = undef;
 
 $self->{stash}->{args} and do {
 
  $total = $p->total ( 
   $self->{stash}->{lang}, split /\//, $self->{stash}->{args} 
  );
 
 };
 
 $self->{stash}->{ergs} = eurl( $self->{stash}->{args} );
 
 $self->{stash}->{total} = $total;
 
 $self->render( template => 'page/search' );
  
}
