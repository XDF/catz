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

use Catz::Util::Data qw ( 
 exid explink expmacro exptext loc nat org plaincat tolines umb 
);
use Catz::Util::Log qw ( logit );
use Catz::Util::String qw ( clean trim );

my $s_data = {}; # static caching of processed data lines
my $s_exif = {}; # static caching of processed exif lines

###

sub ems {

 my ( $d, $ems ) = @_;
 
 # parses EMS code into ems1, ems3, ems4 and ems5 fragments
 # receives a hashref as an arguments and adds all to that
  
 $ems =~ /^([A-Z]{3,3})(\s+)?(.+)?$/ or die "malformed EMS code '$ems'";
  
 $d->{ems3} = $1;
  
 defined $3 and $d->{ems4} = $3;
 
 defined $d->{ems4} and $d->{ems1} = [ split / /, $d->{ems4} ];
   
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

 # parses single cat information into fragments

 my $data = shift;
 
 print "$data\n"; 

 my $d = {}; # collect the fragments to a hashref
 
 # collect ems
 if ( $data =~ /\[(.+?)\]/ ) { ems ( $d, $1 ) } else {
  die "no ems code in cat data '$data'" 
 }
  
 # collect nick(s)
 if ( $data =~ /^(.*)\((.+?)\)(.*)$/ ) {
  
  my @nicks = map { trim $_ } split /,/, $2;
   
  $d->{nick} = \@nicks; 
    
 }
  
 # collect breeder and remove {}
 ( $data =~ /^(.*)\{(.+?)\}(.*)$/ ) and do 
  { $d->{breeder} = $2; $data = $1 . $2 . $3 };
    
 # extract titles using a sub 
 titles ( $d, $data );  
 
 return ( trim ( $data ), $d ); # return the string output and fragments as hashref

}

sub comment { 

 my $text = shift;
 
 my $d = []; # all findings get packed to this arrayref

 my $text = expmacro ( $text );
 
 # the first element is the text in english
 $d->[0] = exptext ( $text, 'en' );
 
 # the second element is the text in finnish
 $d->[1] = exptext ( $text, 'en' );
 
 $text =  plaincat ( $text );
 
 length ( $text ) > 0 and do { # if something is left ... 
 
  # the third element is the cat data
  $d->[2] = cat ( plaincat ( $text ) );
  
 }; 
     
 return $d;

}

# split the line for separate comments by &
# and call 'comment' with every comment
sub line { [ map { comment ( $_ ) } split / \& /, shift ] }

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

sub set {

 # arrayrefs to collect all set's data and exif 
 my $datas = [];
 my $exifs = [];
 
 foreach my $line ( @{ $_[0] } ) {
 
  $line =~ /^(\w)([\d-]+):\s+(.+)$/ or die "malformed line: '$line'";
   
  my $def = $1;
   
  my ( $from, $to ) = split /-/, $2; 
   
  defined $to or $to = $from;
   
  my $data = $3; 
   
  given ( $def ) {
  
   when ( 'P' ) {  
   
    foreach my $i ( $from .. $to ) {
    
     $datas->[ $i ] = line ( $data );
    
    }
   
   }
   
   when ( 'L' ) {  

    foreach my $i ( $from .. $to ) {
    
     $exifs->[ $i]  = exid ( $data );
    
    }
      
   }
   
   default { die "unknow line type in '$line'" }
  
  }    
   
 }

 return ( $datas, $exifs );

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
  ( $d->{umb_en}, $d->{umb_fi} ) = umb ( $d->{org_en}, $album );
  
 $d->{country} = nat ( $d->{location_en} );
 
 # skip descrption lines, they are deprecated
 shift @lines; shift @lines;
 
 # @lines should now containg only data and exif lines
 # if there are no data yet for a new album there are no lines left
 
 # pass the lines forward to 'set' to get two arrayrefs,
 # one with data lines and another wiht exif lines
 ( $d->{data}, $d->{exif} ) = set ( \@lines );
 
 $album =~ /^201001/ and do { logit ( Dumper $d ); die; }
 
}

__END__

print Dumper ( line ( 'EP, IC, TICA TGA, WW2010 {Framillan} Cool Hurricane, DVM, DTM (Aatu) [CRX n 03]' ) );
#print Dumper ( comm ( 'SC {Ilveslinnan} Amir Akanyildiz, DVM (Miro) [TUV d 62] "first show|ensimmäinen näyttely"' ) );
#print Dumper ( comm ( '"strange|outo" SC {Ilveslinnan} Amir Akanyildiz, DVM (Miro) [TUV d 62]' ) );
#print Dumper ( line ( '"strange|outo" SC {Ilveslinnan} Amir Akanyildiz, DVM (Miro) [TUV d 62] "first show|ensimmäinen näyttely"' ) );
#print Dumper ( comm ( '"strange first show|outo ensimmäinen näyttely"' ) );

