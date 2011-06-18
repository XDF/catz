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

package Catz::Load::Parse;

use 5.10.0; use strict; use warnings;

use parent 'Exporter';

our @EXPORT = qw ( parse_pile );

use Data::Dumper;

use Catz::Load::Data qw ( 
 exid expmacro exptext location organizer plaincat tolines umbrella 
);
use Catz::Util::Log qw ( logit );
use Catz::Util::String qw ( clean trim );

sub cat {

 # parses single cat information into fragments

 my $data = shift;

 my $d = {}; # collect the fragments to a hashref
 
 # collect emscode and remove it from data
 if ( $data =~ /^(.*)\[(.+?)\](.*)$/ ) {
  
  $data = $1 . $3;
  
  my $emscode = $2;
  
  $emscode =~ /^([A-Z]{3,3})(\s+)?(.+)?$/ or die "malformed emscode (1) '$emscode'";
  
  $d->{breedcode} = $1;
  
  if ( $3 ) { $d->{facadecode} = $3 } else {

   # add inherent blue facadecode for certain breeds

   ( $d->{breedcode} eq 'CHA' or
     $d->{breedcode} eq 'KOR' or
     $d->{breedcode} eq 'RUS'
   ) and $d->{facadecode} = 'a'; 

  }
 
  defined $d->{facadecode} and $d->{featurecode} = [ split / +/, $d->{facadecode} ];
   
  $d->{emscode} = $emscode; # the original code in code
  
  length ( trim ( $emscode ) ) == 0 and die "malformed emscode (2) '$emscode'";
     
 } else {
 
  die "no emscode in cat data '$data'"
   
 }
  
 # collect nick(s) and remove them from data
 
 if ( $data =~ /^(.*)\((.+?)\)(.*)$/ ) {
 
  $data = $1 . $3;

  my @nicks = map { trim $_ } split /,/, $2;
   
  $d->{nickname} = \@nicks; 
    
 }
 
 # remove country codes before and after breeder
 
 $data =~ s/[A-Z]+\*(\{)/$1/;
 
 $data =~ s/(\})\*[A-Z]+/$1/;
  
 # collect breeder and remove breeder marters
  
 ( $data =~ /^(.*)\{(.+?)\}(.*)$/ ) and do
  { $d->{breeder} = $2; $data = $1 . $2 . $3 };
  
 my @titlecodes = ();
 
 # collect pre-title codes and remove them from data
  
 if ( $data =~ /^(([A-Z0-9 ]|,| )+) (.*)$/ ) {
  
  $data = $3;           
  
  push @titlecodes, map {
   
   trim $_;
      
   s/^(CFA|FIFE|TICA)\s+//; # remove umbrellas from titles
   
   s/\d\d\d\d//; # remove years from WW, SW etc.
   
   $_;
  
  } split /,/, $1;
  
 }

 # collect post-title codes and remove them from data
 if ( $data =~ /^(.+), (([A-Z0-9 ]|,| )+)$/ ) {
  
  $data = $1;
  
  push @titlecodes, map { trim $_ } split /,/, $2;
  
 }
  
 scalar ( @titlecodes ) > 0 and $d->{titlecode} = \@titlecodes;
  
 # store the cat itself, if any left
 
 $data = trim ( $data );
 
 length ( $data ) > 0 and $d->{catname} = $data;
 
 # remove the null characters ~ from all cat data
 # null characters are used to prevent incorrect title extractions
 # they can at this point appear anywhere but on titles
 
 do { $_ ne 'titlecode' and $d->{$_} =~ s/\~//g } foreach ( keys %{ $d } );
 
 return $d; # return the string output and fragments as hashref

}

sub comment { 

 my $text = shift;
 
 my $d = []; # all findings get packed to this arrayref
 
 # data splitting with & is prevented by writing it &&, now convert it back
 $text =~ s/\&\&/\&/g; 
  
 # expand all macros
 $text = expmacro ( $text );
   
 # the first element is the text in english
 $d->[0] = exptext ( $text, 'en' );
 
 # the second element is the text in finnish
 $d->[1] = exptext ( $text, 'fi' );
    
 $text =  plaincat ( $text );
 
 length ( $text ) > 0 and index ( $text, '[' ) > -1 and 
  index ( $text, ']' ) > -1  and do {
   
  # if something is left and code is present 
 
  $d->[2] = cat ( $text );
  
 }; 
     
 return $d;

}

# split the line for separate comments by &
# and call 'comment' with every comment
sub line { [ map { comment ( $_ ) } split / \& /, shift ] }

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
    
     $exifs->[ $i ]  = exid ( $data );
    
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
  
 $album =~ /^(20\d{6})([a-z]+)(\d{0,1})$/ or
  die "invalid album name '$album'";
  
 $d->{folder_en} = $album;
 $d->{folder_fi} = $album;
      
 $d->{origined} = $1; # albumn name starts with YYYYDDMM
 ( $d->{location_en}, $d->{location_fi} ) = location ( $2 ); # location part follows
 # $3 might be 1,2,3 ... to specify multiple albums but is not stored 
 
 shift @lines; # the second line in the pile is deprecated
 
 ( $d->{created}, $d->{modified} ) = split /\//, shift @lines; 

 $d->{album_en} = shift @lines;
 
 $d->{album_fi} = shift @lines;
 
 # currently the model and the scripts support only one organization per album
 # the database is build proactively so that it could store multiples
 ( $d->{organizer_en}, $d->{organizer_fi} ) = organizer ( $d->{album_en} );
 
 defined $d->{organizer_en} and 
  ( $d->{umbrella_en}, $d->{umbrella_fi} ) = umbrella ( $d->{organizer_en}, $album );
   
 # skip descrption lines, they are deprecated
 shift @lines; shift @lines;
 
 # @lines should now containg only data and exif lines
 # if there are no data yet for a new album there are no lines left
 
 # pass the lines forward to 'set' to get two arrayrefs,
 # one with data lines and another wiht exif lines
 ( $d->{data}, $d->{exif} ) = set ( \@lines );
 
 return $d;
 
}


