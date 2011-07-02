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

package Catz::Ctrl::All;

use 5.10.0; use strict; use warnings;

use parent 'Catz::Ctrl::Present';

sub all {

 my $self = shift; my $s = $self->{stash};

 $s->{runmode} = 'all';

 # browsing all photos so the args and their count are set to nil
 $s->{args_array} = []; 
 $s->{args_count} = 0; 
 
 # setting to undef a lot of other params
   
 $s->{pri} = undef; $s->{sec} = undef; 
 $s->{what} = undef;
 $s->{refines} = undef; 
 $s->{breedernat} = undef; $s->{breederurl} = undef;
 $s->{origin} = 'none'; # to indiate that origin was not processed
 $s->{trans} = undef;
             
 $self->pre or return 0;
 
 $s->{urlother} =  
  '/' . $s->{langaother} . '/' . $s->{action} . '/' .
  ( $s->{origin} eq 'id' ?  $s->{id} . '/' : '' );

 return 1;
 
}


sub browseall { 

 $_[0]->all or ( $_[0]->not_found and return );
  
 $_[0]->multi or ( $_[0]->not_found and return );
 
}

sub textall { 

 $_[0]->all or ( $_[0]->not_found and return );
   
 $_[0]->text or ( $_[0]->not_found and return );  

}

sub viewall { 

 $_[0]->all or ( $_[0]->not_found and return );
   
 $_[0]->single or ( $_[0]->not_found and return );  

}

1;



