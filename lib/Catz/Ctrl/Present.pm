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
use Catz::Data::Search;
use Catz::Util::String qw ( enurl );

sub pre {

 my $self = shift; my $s = $self->{stash};

 $s->{maplink} = $self->fetch ( 'map#link' );
 $s->{mapview} = $self->fetch ( 'map#view' );
 $s->{mapdual} = $self->fetch ( 'map#dual' );
 
 # processes id parameter or resolves it from data
 # returns 1 in success, return 0 on reject
 
 if ( $s->{id} ) { 

  $s->{origin} = 'id'; # mark that this was request had an id
   
  $s->{x} = $self->fetch( $s->{runmode} . '#id2x', $s->{id} );
    
  $s->{x} or return 0;
          
 } else { # no id given, must find the id of the first photo in the set
 
  $s->{origin} = 'x'; # mark that the id was resolved
 
  $s->{x} = $self->fetch ( $s->{runmode} . '#first', @{ $s->{args_array} } );
  
  # allow the system to continue if search returns nothing
  $s->{runmode} ne 'search' and (  $s->{x} or return 0 );            
  
  $s->{x} and do { 
   $s->{id} = $self->fetch ( $s->{runmode} . '#x2id', $s->{x} ) 
  };
  
  # allow the system to continue if search returns nothing
  $s->{runmode} ne 'search' and (  $s->{id} or return 0 ); 
   
 }
 
 return 1;
 
}

sub all {

 my $self = shift; my $s = $self->{stash};

 $s->{args_array} = []; # browsing all photos as default
 $s->{args_count} = 0;  # so the count of args is also 0
 $s->{runmode} = 'all'; # set the runmode to all photos mode
 $s->{pri} = undef; $s->{sec} = undef; $s->{what} = undef;
 $s->{refines} = undef;
 $s->{breedernation} = undef;
 $s->{breederurl} = undef;
 
 $self->pre or return 0;

 $s->{urlother} =  
  '/' . $s->{langother} . '/' . $s->{action} . '/' .
  ( $s->{origin} eq 'id' ?  $s->{id} . '/' : '' );

 return 1;
 
}

sub pair {

 my $self = shift; my $s = $self->{stash};
   
 $s->{pri} and $s->{sec} or $self->not_found and return;
 $s->{sec} = $self->decode ( $s->{sec} );
 $s->{args_array} = [ $s->{pri}, $s->{sec} ];
 $s->{args_count} = 2;
 $s->{what} = undef;
 $s->{refines} = undef;
 $s->{breedernation} = undef;
 $s->{breederurl} = undef;
 
 $s->{runmode} = 'pair'; # set the runmode to pri-sec pair 

 $self->pre or return 0;
 
 my $trans = $self->fetch ( 'map#trans', $s->{pri}, $s->{sec} );  

 $s->{urlother} =  
  '/' . ( join '/', $s->{langother} , $s->{action}, $s->{pri}, 
  $self->encode( $trans ) ). '/' .
  ( $s->{origin} eq 'id' ?  $s->{id} . '/' : '' );

 defined $s->{matrix}->{$s->{pri}}->{refines} and 
  $s->{refines} = $self->fetch ('related#refines', $s->{pri}, $s->{sec}, @{ $s->{matrix}->{$s->{pri}}->{refines} } ); 

 if ( $s->{pri} eq 'breeder' ) {
  $s->{breedernation} = $self->fetch ( "related#breedernat", $s->{sec} );
  $s->{breederurl} = $self->fetch ( "related#breederurl", $s->{sec} );
 }
 
 return 1;

}

sub pattern {

 my $self = shift; my $s = $self->{stash};
  
 $s->{pri} = undef; $s->{sec} = undef;
 $s->{refines} = undef;
 $s->{breedernation} = undef;
 $s->{breederurl} = undef;
 
 $s->{what} = $self->param('what') // undef;
 $s->{init} = $self->param('init') // undef;
 
 if ( $s->{what} ) {
 
  ( $s->{what}, $s->{args_array} ) = search2args ( $s->{what} );
  $s->{args_count} = scalar @{ $s->{args_array} };

 } else {
  $s->{args_array} = [];
  $s->{args_count} = 0;
  $s->{what} = undef;
 }
  
 $s->{runmode} = 'search';
 
 $s->{args_count} > 0 and ( $self->pre or return 0 );
 
 $s->{urlother} =  '/' . $s->{langother} . '/' . $s->{action};
 
 if ( $s->{what} ) {
 
  if ( $s->{origin} eq 'id' ) {
  
   $s->{urlother} .= '/' . $s->{id} . '?what=' .  enurl ( $s->{what} );
  
  } else {
  
   $s->{urlother} .= '?what=' .  enurl ( $s->{what} );
  
  } 
 
 } elsif ( $s->{init} ) {

  $s->{urlother} .= '?init=' .  enurl ( $s->{init} );
 
 } else {

  $s->{urlother} .=  ( $s->{origin} eq 'id' ?  '/' . $s->{id} . '/' : '/' );
  
 }

 return 1;
  
}

