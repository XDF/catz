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

use 5.12.0; use strict; use warnings;

use parent 'Exporter';

our @EXPORT = qw ( parse_pile );

use Catz::Load::Data qw ( 
 exid expmacro exptext loc org plaincat umb 
);
use Catz::Util::Log qw ( logit );
use Catz::Util::String qw ( clean tolines trim );

sub cat {

 # parses single cat information into fragments

 my $data = shift;
 
 my $d = {}; # collect the fragments to a hashref
 
 # collect emscode and remove it from data
 if ( $data =~ /^(.*)\[(.+?)\](.*)$/ ) {
  
  $data = $1 . $3;
  
  my $code = $2;
  
  $code =~ /^([A-Z]{2}[A-Z1-9])(\s+)?(.+)?$/ or die "malformed code (1) '$code'";
  
  $d->{breed} = $1;
  
  $3 and $d->{app} = $3;
 
  if ( defined $d->{app} ) { 
   
   $d->{feat} = 
    [ map { /^\((.+)\)$/ ? $1 : $_ } split / +/, $d->{app} ];

  } else {

   # add inherent feats to certain breeds
   # don't add if app is defined
   # add only to feat, not to app

   ( $d->{breed} eq 'CHA' or 
     $d->{breed} eq 'KOR' or
     $d->{breed} eq 'RUS'
   ) and $d->{feat} = [ 'a' ]; 

  }
   
  $d->{code} = $code; # the original code in code
  
  length ( trim ( $code ) ) == 0 and die "malformed code (2) '$code'";
     
 } else {
 
  die "no code in cat data '$data'"
   
 }
  
 # collect nick(s) and remove them from data
 
 if ( $data =~ /^(.*)\((.+?)\)(.*)$/ ) {
 
  $data = $1 . $3;

  my @nicks = map { trim $_ } split /,/, $2;
   
  $d->{nick} = \@nicks; 
    
 }
 
 # remove country codes before and after breeder
 
 $data =~ s/[A-Z]+\*(\{)/$1/;
 
 $data =~ s/(\})\*[A-Z]+/$1/;
  
 # collect breeder and remove breeder marters
  
 ( $data =~ /^(.*)\{(.+?)\}(.*)$/ ) and do { 
 
  $d->{breeder} = $2; $data = $1 . $2 . $3;
  
  ( 
   index ( $d->{breeder}, '’' ) > -1 or
   index ( $d->{breeder}, '´' ) > -1 or
   index ( $d->{breeder}, '`' ) > -1 
  ) and die "illegal characters in breeder '$d->{breeder}'"; 
  
 };
  
 my @titles = ();
 
 # collect pre-title codes and remove them from data
  
 if ( $data =~ /^(([A-Z0-9 ]|,| )+) (.*)$/ ) {
  
  $data = $3;           
  
  push @titles, map {
   
   trim $_;
      
   s/^(CFA|FIFE|TICA)\s+//; # remove umbrellas from titles
   
   s/\d\d\d\d//; # remove years from WW, SW etc.
   
   $_;
  
  } split /,/, $1;
  
 }

 # collect post-title codes and remove them from data
 while ( $data =~ /^(.+), (([A-Z0-9 ])+?)$/ ) {
  
  $data = $1;

  push @titles, trim $2;
  
 }
  
 scalar ( @titles ) > 0 and do {
 
  foreach my $title ( @titles ) {
  
   $title =~ /^[A-Z]+(\d{4})?$/ or 
    die "malformed title '$title' in '$data'";
  
  }
 
  $d->{title} = \@titles;
  
 };
  
 # store the cat itself, if any left
 
 $data = trim ( $data );
 
 length ( $data ) > 0 and $d->{cat} = $data;
 
 # convert $ to " on all cat data
 # remove the null characters ~ from all cat data
 # null characters are used to prevent incorrect title extractions
 # they can at this point appear anywhere but on titles
 
 do {

   $d->{$_} =~ s/\$/\"/g;
  
   $_ ne 'title' and $d->{$_} =~ s/\~//g;
       
  } foreach ( keys %{ $d } );
 
 return $d; # return the string output and fragments as hashref

}

