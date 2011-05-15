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

package Catz::Load::Data;

use 5.10.0; use strict; use warnings;

use base 'Exporter';

our @EXPORT_OK = qw( 
 body exifsort exid explink expmacro exptext fixgap lens loc nat org 
 plaincat textchoose textremove tolines topiles umb 
);

use Memoize;

use Catz::Core::Conf;
use Catz::Util::File qw ( filenum );
use Catz::Util::Number qw ( round );
use Catz::Util::String qw ( clean trim ucclcc );
use Catz::Util::Time qw ( dtexpand );


memoize ( 'exifsort' );

sub exifsort {

 my ( $key, $val ) = @_;

 given ( $key ) {
 
  when ( 'fnum' ) {  
  
   $val =~ /^f\/(\d+).(\d+)?$/;
   
   ( defined $1 and defined $2 ) or die "malformed exif '$key' '$val'";
    
   return sprintf ( "%04d" , $1.$2 );  
  
  }
  
  when ( 'etime' ) {  
  
   $val =~ /^(.+) s$/;
   
   defined $1 or die "malformed exif '$key' '$val'";
   
   my $res =  eval ( $1 );
   
   # works up to 999 seconds of exposure time due to
   # 1) padding length
   # 2)  behavior with sprintf (negative sign appears)
   $res > 200 and die "etime exif processing doesn't support value '$res'"; 
   
   return sprintf ( "%010d", ( $res * 10_000_000 ) );
     
  }
  
  when ( 'iso' ) {  
  
   $val =~ /^ISO (\d+)$/;
   
   defined $1 or die "malformed exif '$key' '$val'";
   
   return sprintf ( "%06d" , $1 );
     
  }
  
  when ( 'flen' ) {  

   $val =~ /^(\d+) mm$/;
   
   defined $1 or die "malformed exif '$key' '$val'";
  
   return sprintf ( "%04d", $1 );  
  
  }
  
  when ( [ qw ( lens body dt ) ] ) { return $val }
  
  default { die "unable to make sorter for exif key '$key'" }
 
 }
 
}

memoize ( 'expand_common' );

sub expand_common {

 ### NOT USED RIGHT NOW!

 my $text = shift;

 $text =~ s/FIFE/FIFe/g;
 
 return $text; 

}

memoize ( 'exptext' );

sub exptext {

 my ( $text, $lang ) = @_;
 
# my $old = $text;
 
 if( $lang eq 'fi' ) { 
 
  $text =~ s/\"(.+?)\|(.+?)\"/$2/g; # dual lang, use second version
  
 } else {
 
  $text =~ s/\"(.+?)\|(.+?)\"/$1/g; # dual lang, use first version
 
 }
 
 $text =~ s/\"(.+?)\"/$1/g; # single lang

# ( $text ne $old ) and logit ( "$old -> $text" );
  
 $text =~ s/\{(.+)\}/$1/g; # also remove breeder markers
  
 return $text;
 
}

memoize ( 'explink' );

sub explink {

 my $text = shift;
 
 #my $old = $text; 
  
 $text =~ s/\<(.+?)\|(.+?)\>/\<a href\=\"$1\"\>$2\<\/a\>/g;
 
 #( $text ne $old ) and logit ( "$old -> $text" ); 
 
 return $text;
   
}

memoize ( 'macro' );

sub macro {

 my ( $type, $key ) = @_;
 
 my $macro = conf ( 'macro' );
 
 given ( $type ) {
 
  when ( 'A' ) { # age
   
   my $en = $key; 
   my $fi = $key; 
 
   $fi =~ tr/\,/\,/;
   $en =~ tr/\./\,/;
  
   $en =~ s/y/ years /;
   $en =~ s/m/ months /;
   $en =~ s/w/ weeks /; 
   $en =~ s/d/ days /;
   $en = trim ( $en );
   
      
   $fi =~ s/y/ vuotta /; 
   $fi =~ s/m/ kuukautta /;
   $fi =~ s/w/ viikkoa /; 
   $fi =~ s/d/ päivää /;
   $fi = trim ( $fi );
  
   return qq("at the age of $en|ikä: $fi");
 
  }
 
  when ( 'B' ) { # born
 
   $key =~ /^\d{8}$/ or die "illegal date in born macro '$key'";
 
   my $en = dtexpand ( $key, 'en' );
   my $fi = dtexpand ( $key, 'fi' );
 
   return qq("born $en|syntynyt $fi");
 
  }
 
  when ( 'F' ) { return qq("female|naaras") } 
 
  when ( 'M' ) { return qq("male|uros") }

  when ( 'W' ) {
 
   my $en = $key; $en =~ tr/,/./;
   my $fi = $key; $fi =~ tr/./,/;
  
   return qq("weight $en kg|paino $en kg");
 
  } 
 
  when ( [ qw ( P X ) ] ) { # position, general 

   $macro->{ $key } or die "unknow macro key '$key'";
  
   return $macro->{ $key }; 
 
  }
 
  default { die "unknow macro type $type" } 
 
 }
 
} 

