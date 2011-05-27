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

use 5.10.0; use strict; use warnings;

use parent 'Catz::Core::Ctrl';

use Catz::Core::Conf;
use Catz::Data::List qw ( list_matrix );
use Catz::Data::Search;
use Catz::Util::Number qw ( round );

sub process_width {

 my $self = shift; my $s = $self->{stash};

 my $width = $self->param( 'width' ) // 1200;

 $width =~ /^\d{3,4}$/ or $width = 1200;
  
 $width > 599 or $width = 600;
 
 $width < 2001 or $width = 2000;

 $s->{count_thumb} = 30 + 
  round ( ( ( $width - 600 ) / ( 2000 - 600 ) ) * 50 );

 $s->{count_find} = $s->{count_thumb};

}


sub process_what {

 my $self = shift;
 
 my $what = $self->param( 'what' ) // undef;

 $what or return 0;
 
 length $what > 2000 and return 0;
 
 $self->{stash}->{what} = $what;
 
 return 1;

}

sub find {

 my $self = shift; my $s = $self->{stash};

 $self->process_width;
 
 $self->process_what or ( $self->not_found and return );
  
 $s->{find} = $self->fetch ( 'locate#find', $s->{what}, $s->{count_find} );

 $self->render( template => 'block/find' );

}

sub list {

 my $self = shift; my $s = $self->{stash};

 $s->{matrix} = list_matrix;
 
 $s->{matrix}->{$s->{subject}} or ( $self->not_found and return );
   
 my $res = $self->fetch( 'locate#full', $s->{subject}, $s->{mode} );
 
 $s->{total} = $res->[0];
 $s->{idx} = $res->[1];
 $s->{sets} = $res->[2];
   
 $s->{total} > 0 or ( $self->not_found and return );
 
 $self->render(template => 'page/list');
 
}

sub sample {

 my $self = shift; my $s = $self->{stash};

 $self->process_width;

 $self->process_width or $s->{what} = undef;

 my @set = ();

 if ( $s->{what} ) {
 
  my $res = $self->fetch ( 'locate#find', $s->{what}, $s->{count_find} );
  
  scalar @$res > 0 and do {

   foreach my $i ( 0 .. ( scalar @$res - 1 ) ) {

    if ( scalar @set < $s->{count_thumb} ) {

     push @set, @{ 
      $self->fetch ( 'vector#array_rand', $res->[$i]->[0], $res->[$i]->[1] )
     };

    }   

   }

  };
  
 } else {

  @set = @{ $self->fetch ( 'vector#array_rand' ) };
     
 }

 if ( scalar @set > $s->{count_thumb} ) {

  @set = @set[ 0 .. $s->{count_thumb} - 1 ];

 }
 
 my $th = $self->fetch ( 'photo#thumb', @set );

 $s->{thumb} = $th->[0];

 $self->render( template => 'block/sample' );

}

sub search {

 my $self = shift; my $s = $self->{stash};
   
 $s->{args_array} = [];
 $s->{args_count} = 0;
 $s->{found} = 0;
 $s->{args_string} = undef;
 $s->{thumb} = undef;
 
 $self->process_what or $s->{what} = undef;
     
 if ( $s->{what} ) {
 
  ( $s->{what}, $s->{args_array}, $s->{args_string} ) = search2args ( $s->{what} );
  
  $s->{args_count} = scalar ( @{ $s->{args_array} } );
        
  my @set = @{ $self->fetch ( 'vector#array_rand', @{ $s->{args_array} } ) };
  
  $s->{found} = scalar @set;
  
  scalar @set > 12 and @set = @set[ 0 .. 12 ];
   
  my $th = $self->fetch ( 'photo#thumb', @set );
  
  $s->{thumb} = $th->[0];  
  $s->{earliest} = $th->[1];
  $s->{latest} = $th->[2];        
   
 }
 
 $self->render ( template => 'page/search' );

}

1;
