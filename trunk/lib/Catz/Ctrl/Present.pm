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

package Catz::Ctrl::Present;

use 5.10.0; use strict; use warnings;

use parent 'Catz::Core::Ctrl';
       
use List::MoreUtils qw ( any );

use Catz::Data::Result;
use Catz::Data::Search qw ( args2search );
use Catz::Util::String qw ( enurl );

sub process_id {
 
 # processes the id parameter from the request
 # sets the photo x to stash

 # returns true in success, return false on reject
 
 my $self = shift; my $s = $self->{stash};
  
 if ( defined $self->param('id') ) { # id was given in request

  my $id = $self->param('id');

  ( length ( $id ) == 6 and $id =~ /^\d+$/ )  or return 0;

  $s->{origin} = 'id'; # mark that this was request had an id
 
  $s->{id} = $id;
  
  $s->{x} = $self->fetch( 'common#id2x', $id );
    
  $s->{x} or return 0;
          
 } else { # no id given, must find the id of the first photo in the set
 
  $s->{origin} = 'x'; # mark that the id was resolved
 
  $s->{x} = $self->fetch ( 'vector#first', @{ $s->{args_array} } );
        
  $s->{x} or return 0;
  
  $s->{id} = $self->fetch ( 'common#x2id', $s->{x} );
  
  $s->{id} or return 0; 
   
 }

 $s->{idparam} = '';
 $s->{pad} = '';
 
 if ( $s->{origin} eq 'id' ) {
                
   $s->{pad} = '?';

   if ( $s->{args_string} ne '' ) {

    $s->{idparam} = '&id=' . $s->{id};

   } else {

    $s->{idparam} = 'id=' . $s->{id};

   }

 } else {
   
  if ( $s->{args_string} ne '' ) {

    $s->{pad}= '?';

   }

 } 
 return 1;
 
}

sub process_args {

 my $self = shift; my $s = $self->{stash};
 
 # processes the get parameters of the request
 # returns true in success, false on reject
   
 my @args = ();
 my $str = '';

 my $pri = $self->fetch ( 'photo#pri_all' );

 push @{ $pri }, 'has';

 foreach my $key ( $self->param ) {

  any { $_ eq $key } @{ $pri } and do {

   my @vals = $self->param( $key );

   foreach my $val ( @vals ) {

    $str eq '' or $str .= '&';
    $str .= "$key=".enurl($val); 
    push @args, $key; 
    push @args, $val;

   }

  };

 }
 
 $s->{args_string} = $str;  
 $s->{args_count} = scalar @args;
 $s->{args_array} = [ @args ];
 $s->{search} = args2search ( $s->{args_array} );
   
 return 1;

}


sub browse { # browse photos by one pri-sec pair or no arguments

 my $self = shift; my $s = $self->{stash};
 
 $s->{args_array} = []; # browsing all photos
 
 $s->{sec} = $self->decode ( $s->{sec} );
 
 warn $s->{sec};
 
 $s->{pri} and $s->{sec} and
   $s->{args_array} = [ $s->{pri}, $s->{sec} ]; # browsing a pair
 
 if ( $s->{id} ) { # id was given in request, resolve x

  $s->{origin} = 'id'; # mark that this was request had an id

  $s->{x} = $self->fetch( 'pair#id2x',  $s->{id} );
      
  $s->{x} or ( $self->not_found and return );
 
 } else { # no id given, must find the id of the first photo in the set

  $s->{origin} = 'x'; # mark that the id was resolved
 
  $s->{x} = $self->fetch ( 'pair#first', $s->{pri}, $s->{sec} );
        
  $s->{x} or ( $self->not_found and return );
 
  $s->{id} = $self->fetch ( 'pair#x2id', $s->{x} );
 
 } 
     
 my $res = $self->fetch( 'pair#pager', $s->{x}, $s->{perpage}, $s->{pri}, $s->{sec} );
 
 $s->{args_count} = 2; $s->{search} = 'asdfasdf';
 $s->{args_string} = 'asdfasdf';
     
 $res->[0] == 0 and $self->not_found and return;

 $s->{total} = $res->[0];
 $s->{page} = $res->[1];
 $s->{pages} = $res->[2];
 $s->{from} = $res->[3];
 $s->{to} = $res->[4];
 $s->{pin} = $res->[5];
 $s->{xs} = $res->[6];
                   
 $s->{total} == 0 and $self->not_found and return; 
 # no photos found by search 
 
 scalar @{ $s->{xs} } == 0 and $self->not_found and return; 
 # no photos in this page
 
 $res = $self->fetch( 'photo#thumb', @{ $s->{xs} } ) ;
 
 $s->{thumb} = $res->[0];
 $s->{earliest} = $res->[1];
 $s->{latest} = $res->[2];
 
 $s->{texts} = $self->fetch ( 'photo#texts', @{ $s->{xs} } );
 
 $s->{related} = undef;
 
 # when on first page, more than 1 photos and just one pri-sec -pair
 # then fetch related information and send it to template
 #$s->{page} == 1 and $s->{total} > 1 and $s->{args_count} == 2 and  
 # $s->{related} = $self->fetch( 
 #  'locate#related', $s->{args_array}->[0], $s->{args_array}->[1] 
 # ); 
             
 $self->render( template => 'page/browse' );
    
}

