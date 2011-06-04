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
use Catz::Data::Search qw ( search2args );
use Catz::Util::String qw ( enurl );

sub pre {

 my $self = shift; my $s = $self->{stash};

 # fetch folder<->album mappings
 $s->{map} = $self->fetch ( 'mapper#map' );
 
 # processes id parameter or resolves it from data
 # returns 1 in success, return 0 on reject
 
 if ( $s->{id} ) { 

  $s->{origin} = 'id'; # mark that this was request had an id
   
  $s->{x} = $self->fetch( $s->{runmode} . '#id2x', $s->{id} );
    
  $s->{x} or return 0;
          
 } else { # no id given, must find the id of the first photo in the set
 
  $s->{origin} = 'x'; # mark that the id was resolved
 
  $s->{x} = $self->fetch ( $s->{runmode} . '#first', @{ $s->{args_array} } );
        
  $s->{x} or return 0;
  
  $s->{id} = $self->fetch ( $s->{runmode} . '#x2id', $s->{x} );
  
  $s->{id} or return 0; 
   
 }
 
 return 1;
 
}

sub all {

 my $self = shift; my $s = $self->{stash};

 $s->{args_array} = []; # browsing all photos as default
 $s->{args_count} = 0;  # so the count of args is also 0
 $s->{runmode} = 'all'; # set the runmode to all photos mode
 $s->{pri} = undef; $s->{sec} = undef; $s->{what} = undef;
 
 $self->pre;

 $s->{urlother} =  
  '/' . $s->{langother} . '/' . $s->{action} . '/' .
  ( $s->{origin} eq 'id' ?  $s->{id} . '/' : '' );
 
}

sub pair {

 my $self = shift; my $s = $self->{stash};
   
 $s->{pri} and $s->{sec} or $self->not_found and return;
 $s->{sec} = $self->decode ( $s->{sec} );
 $s->{args_array} = [ $s->{pri}, $s->{sec} ];
 $s->{args_count} = 2;
 $s->{what} = undef;
  
 $s->{runmode} = 'pair'; # set the runmode to pri-sec pair 

 $self->pre;
 
 my $trans = $self->fetch('mapper#trans',$s->{pri}, $s->{sec});  

 $s->{urlother} =  
  '/' . ( join '/', $s->{langother} , $s->{action}, $s->{pri}, 
  $self->encode( $trans ) ). '/' .
  ( $s->{origin} eq 'id' ?  $s->{id} . '/' : '' );

}

sub pattern {

 my $self = shift; my $s = $self->{stash};
 
 $s->{what} = $self->param('what') // undef;
 
 if ( $s->{what} ) {
 
  ( $s->{what}, $s->{args_array} ) = search2args ( $s->{what} );
  $s->{args_count} = scalar @{ $s->{args_array} };
  $s->{pri} = undef; $s->{sec} = undef;

 } else {
  $s->{args_array} = [];
  $s->{args_count} = 0;
  $s->{pri} = undef; $s->{sec} = undef; $s->{what} = undef;
 }
  
 $s->{runmode} = 'search';
 
 $s->{args_count} > 0 and $self->pre;
 
 $s->{urlother} =  
  '/' . $s->{langother} . '/' . $s->{action} . '/' .
  ( $s->{origin} eq 'id' ?  $s->{id} . '/' : '' );
 
} 

sub browseall { $_[0]->all; $_[0]->multi }
sub viewall { $_[0]->all; $_[0]->single }

sub browse { $_[0]->pair; $_[0]->multi }
sub view { $_[0]->pair; $_[0]->single }

sub search { 

 my $self = shift; my $s = $self->{stash};

 $self->pattern; 

 if ( $s->{x} and $s->{id} ) { $self->multi
  
  } else { $self->guide } 

}

sub display { $_[0]->pattern; $_[0]->single }

sub single {

 my $self = shift; my $s = $self->{stash};
 
 ( $s->{total}, $s->{pos}, $s->{pin} ) = @{
  $self->fetch( $s->{runmode} . '#pointer', $s->{x}, @{ $s->{args_array} } )
 };
     
 $s->{total} == 0 and $self->not_found and return;
  
 $s->{detail} = $self->fetch( 'photo#detail', $s->{x});

 $s->{comment} =  $self->fetch( 'photo#text', $s->{x} );
 
 $s->{image} =  $self->fetch( 'photo#image', $s->{x} );
 
 my $keys = $self->fetch ( 'photo#resultkey', $s->{x} );

 result_prepare ( $self, $keys );
        
 $self->render( template => 'page/view' );

}
 
sub multi {

 my $self = shift; my $s = $self->{stash};
 
 ( 
  $s->{total}, $s->{page}, $s->{pages}, $s->{from}, 
  $s->{to}, $s->{pin}, $s->{xs} 
 ) = @{ $self->fetch( 
   $s->{runmode} . '#pager', $s->{x}, $s->{perpage}, @{ $s->{args_array} } 
  ) };
                   
# if no photos found                   
 $s->{total} == 0 and $self->not_found and return;   
 
 # if no photos on this page
 scalar @{ $s->{xs} } == 0 and $self->not_found and return; 
 
 ( $s->{thumb}, $s->{earliest}, $s->{latest} ) = 
  @{ $self->fetch( 'photo#thumb', @{ $s->{xs} } ) };

 $s->{coverage_text} = 
  $self->fetch ( "search#count", @{ $s->{args_array} }, 'has', '+text' );

 $s->{coverage_cat} = 
  $self->fetch ( "search#count", @{ $s->{args_array} }, 'has', '+bcode', 'has', '-cat' );
  
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

sub guide {

 my $self = shift; my $s = $self->{stash};
 
 $s->{total} = 0;
 
 $self->render( template => 'page/search' );

}



1;

__END__

sub browse { # browse photos by one pri-sec pair or no arguments

 my $self = shift; my $s = $self->{stash};
 
 $s->{args_array} = []; # browsing all photos as default
 $s->{args_count} = 0;  # so the count of args is also 0
 $s->{runmode} = 'all'; # set the runmode to all photos 
 
 my $what $self->param( 'what' ) // undef; 
 
 if ( $s->{pri} and $s->{pri} ) { # priority goes to pri,sec pair
 
  $s->{sec} = $self->decode ( $s->{sec} );

  $s->{args_array} = [ $s->{pri}, $s->{sec} ]; # browsing all photos as default
  $s->{args_count} = 2;
  $s->{runmode} = 'pair'; # set the runmode to all photos 
 
  $s->{disp_array} = $self->fetch('mapper#disp',$s->{pri}, $s->{sec});
  
 } elsif ( $what ) { # the second possibility is that this is search
 
  $s->{search} = 'all'; # set the runmode to all photos 
 
 
 
 }
 
 # or we are 
 
    
 
 
 
 } 
 
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

  my $trans = $self->fetch ( 'mapper#trans', $s->{pri}, $s->{sec} );
 
 $s->{urlother} =  
  '/' . $s->{langother} . '/' . $s->{action} . '/' . 
  $trans->[0] . '/' . $self->encode ( $trans->[1] ) . '/';
       
 my $res = $self->fetch( 'pair#pager', $s->{x}, $s->{perpage}, @ { $s->{args_array }} );
 
 $s->{search} = 'asdfasdf';
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