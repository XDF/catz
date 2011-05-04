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

package Catz::Util::Image;

use strict;
use warnings;

use feature qw ( switch );

use Image::Size;
use Image::ExifTool qw( :Public );

use Catz::Util::Data qw ( body lens );
use Catz::Util::Number qw ( round );

use base 'Exporter';

our @EXPORT_OK = qw( exif thumbfile widthheight );

sub exif {
 
 my ( $album, $file ) = @_;
 
 my $i = ImageInfo ( $file ); 
 
 my $o = {};
   
 foreach my $key ( keys %{ $i } ) {
 
  given ( $key ) {
  
   when ( 'FocalLength' ) { 
   
    $i->{ $key } =~ s/ mm$//;  
    
    # filter out unknown focal lengths reported by the body as 0 or 0.0
    $i->{ $key } ne '0' and $i->{ $key } ne '0.0' and
     $o->{ flen } = round ( $i->{ $key }, 0 ) . ' mm'; 
   
   }
   
   when ( 'ExposureTime' ) { $o->{etime} = $i->{ $key } . ' s' } 
  
   when ( 'FNumber' ) {
   
    # filter out unknown aperture values reported by the body as 0 or 0.0
    $i->{ $key } ne '0' and  $i->{ $key } ne '0.0' and 
     $o->{fnum} = 'f/' . $i->{ $key } 
   
   }

   when ( 'CreateDate' ) { 
  
   $i->{ $key } =~ /(\d\d\d\d).(\d\d).(\d\d) (\d\d).(\d\d).(\d\d)/;
     
   $o->{dt} = "$1$2$3$4$5$6";
  
   }
  
   when ( 'ISO' ) { $o->{iso} = 'ISO ' . $i->{ $key } }
  
   when ( 'Model' ) {
    
    body ( $i->{ $key } )
     or die "unable to resolve body name with '$i->{ $key }'";
   
    $o->{body} = body ( $i->{ $key } );
      
   }
   
  } 
   
 }
 
 # resolve lens only for albums 2011 and beyond
 int ( substr ( $album, 0, 4 ) ) > 2010 and do { 
  $o->{lens} = lens ( $album, $o->{flen}, $o->{fnum} );
 };
 
 return $o;
     
}  
  
#  
# convert image file name to thumbnail file name
#
sub thumbfile { substr ( $_[0], 0, -4 ) . conf ( 'part_thumb' )  }

#
# get image width and height
# uses Image::Size 
#
# in: filename
# out: width, height
#
sub widthheight { imgsize ( $_[0] ) }

1;