sub search { # browse photos by search argument

 my $self = shift; my $s = $self->{stash};
    
 $self->process_args or $self->not_found and return;
 $self->process_id or $self->not_found and return;
    
 my $res = $self->fetch('vector#pager', 
   $s->{x}, $s->{perpage}, @{ $s->{args_array} }  
  );
     
 $res->[0] == 0 and $self->not_found and return;

 $s->{total} = $res->[0];
 $s->{page} = $res->[1];
 $s->{pages} = $res->[2];
 $s->{from} = $res->[3];
 $s->{to} = $res->[4];
 $s->{pin} = $res->[5];
 $s->{xs} = $res->[6];
                   
 $s->{total} == 0 and $self->not_found and return; 
 # no photos found by search 
 
 scalar @{ $s->{xs} } == 0 and $self->not_found and return; 
 # no photos in this page
 
 $res = $self->fetch( 'photo#thumb', @{ $s->{xs} } ) ;
 
 $s->{thumb} = $res->[0];
 $s->{earliest} = $res->[1];
 $s->{latest} = $res->[2];
 
 $s->{texts} = $self->fetch ( 'photo#texts', @{ $s->{xs} } );
 
 $s->{related} = undef;
 
 # when on first page, more than 1 photos and just one pri-sec -pair
 # then fetch related information and send it to template
 $s->{page} == 1 and $s->{total} > 1 and $s->{args_count} == 2 and  
  $s->{related} = $self->fetch( 
   'locate#related', $s->{args_array}->[0], $s->{args_array}->[1] 
  ); 
             
 $self->render( template => 'page/browse' );
    
}


sub view { # show onte photo defined by pri-sec pair or no arguments

 my $self = shift; my $s = $self->{stash};
  
 $s->{args_array} = []; # browsing all photos
 
 $s->{sec} = $self->decode ( $s->{sec} );
 
 warn $s->{sec};
 
 $s->{pri} and $s->{sec} and
   $s->{args_array} = [ $s->{pri}, $s->{sec} ]; # browsing a pair
 
 if ( $s->{id} ) { # id was given in request, resolve x

  $s->{origin} = 'id'; # mark that this was request had an id

  $s->{x} = $self->fetch( 'pair#id2x',  $s->{id} );
      
  $s->{x} or ( $self->not_found and return );
 
 } else { # no id given, must find the id of the first photo in the set

  $s->{origin} = 'x'; # mark that the id was resolved
 
  $s->{x} = $self->fetch ( 'pair#first', $s->{pri}, $s->{sec} );
        
  $s->{x} or ( $self->not_found and return );
 
  $s->{id} = $self->fetch ( 'pair#x2id', $s->{x} );
 
 }
 
  $s->{args_count} = 2; $s->{search} = 'asdfasdf';
 $s->{args_string} = 'asdfasdf'; 
 $s->{pad} = 'asdf'; $s->{idparam} = 'asdf'; 
     
 my $res = $self->fetch('pair#pointer', $s->{x}, @{ $s->{args_array} } );
 
 $res->[0] == 0 and $self->not_found and return;
  
 $s->{total} = $res->[0];
 $s->{pos} = $res->[1];
 $s->{pin} = $res->[2];
    
 $s->{detail} = $self->fetch( 'photo#detail', $s->{x});

 $s->{comment} =  $self->fetch( 'photo#text', $s->{x} );
 
 $s->{image} =  $self->fetch( 'photo#image', $s->{x} );
 
 my $keys = $self->fetch ( 'photo#resultkey', $s->{x} );

 result_prepare ( $self, $keys );
        
 $self->render( template => 'page/view' );

}

sub display { # show one photo defined by search arguments

 my $self = shift; my $s = $self->{stash};
  
 $self->process_args or $self->not_found and return;

 $self->process_id or $self->not_found and return;
     
 my $res = $self->fetch('vector#pointer', $s->{x}, @{ $s->{args_array} } );
 
 $res->[0] == 0 and $self->not_found and return;
  
 $s->{total} = $res->[0];
 $s->{pos} = $res->[1];
 $s->{pin} = $res->[2];
    
 $s->{detail} = $self->fetch( 'photo#detail', $s->{x});

 $s->{comment} =  $self->fetch( 'photo#text', $s->{x} );
 
 $s->{image} =  $self->fetch( 'photo#image', $s->{x} );
 
 my $keys = $self->fetch ( 'photo#resultkey', $s->{x} );

 result_prepare ( $self, $keys );
        
 $self->render( template => 'page/view' );

}

1;