sub comment { 

 my $text = shift;
 
 my $d = []; # all findings get packed to this arrayref
 
 # data splitting with & is prevented by writing it &&, now convert it back
 $text =~ s/\&\&/\&/g;

 # find pre nation codes
 my @pre = $text =~  /([A-Za-z]+)\*(?:\{|\w)/g; 
 
 # find post nation codes
 my @post = $text =~ /(?:\}|\w)\*([A-Za-z]+)/g;
 
 ( scalar @pre > 0 or scalar @post > 0 ) and do {
  
  foreach my $nat ( ( @pre, @post ) ) {
  
  length ( $nat ) == 2 or die
   "found nation code '$nat' in '$text' that is not two characters";
   
  $nat eq 'FI' and die
   "found nation code '$nat' in '$text', we don't store $nat";
   
  ( $nat eq uc ( $nat ) ) or die
   "found nation code '$nat' in text '$text' that is not in upper case";  
 
  }
  
 };
  
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
 
 my %seen_l = ();
 my %seen_p = ();
 
 foreach my $line ( @{ $_[0] } ) {
 
  $line =~ /^(\w)([\d-]+):\s+(.+)$/ or die "malformed line: '$line'";
   
  my $def = $1;
   
  my ( $from, $to ) = split /-/, $2; 
   
  defined $to or $to = $from;
   
  my $data = $3; 
   
  given ( $def ) {
  
   when ( 'P' ) {  
   
    foreach my $i ( $from .. $to ) {
    
     exists $seen_p{$i} and die "P index $i already seen within an album";
    
     $datas->[ $i ] = line ( $data );
     
     $seen_p{$i} = 1;
    
    }
   
   }
   
   when ( 'L' ) {  

    foreach my $i ( $from .. $to ) {
    
     exists $seen_l{$i} and die "P index $i already seen within an album";
    
     $exifs->[ $i ]  = exid ( $data );
     
     $seen_l{$i} = 1;
    
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
  
 my $album = substr ( shift @lines, 4 ); # the folder name
  
 $album =~ /^(20\d{6})([a-z]+)(\d{0,1})$/ or
  die "invalid album name '$album'";
   
 $d->{folder_en} = $album;
 $d->{folder_fi} = $album;
 
 $d->{origined} = $1; # albumn name starts with YYYYDDMM
 
 ( $d->{loc_en}, $d->{loc_fi} ) = loc ( $2 );
 
 defined $d->{loc_en} and defined $d->{loc_fi} or die
  "unable to resolve location for album '$album'";
 
 # $3 might be 1,2,3 ... to specify multiple albums but is not stored

 $d->{s} = substr ( shift @lines, 4 ); # the sorter
 
 ( $d->{s} =~ m|^\d{1,3}$| ) or  
  die "unable to find sorter for album '$album'";
 
 $d->{album_en} = substr ( shift @lines, 4 );
 
 length ( $d->{album_en} ) > 9 or 
  die "album name (en) too short for album '$album'";
 
 $d->{album_fi} = substr ( shift @lines, 4 );

 length ( $d->{album_en} ) > 9 or 
  die "album name (fi) too short for album '$album'";
 
 # currently the model and the scripts support only one organization per album
 # the database is build proactively so that it could store multiples
 ( $d->{org_en}, $d->{org_fi} ) = org ( $d->{album_en} );

 defined $d->{org_en} and defined $d->{org_fi} or die
  "unable to resolve organizer for album '$album'";

 ( $d->{umb_en}, $d->{umb_fi} ) = umb ( $d->{org_en}, $album );
  
 defined $d->{umb_en} and defined $d->{umb_fi} or die
  "unable to resolve umbrella for album '$album'";
      
 # @lines should now containg only data P and exif L lines
 # if there are no data yet for a new album there are no lines left
 
 # pass the lines forward to 'set' to get two arrayrefs,
 # one with data lines and another wiht exif lines
 ( $d->{data}, $d->{exif} ) = set ( \@lines );
 
 return $d;
 
}