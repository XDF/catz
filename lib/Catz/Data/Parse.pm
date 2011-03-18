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

package Catz::Data::Parse;

use strict;
use warnings;

use feature qw ( switch );

use parent 'Exporter';

our @EXPORT = qw ( parse_pile );

use Data::Dumper;

use Catz::Util::Data qw ( loc nat org tolines umb );
use Catz::Util::String qw ( clean trim );

###

sub ems {

 my ( $d, $ems ) = @_;
 
 # parses EMS code into ems1, ems3, ems4 and ems5 fragments
 # receives a hashref as an arguments and adds all to that
  
 ( $ems =~ /^([A-Z]{3,3})(.*)$/ ) or die "no breed code found in EMS code '$ems'";
  
 $d->{ems3} = $1;
  
 defined $2 and $d->{ems4} = trim ( $2 );
 
 defined $d->{ems4} and do { 
 
  my @ems3 = split / /, $d->{ems4};
  
  $d->{ems1} = \@ems3; # store an arrayref
  
 };
 
 $d->{ems5} = $ems; # the original EMS is ems5
  
}

sub titles {

 my ( $d, $str ) = @_;
  
 if ( $str =~ /^(([A-Z0-9]|,| )+) (.*)$/ ) {
 
  #die $1;
 
  my $rest = $3; 
  
  my @pretitles = map { trim $_ } split /,/, $1;
  
  $d->{pretitle} = \@pretitles;
  
 # die Dumper $d;
 #die $rest;
          
  if ( $rest =~ /,(([A-Z0-9]|,| )+)/ ) {
      
   my @posttitles = map { trim $_ } split /,/, $1;
     
   $d->{posttitle} = \@posttitles;
  
  }  
 
 }
   
}

sub cat {

 my $str = shift;
  
 # parses a single cat information into fragments

 my $d = {}; # collect the fragments to a hashref

 # collect ems
 if ( $str =~ /\[(.+?)\]/ ) { ems ( $d, $1 ) } else {
  die "no ems code in cat data '$str'" 
 }
  
 # collect nick and replace () with ""
 if ( $str =~ /^(.*)\((.+?)\)(.*)$/ ) {
  
  my @nicks = map { trim $_ } split /,/, $2;
   
  $d->{nick} = \@nicks; 
  
  $str = qq($1"$2"$3); 
  
 }
  
 # collect breeder and remove {}
 if ( $str =~ /^(.*)\{(.+?)\}(.*)$/ ) { $d->{breeder} = $2; $str = $1 . $2 . $3; }
    
 # extract titles using a sub 
 titles ( $d, $str );  
 
 return ( trim ( $str ), $d ); # return the string output and fragments as hashref

}

sub lang {

 my @parts = split /\|/, $_[0];
 
 given ( scalar @parts ) {
 
  when ( 1 ) { return ( $parts[0], $parts[0] ) }
  
  when ( 2 ) { return ( $parts[0], $parts[1] ) }
 
  default { die "language split failed in data '$_[0]'"; }
 
 }
 
}

###