memoize ( 'expmacro' );

sub expmacro {

 my $text = shift;
  
 while ( $text =~ /(^| )(\%([A-Z])(\S*))/ ) {
  # it is imporatant to check that macro starts with the beginning of
  # data or with a space since % encoding may appear in hyperlinks
 
  my $from = $2; my $type = $3; my $key = $4;
 
  my $to = macro ( $type, $key );
  
  $text =~ s/$from/$to/g;
   
 }

 return $text;
 
}

memoize ( 'plaincat' );

sub plaincat {

 # removes all freetext parts -> just cat data is left

 my $text = shift;

 $text =~ s/\".+?\"//g;

 return trim ( clean ( $text ) );

}

memoize ( 'lens' );

sub lens {

 my ( $album, $flen, $fnum ) = @_;
   
 my $date = substr ( $album, 0, 8 ); # use only date
 $flen =~ s/ mm$//g; # remove ' mm'
 $fnum =~ s/f\///; # remove 'f/'
 
 my $lens;
 
 given ( $flen ) { # substr -3 removes ' mm'
 
  when ( 17 )  { $lens = 'tokina17' }
  when ( 28 )  { $lens = 'sigma28' }
  when ( 50 )  { $lens = 'sigma50' }
  when ( 85 )  { $lens = 'sigma85' }
  when ( 135 ) { $lens = 'canon135l' }   
  when ( 200 ) { $lens = 'canon200l' }
  
  default {
  
   if ( $flen < 17 ) {
    if ( $flen < 5 ) {
     $lens = 'dmwlw64';
    } else {
     $lens = 'lx3leica';
    } 
   } else { 
    die "unable to resolve lens '$date' '$flen' '$fnum'";
   } 
  }
  
 }
 
 my $true = conf ( 'lensname' )->{$lens} // undef;
 
 $true or die "unable to find true lens name for '$lens'";
 
 #print "$true\n";
 
 return $true; 

}

memoize ( 'body' );

sub body {
 
 $_ = $_[0];
 
 m|ND\-4020| and return 'Nytech ND-4020';
 
 m| 300D| and return 'Canon EOS 300D';
 
 m|EOS 20D| and return 'Canon EOS 20D';
 
 m|EOS 40D| and return 'Canon EOS 40D';
  
 m|Mark III| and return 'Canon EOS 1D Mark III';
  
 m|DMC-LX3| and return 'Panasonic Lumix DMC-LX3';
  
 return undef; 
 
}

memoize ( 'nat' );

sub nat { 'FI' } # at the moment all galleries are from Finland

sub exid {
 
 my @parts = split /,/, $_[0];
  
 my $o = {};
 
 # lens must be the first part
 my $lens = shift @parts;
 
 defined conf ( 'lensname' )->{ $lens } or 
  die "unknow lens '$lens'";
  
 $o->{lens} = conf ( 'lensname' )->{ $lens };
 
 # other parts may vary
 foreach my $part ( @parts ) {
 
  my ( $key , $val ) = split /=/, $part;
  
  given ( $key ) {
  
   when ( /^exif_focal_/ ) { 
   
    $val =~ /^(\d+)/;
    
    defined $1 or die "illegal focal length '$val'";
    
    $val = round ( $1, 0 );
    
    $o->{flen} = "$val mm"; 
   
   }
   
   when ( /^exif_f_/ ) {
   
    # if needed adds '.0' to the end
    # accepts f number both with and without 'f/'
    
    $val =~ /\.\d$/ or $val = "$val.0";
   
    if ( substr ( $val, 0, 2 ) eq 'f/' ) {
    
     $o->{fnum} = $val;
    
    } else {
    
     $o->{fnum} = "f/$val";
    
    }
    
   }
   
   when ( /^exif_exposure_t/ ) { 
   
    $val =~ / s$/ or $val = "$val s";
   
    $o->{etime} = $val; 
   
   }
   
   when ( /^exif_iso/ ) {
   
    substr ( $val, 0, 4 ) eq 'ISO ' or $val = "ISO $val"; 
   
    $o->{iso} = $val;
    
   }
   
   when ( /^exif_camera_mo/ ) { $o->{body} = $val }
   
   when ( /^exif_flash_/ ) {  } # skip this, this is deprecated
  
   default { die "unable to process $key at '$_[0]'" }
  
  }
  
 }
      
 return $o;
     
}

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

