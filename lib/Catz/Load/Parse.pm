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
 exid explink expmacro exptext loc nat org plaincat tolines umb 
);
use Catz::Util::Log qw ( logit );
use Catz::Util::String qw ( clean trim );

sub cat {

 # parses single cat information into fragments

 my $data = shift;
 
 #print "$data\n"; 

 my $d = {}; # collect the fragments to a hashref
 
 # collect ems and remove it from data
 if ( $data =~ /^(.*)\[(.+?)\](.*)$/ ) {
  
  $data = $1 . $3;
  
  my $ems = $2;
  
  $ems =~ /^([A-Z]{3,3})(\s+)?(.+)?$/ or die "malformed EMS code '$ems'";
  
  $d->{ems3} = $1;
  
  $3 and $d->{ems4} = $3;
 
  defined $d->{ems4} and $d->{ems1} = [ split / +/, $d->{ems4} ];
   
  $d->{ems5} = $ems; # the original EMS is ems5
  
  length ( trim ( $ems ) ) == 0 and die;
     
 } else {
 
  die "no ems code in cat data '$data'"
   
 }
  
 # collect nick(s) and remove them from data
 if ( $data =~ /^(.*)\((.+?)\)(.*)$/ ) {
 
  $data = $1 . $3;

  my @nicks = map { trim $_ } split /,/, $2;
   
  $d->{nick} = \@nicks; 
    
 }
 
 # remove country codes before and after breeder
 $data =~ s/[A-Z]+\*(\{)/$1/;
 $data =~ s/\*(\})[A-Z]+/$1/;
  
 # collect breeder and remove {} 
 ( $data =~ /^(.*)\{(.+?)\}(.*)$/ ) and do 
  { $d->{breeder} = $2; $data = $1 . $2 . $3 };
  
 my @titles = ();
 
 # collect pre-titles and remove them from data
  
 if ( $data =~ /^(([A-Z0-9 ]|,| )+) (.*)$/ ) {
  
  $data = $3;           
  
  push @titles, map {
   
   trim $_;
      
   s/^(CFA|FIFE|TICA)\s+//; # remove umbrellas from titles
   
   s/\d\d\d\d//; # remove years from WW, SW etc.
   
   $_;
  
  } split /,/, $1;
  
 }

 # collect post-titles and remove them
 if ( $data =~ /^(.+),(([A-Z0-9 ]|,| )+)/ ) {

  # fixed fixes
  $2 eq 'USA' and do { $2 = ''; $data = $data . ", $2" };
  
  $data = $1;
  
  push @titles, map { trim $_ } split /,/, $2;
  
 }
 
 scalar ( @titles ) > 0 and $d->{title} = \@titles;
  
 # store the cat itself, if any
 
 $data = trim ( $data );
 length ( $data ) > 0 and $d->{cat} = $data;  
 
 return $d; # return the string output and fragments as hashref

}

sub comment { 

 my $text = shift;
 
 my $d = []; # all findings get packed to this arrayref

 # expand all macros
 $text = expmacro ( $text );
 
 # expand all links
 $text = explink ( $text );
 
 # the first element is the text in english
 $d->[0] = exptext ( $text, 'en' );
 
 # the second element is the text in finnish
 $d->[1] = exptext ( $text, 'fi' );
 
 #$d->[0] =~ /\(/ or do { $d->[0] ne $d->[1] and die "$d->[0] $d->[1]" };
  
 $text =  plaincat ( $text );
 
 length ( $text ) > 0 and index ( $text, '[' ) > -1 and 
  index ( $text, ']' ) > -1  and do {
   
  # if something is left and ems code is present 
 
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
 ( $d->{loc_en}, $d->{loc_fi} ) = loc ( $2 ); # location part follows
 # $3 might be 1,2,3 ... to specify multiple albums but is not stored 
 
 shift @lines; # the second line in the pile is deprecated
 
 ( $d->{created}, $d->{modified} ) = split /\//, shift @lines; 

 $d->{album_en} = shift @lines;
 
 $d->{album_fi} = shift @lines;
 
 # currently the model and the scripts support only one organization per album
 # the database is build proactively so that it could store multiples
 ( $d->{org_en}, $d->{org_fi} ) = org ( $d->{album_en} );
 
 defined $d->{org_en} and 
  ( $d->{umb_en}, $d->{umb_fi} ) = umb ( $d->{org_en}, $album );
  
 $d->{nat} = nat ( $d->{loc_en} );
 
 # skip descrption lines, they are deprecated
 shift @lines; shift @lines;
 
 # @lines should now containg only data and exif lines
 # if there are no data yet for a new album there are no lines left
 
 # pass the lines forward to 'set' to get two arrayrefs,
 # one with data lines and another wiht exif lines
 ( $d->{data}, $d->{exif} ) = set ( \@lines );
 
 return $d;
 
}

__END__

print Dumper ( line ( 'EP, IC, TICA TGA, WW2010 {Framillan} Cool Hurricane, DVM, DTM (Aatu) [CRX n 03]' ) );
#print Dumper ( comm ( 'SC {Ilveslinnan} Amir Akanyildiz, DVM (Miro) [TUV d 62] "first show|ensimmäinen näyttely"' ) );
#print Dumper ( comm ( '"strange|outo" SC {Ilveslinnan} Amir Akanyildiz, DVM (Miro) [TUV d 62]' ) );
#print Dumper ( line ( '"strange|outo" SC {Ilveslinnan} Amir Akanyildiz, DVM (Miro) [TUV d 62] "first show|ensimmäinen näyttely"' ) );
#print Dumper ( comm ( '"strange first show|outo ensimmäinen näyttely"' ) );