sub comm { 

 my $str = shift;
 
 my $d = {}; # all findings gets packed to this hashref
   
 # comment may be a full quotation
 # or may have quotation at the beginning
 # or may have quotation at the end
 # or may have quotation at both ends
 # or may have zero quotations
    
 my $quots = $str =~ tr/\"//;
 
 given ( $quots ) {
 
  when ( 0 ) {
  
   my $out; my $cat;
  
  ( $out, $cat ) = cat ( $str );  
  
   $d->{en} = $out; $d->{fi} = $out; $d->{cat} = $cat;
   
  }
  
  when ( 2 ) {
  
   my $begin = ( substr ( $str, 0, 1 ) eq '"' ) ? 1 : 0;
   
   my $end = ( substr ( $str, -1 ) eq '"' ) ? 1 : 0;
   
   if ( $begin and $end ) { # simple fully quoted comment
   
    $str = substr ( $str, 1, -1 );
    
    my $en; my $fi;
    
    ( $en, $fi ) = lang ( $str );
    
    $d->{en} = $en; 
    $d->{fi} = defined $fi ? $fi : $en;
       
   } elsif ( $begin ) { # quotation at the beginning
   
    my $en; my $fi; my $out; my $cat;
    
    $str =~ /^\"(.+)\"(.+)$/;
    
    ( $out, $cat ) = cat ( $2 );
    
    ( $en, $fi ) = lang ( $1 );    
   
    $d->{cat} = $cat;
    
    $d->{en} = $en . ' ' . $out;
    $d->{fi} = $fi . ' ' . $out;
   
   } elsif ( $end ) { # quotation at the end

    my $en; my $fi; my $out; my $cat;
    
    $str =~ /^(.+)\"(.+)\"$/;
    
    ( $out, $cat ) = cat ( $1 );
    
    ( $en, $fi ) = lang ( $2 );    
   
    $d->{cat} = $cat;
    
    $d->{en} = $out . ' ' . $en;
    $d->{fi} = $out . ' ' . $fi;   
   
   } else {
   
    die "data error with quotation marks in '$str'";
   
   }  
   
  }
  
  when ( 4 ) { # cat in the middle
  
    my $en1; my $fi1; my $en2; my $fi2; my $out; my $cat;
    
    $str =~ /^\"(.+)\"(.+)\"(.+)\"$/;
    
    ( $en1, $fi1 ) = lang ( $1 );
    ( $out, $cat ) = cat ( $2 );
    ( $en2, $fi2 ) = lang ( $3 );

    $d->{cat} = $cat;
    
    $d->{en} = qq($en1 $out $en2);
    $d->{fi} = qq($fi1 $out $fi2);   
  
  }
 
  default { die "illegal number of quotations marks ($quots) in data '$str'"; }
 
 }
    
 return $d; # data returned as hashref

}

sub line {

 my $line = shift;
 
 my $d = []; # collect results to an array
 
 $line = clean ( trim ( $line ) ); # get rid of extra whitespaces
 
 # split the line into separate comments
  
 my @comms = split / \& /, $line;
 
 foreach my $str ( @comms ) {  push @{ $d }, comm ( $str ) }  

 return $d; # return the resulting data packed to an array as a ref

}

sub def {

 my $str = shift;
 
 $str =~ /^(\w)([\d\-]+):\s+(.+)$/ or die "malformed line in data: '$str'";
 
 my $def = $1; my $data = $3;
 
 my ( $from, $to ) = split /-/, $2;
 
 defined $to or $to = $from;
 
 given ( $def ) {
 
  when ( 'P' ) { 
  
   my $obj = comm ( $data );
  
  
  }
  
  when ( 'L' ) { die "exid processing not yet implemented" }
  
  default { die "unknow data type: '$str'" } 
 
 }
 
}

sub parse_pile {

 my @lines = tolines ( $_[0] );
 
 my $d = {};
 
 # proceed line by line (shift from @lines)
 
 # if the first line is a section then skip it
 substr ( $lines[0], 0, 1 ) eq '!' and shift @lines;
 
 my $album = shift @lines;
 
 $album =~ /^(20\d{6})([a-z]+)(\d{0,1})$/;
      
 $d->{origined} = $1; # albumn name starts with YYYYDDMM
 ( $d->{location_en}, $d->{location_fi} ) = loc ( $2 ); # location part follows
 # $3 might be 1,2,3 ... to specify multiple albums but is not stored 
 
 shift @lines; # the second line in the pile is deprecated
 
 ( $d->{created}, $d->{modified} ) = split /\//, shift @lines; 

 $d->{name_en} = shift @lines;
 
 $d->{name_fi} = shift @lines;
 
 ( $d->{org_en}, $d->{org_fi} ) = org ( $d->{name_en} );
 
 defined $d->{org_en} and 
  ( $d->{umb_en}, $d->{umb_fi} ) = umb ( $d->{org_en} );
  
 $d->{country} = nat ( $d->{location_en} );
 
 
 
 die Dumper $d;

}

__END__

print Dumper ( line ( 'EP, IC, TICA TGA, WW2010 {Framillan} Cool Hurricane, DVM, DTM (Aatu) [CRX n 03]' ) );
#print Dumper ( comm ( 'SC {Ilveslinnan} Amir Akanyildiz, DVM (Miro) [TUV d 62] "first show|ensimmäinen näyttely"' ) );
#print Dumper ( comm ( '"strange|outo" SC {Ilveslinnan} Amir Akanyildiz, DVM (Miro) [TUV d 62]' ) );
#print Dumper ( line ( '"strange|outo" SC {Ilveslinnan} Amir Akanyildiz, DVM (Miro) [TUV d 62] "first show|ensimmäinen näyttely"' ) );
#print Dumper ( comm ( '"strange first show|outo ensimmäinen näyttely"' ) );