memoize ( 'loc' );

sub loc {

 my $loc = $_[0];
 
 my $conf = conf ( 'location' );
 
 $conf->{$loc} and $loc = $conf->{$loc};
     
 return ucclcc($loc), ucclcc($loc);
     
}

memoize ( 'org' );

sub org { 
 
 given ( shift ) {
    
  when ( /cornish rex/i ) {
   return 'Norwegian Forest Cat Association','Norjalainen Metsäkissa -yhdistys' 
  }
  
  when ( /norwegian forest cat/i ) 
   { return 'Cornish Rex Association','Cornish Rex -yhdistys' }
  
  when ( /american curl/i )  
   { return 'American Curl Association','American Curl -yhdistys' }
  
  when ( /manxrengas/i )   
   { return 'Manx Association','Manxrengas' }
  
  when ( /maine coon/i )  
   { return 'Maine Coon Association','Maine Coon -yhdistys' }
  
  when ( /korat cat/i ) 
   { return 'Korat Association','Korat-yhdistys' }
  
  when ( /InCat/ ) { return 'InCat','InCat' }
          
  when ( /SUROK/ ) { return 'SUROK','SUROK' }
 
  when ( /TUROK/ ) { return 'TUROK','TUROK' }

  when ( /PIROK/ ) { return 'PIROK','PIROK' }
 
  when ( /RuRok/ ) { return 'RuRok','RuRok' }
 
  when ( /POROK/ ) { return 'POROK','POROK' }
 
  when ( /ISROK/ ) { return 'ISROK','ISROK' }
 
  when ( /KES-KIS/ ) { return 'KES-KIS','KES-KIS' }
 
  when ( /POH-KIS/ ) { return 'POH-KIS','POH-KIS' }
 
  when ( /ERY-SYD/ ) { return 'ERY-SYD','ERY-SYD' }
 
  when ( /URK/ ) { return 'URK','URK' }
 
  when ( /SUVAK/ ) { return 'SUVAK','SUVAK' }
 
  when ( /SRK/) { return 'SRK','Kissaliitto' }
 
  when ( /CFF/ ) { return 'CFF','CFF' }
 
  when ( /FINTICAt/ ) { return 'FINTICAt','FINTICAt' }
 
  when ( /Alfa Felis/i ) { return 'Alfa Felis','Alfa Felis' }
 
  default { return undef,undef }
  
 }
  
}

memoize ( 'umb' );

sub umb { 
 
 given ( $_[0] ) {
  
  when ( 'Alfa Felis' ) {
  
   int ( substr ( $_[1], 0, 4 ) ) < 2008 and return 'FIFe','FIFe';
     
   return 'TICA','TICA';
    
  }

  when ( 'SUVAK' ) {
   
   int ( substr ( $_[1], 0, 4) ) < 2008 and return 'other','muu';
     
   return 'FIFe','FIFe';
    
  }
  
  when ( 'FINTICAt' ) { return 'TICA','TICA' }
   
  when ( 'CFF' ) { return 'CFA','CFA' }
  
  when ( [ 'InCat','SUROK','TUROK','PIROK','RuRok','POROK','ISROK','KES-KIS',
   'POH-KIS','ERY-SYD','URK','SUVAK','SRK'] )
   { return 'FIFe','FIFe' }
 
  default { return 'other','muu' }
 
 }
   
}

sub tolines { map { trim( $_ ) } split /\n/, trim ( $_[0] ) }

sub topiles { map { trim( $_ ) } split /\#/, trim ( $_[0] ) }

1; 