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

package Catz::Util::Data;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw( exif fixgap loc nat org tolines topiles umb );

use Catz::Data::Conf;
use Catz::Util::File qw ( filenum );
use Catz::Util::String qw ( trim ucclcc );

sub nat { no strict 'refs'; conf ( 'country' ) -> ( @_ ) }

sub fixgap {
 
 # should locate the gap (9999 to 0000 ) in photo file numbers 
 # and reorder the photos to the correct logical order

 my @photos = @_;

 my $prevnum = undef;
 
 foreach my $i ( 0 .. $#photos ) {
 
  my $filenum = filenum ( $photos[ $i ] );
  
  if(defined $prevnum) {
  
   if( int ( $filenum ) > ( int ( $prevnum ) + 5000 ) ) { # gap detected
    
    my @arr = (); # new modified array
    
    # the first part ...
    foreach my $j ($i .. $#photos ) { push @arr, $photos[$j] }
   
    # ... and the second part
    foreach my $j ( 0 .. $i - 1 ) { push @arr, $photos[$j] }
    
    return @arr; # return the modified array
    
   }
   
  }
  
  $prevnum = $filenum;
  
 }
  
 return @photos; # return the original array if reached the end 

}

sub loc {

 my $loc = $_[0];
 
 my $conf = conf ( 'location' );
 
 $conf->{$loc} and $loc = $conf->{$loc};
     
 return ucclcc($loc), ucclcc($loc);
     
}

sub org { no strict 'refs'; conf ( 'organizer' ) -> ( @_ ) }

sub umb { no strict 'refs'; conf ( 'umbrella' ) -> ( @_ ) }

sub tolines { map { trim( $_ ) } split /\n/, trim ( $_[0] ) }

sub topiles { map { trim( $_ ) } split /\#/, trim ( $_[0] ) }

1; 