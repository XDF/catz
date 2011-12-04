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

package Catz::Ctrl::Locate;

use 5.12.0; use strict; use warnings;

use parent 'Catz::Ctrl::Base';

use List::MoreUtils qw ( any );

use Catz::Data::Conf;
use Catz::Data::List qw ( list_matrix );
use Catz::Data::Search;

use Catz::Util::Time qw ( dt2w3c );

sub find {

 my $self = shift; my $s = $self->{stash};
  
 $s->{what} = $self->param( 's' ) // undef;
  
 # it appears that browsers typcially send UTF-8 encoded data
 # when the origin page is UTF-8 -> we decode now
 utf8::decode ( $s->{what} );
 
 $s->{find} = []; # empty result array as default
 
 ( length $s->{what} > 0 ) and ( length $s->{what} < 51 ) and   
   $s->{find} = $self->fetch ( 'locate#find', $s->{what}, 50 );

 $self->f_map or return $self->fail ( 'f_map exit' );
 
 $self->output ( 'block/find' );

}

sub list {

 my $self = shift; my $s = $self->{stash};

 $s->{matrix} = list_matrix;
  
 # verify that the subject is known
 $s->{matrix}->{$s->{subject}} 
  or return $self->fail ( 'subject not in matrix' ); 
 
 # verify that the mode is known for this subject
 ( any { $s->{mode} eq $_ } @{ $s->{matrix}->{$s->{subject}}->{modes} } )
  or return $self->fail ( 'subject and mode not in matrix' ); 
 
 $s->{urlother} = $self->fuse ( 
  $s->{langaother} , $s->{action} , $s->{subject} , $s->{mode} 
 );
   
 my $res = $self->fetch( 'locate#full', $s->{subject}, $s->{mode} );
  
 $s->{total} = $res->[0] // 0;
 $s->{idx} = $res->[1] // undef;
 $s->{sets} = $res->[2] // undef;

 $s->{total} > 0 or return $self->fail ( 'no data' );
 
 $self->f_map or return $self->fail ( 'f_map exit' );
      
 $self->output ( 'page/list1' );
 
}

sub lists {

 my $self = shift; my $s = $self->{stash};

 $s->{matrix} = list_matrix;
    
 $s->{urlother} = $self->fuse ( $s->{langaother}, $s->{action} );  
   
 ( $s->{prims} = $self->fetch( 'locate#prims' ) ) or
   return $self->fail ( 'no lists found' ); 
        
 $self->output ( 'page/lists' );
 
}

my $smaps = [ qw ( core news list pair photo ) ];

sub mapidx {

 my $self = shift; my $s = $self->{stash};

 $s->{version_w3c} = dt2w3c $s->{version};

 $s->{smaps} = $smaps;

 return $self->render ( 'map/idx', format => 'xml' );

}

sub mapsub {

 my $self = shift; my $s = $self->{stash};
 
 length $s->{langa} > 2 and return $self->fail ( 'setup set so stopped' );

 $s->{version_w3c} = dt2w3c $s->{version};
  
  given ( $s->{mapsub} ) {

   when ( 'photo' ) {
    
    $s->{surls} = [ map { [ 
     $self->fuse ( 'viewall',  $self->fullnum33( $_->[1], $_->[2] ) ),
     'monthly', 0.3    
    ] } @{ $self->fetch ( 'locate#photos' ) } ];

   }

   when ( 'core' ) { 
   
    $s->{surls} = [
     [ '/', 'daily', 1 ],
     [ '/more/contrib/', 'weekly', 0.9 ],
     [ '/more/quality/', 'monthly', 0.1 ],
     [ '/search/', 'monthly', 0.8 ],
     [ '/news/', 'weekly', 0.4 ],
     [ '/lists/', 'monthly', 0.2 ],    
    ]; 

   }
   
   when ( 'list') {
   
    my $m = list_matrix;
    
    my @urls = ();
    
    foreach my $key ( keys %{ $m } ) {
    
     my $i = 1;
    
     foreach my $mode ( @{ $m->{$key}->{modes} } ) {
     
      push @urls, [ 
       $self->fuse ( 'list', $key, $mode ), 
       $i == 1 ? 'weekly' : 'monthly',
       $i == 1 ? 0.2 : 0.1 
      ]; 
     
      $i++;
      
     } 
    
    
    }
    
    $s->{surls} = \@urls;
   
   }
   
   when ( 'news' ) {
   
    my $i = 0;
    
    my $titles =  $self->fetch ( 'news#titles' );
    
    my @urls = ();
    
    foreach ( my $i = 0; $i < scalar @$titles; $i++ ) {
    
     my $p = 1 - ( $i / 20 ); $p < 0.1 and $p = 0.1;
      
     my $cap = 'daily';
     
     $p < 0.7 and $cap = 'weekly';
     
     $p < 0.2 and $cap = 'monthly';   
    
     push @urls, [ $self->fuse ( 'news', $titles->[$i]->[0] ), $cap, $p ]; 
    
    }

    $s->{surls} = \@urls;
      
   }
   
   when ( 'pair' ) {
   
    $s->{surls} = [ map { [ 
     $self->fuse ( 'browse', $_->[0],  $self->encode( $_->[1] ) ),
     'weekly', 0.5    
    ] } @{ $self->fetch ( 'locate#secs' ) } ];
   
   }

   default { $self->fail ( 'no such sitemap' ) }

  }

 $self->render ( 'map/sub', format => 'xml' );

}

1;