sub single {

 my $self = shift; my $s = $self->{stash};
 
 ( $s->{total}, $s->{pos}, $s->{pin} ) = @{
  $self->fetch( $s->{runmode} . '#pointer', $s->{x}, @{ $s->{args_array} } )
 };
     
 $s->{total} == 0 and return 0;

 $s->{comment} =  $self->fetch( 'photo#text', $s->{x} );
   
 $s->{detail} = $self->fetch( 'photo#detail', $s->{x});
 
 $s->{image} =  $self->fetch( 'photo#image', $s->{x} );
 
 my $keys = $self->fetch ( 'photo#resultkey', $s->{x} );

 result_prepare ( $self, $keys );
        
 $self->render( template => 'page/view' );
 
 return 1;

}
 
sub multi {

 my $self = shift; my $s = $self->{stash};
 
 ( 
  $s->{total}, $s->{page}, $s->{pages}, $s->{from}, 
  $s->{to}, $s->{pin}, $s->{xs}, $s->{xfirst}, $s->{xlast} 
 ) = @{ $self->fetch( 
   $s->{runmode} . '#pager', $s->{x}, $s->{perpage}, @{ $s->{args_array} } 
  ) };
                    
 # if no photos found                   
 $s->{total} == 0 and return 0;   
 
 # if no photos on this page
 scalar @{ $s->{xs} } == 0 and return 0; 
 
 ( $s->{thumb}, $s->{earliest}, $s->{latest} ) = 
  @{ $self->fetch( 'photo#thumb', @{ $s->{xs} } ) };
  
 $s->{cover_notext} = undef; $s->{url_notext} = undef;
 $s->{cover_nocat} = undef; $s->{url_nocat} = undef;
 
 if ( $s->{runmode} ne 'search' ) {
  
  my @extra = qw ( -has text );

  $s->{cover_notext} = 
   $self->fetch ( "search#count", @{ $s->{args_array} }, @extra );
  
  $s->{cover_notext} > 0 and
  $s->{url_notext} =
   args2search (  @{ $s->{args_array} }, @extra );
  
  @extra = qw ( +has breed -has cat );
  
  $s->{cover_nocat} = 
   $self->fetch ( "search#count", @{ $s->{args_array} }, @extra );

  $s->{cover_nocat} > 0 and
  $s->{url_nocat} =
   args2search (  @{ $s->{args_array} }, @extra );
  
 }
  
 $s->{texts} = $self->fetch ( 'photo#texts', @{ $s->{xs} } );
  
 # date jumps are only available for all and pair, not for search
 if ( $s->{runmode} eq 'all' ) {
 
  $s->{jump2date} = $self->fetch ( 'related#all2date' );
 
 } elsif ( $s->{runmode} eq 'pair' ) {

  # upper and lower x of the photos on this page are used to limit the dates so that there are no links dates on this page
  $s->{jump2date} = $self->fetch ( 'related#pair2date', $s->{pri}, $s->{sec}, $s->{xs}->[0], $s->{xs}->[$#{$s->{xs}}] );

 } else {
 
  $s->{jump2date} = undef;
 
 }
 
 $s->{fresh} = $self->fetch ( 'related#date', $s->{xfirst} );
 $s->{ancient} = $self->fetch ( 'related#date', $s->{xlast} );
  
 $self->render( template => 'page/browse' );
 
 return 1;

}

sub guide {

 my $self = shift; my $s = $self->{stash};
 
 $s->{total} = 0;
  
 $self->render( template => 'page/search' );

 return 1;

} 

sub browseall { 

 $_[0]->all or $_[0]->not_found and return; 
 $_[0]->multi or $_[0]->not_found and return;
 
}

sub viewall { 

 $_[0]->all or $_[0]->not_found and return;  
 $_[0]->single or $_[0]->not_found and return;  

}

sub browse {
 
 $_[0]->pair or $_[0]->not_found and return;  
 $_[0]->multi or $_[0]->not_found and return;  

}
sub view { 

 $_[0]->pair or $_[0]->not_found and return;  
 $_[0]->single or $_[0]->not_found and return;  
 
}

sub search { 

 my $self = shift; my $s = $self->{stash};

 $self->pattern or $self->not_found and return; 

 if ( $s->{x} and $s->{id} ) { 
 
  $self->multi or $self->not_found and return; 
  
  } else { 
  
 $self->guide or $self->not_found and return;  

 } 

}

sub display { 

 $_[0]->pattern or $_[0]->not_found and return;
 
 $_[0]->single or $_[0]->not_found and return 
 
}



1;