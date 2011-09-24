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

package Catz::Ctrl::Catshow;

use 5.10.0; use strict; use warnings;

use parent 'Catz::Core::Ctrl';

use Catz::Core::Conf;

use Catz::Data::Result;
use Catz::Data::Setup;
use Catz::Data::Style;

use Catz::Util::Number qw ( fmt round );
use Catz::Util::Time qw ( dt );

use constant RESULT_NA => '<!-- N/A -->';

sub result {

 my $self = shift; my $s = $self->{stash};
 
 # result available only without setup
 $s->{langa} ne $s->{lang} and ( $self->not_found and return );

 my $key = $self->param( 'x' ) // undef;

 (
   defined $key and length $key < 2000 
   and $key =~ /^CATZ\-([A-Z2-7]+)\-([0-9A-F]{32,32})$/ 
 ) or $self->render( text => RESULT_NA ) and return;

 my @keys = result_unpack ( $key );
   
 scalar @keys == 3 or 
  $self->render( text => RESULT_NA ) and return;
 
 # this is a pseudo parameter passed to the model that contains the
 # current dt down to 10 minutes, so this parameter changes in every
 # 10 minutes and this makes cached model data live at most 10 minutes
 my $pseudo = substr ( dt, 0, -3 );
  
 my $count = $self->fetch ( 'net#count', $keys[0], $keys[1], $pseudo ) // 0;
  
 $count == 0 and 
  $self->render( text => RESULT_NA ) and return;

 my $res = $self->fetch ( 'net#data', @keys, $pseudo );
 
 defined $res and do {
  
  $s->{result} = $res->[0];
  $s->{attrib} = $res->[1];
 
  $self->render( template => 'elem/result' ) and return;
 
 };
 
 $self->render( text => RESULT_NA );
 
}

sub lastshow {

 my $self = shift; my $s = $self->{stash};
 
 my $aid = $self->fetch ( 'locate#lastshow' ) // undef;
 
 defined $aid or ( $self->not_found and return );
 
 $s->{list} = $self->fetch ( 'locate#dumpshow', $aid );
  
 $s->{site} = conf ( 'url_site' );
 
 $self->render( template => 'block/dumpshow', format => 'txt' );
 
}

sub anyshow {

 my $self = shift; my $s = $self->{stash};
 
 my $aid = $self->fetch ( 'locate#anyshow', $s->{date}, $s->{loc} ) // undef;
 
 defined $aid or ( $self->not_found and return );
 
 $s->{list} = $self->fetch ( 'locate#dumpshow', $aid );
 
 $s->{site} = conf ( 'url_site' );
 
 $self->render( template => 'block/dumpshow', format => 'txt' );
 
}

1;