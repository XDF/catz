#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2014 Heikki Siltala
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

use 5.16.2;
use strict;
use warnings;
no warnings 'experimental';

use base 'Exporter';

our @EXPORT_OK = qw(
 body exifsort exif exid expmacro exptext fixgap lens loc org
 plaincat textchoose textremove toalbums umb
);

use Const::Fast;
use Memoize;

use Catz::Data::Conf;

use Catz::Util::File qw ( filenum );
use Catz::Util::Image qw ( imageinfo );
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

   return sprintf ( "%04d", $1 . $2 );

  }

  when ( 'etime' ) {

   $val =~ /^(.+) s$/;

   defined $1 or die "malformed exif '$key' '$val'";

   my $res = eval ( $1 );    ## no critic

   # works up to 999 seconds of exposure time due to
   # 1) padding length
   # 2) behavior with sprintf (negative sign appears)
   $res > 200 and die "etime processing doesn't support value '$res'";

   return sprintf ( "%010d", ( $res * 10_000_000 ) );

  }

  when ( 'iso' ) {

   $val =~ /^ISO (\d+)$/;

   defined $1 or die "malformed exif '$key' '$val'";

   return sprintf ( "%06d", $1 );

  }

  when ( 'flen' ) {

   $val =~ /^(\d+) mm$/;

   defined $1 or die "malformed exif '$key' '$val'";

   return sprintf ( "%04d", $1 );

  }

  when ( [ qw ( lens body dt ) ] ) { return $val }

  default { die "unable to make sorter for exif key '$key'" }

 } ## end given

} ## end sub exifsort

memoize ( 'exptext' );

sub exptext {

 my ( $text, $lang ) = @_;

 if ( $lang eq 'fi' ) {

  $text =~ s/\"(.+?)\|(.+?)\"/$2/g;    # dual lang, use second version

 }
 else {

  $text =~ s/\"(.+?)\|(.+?)\"/$1/g;    # dual lang, use first version

 }

 $text =~ s/\"(.+?)\"/$1/g;            # single lang

 $text =~ s/\{(.+)\}/$1/g;             # also remove breeder markers

 $text =~ s/\$/\"/g;                   # convert $ to "
 $text =~ s/\~//g;                     # remove null characters ~

 $text =~ s/FIFE/FIFe/g;

 return $text;

} ## end sub exptext

const my $MACRO => {
 front  => "\"(front)|(edessä)\"",
 back   => "\"(back)|(takana)\"",
 bottom => "\"(bottom)|(alimpana)\"",
 top    => "\"(top)|(ylimpänä)\"",
 middle => "\"(middle)|(keskellä)\"",
 center => "\"(middle)|(keskellä)\"",
 left   => "\"(left)|(vasemmalla)\"",
 right  => "\"(right)|(oikealla)\"",
 floor  => "\"(floor)|(lattialla)\"",
 bonus  => "\"bonus photo|bonuskuva\"",
 view   => "\"view over the show site|yleiskuvaa näyttelypaikalta\"",
 panel  => "\"the panel|paneeli\"",
 del    => "\"this photo has been deleted|tämä kuva on poistettu\""
};

memoize ( 'macro' );

sub macro {

 my ( $type, $key ) = @_;

 given ( $type ) {

  when ( 'A' ) {    # age

   my $en = $key;
   my $fi = $key;

   $fi =~ tr/\./\,/;    # in Finnish use commas
   $en =~ tr/\,/\./;    # in English use dots

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

   return qq("at the age of $en|ikä $fi");

  } ## end when ( 'A' )

  when ( 'B' ) {    # born

   $key =~ /^\d{8}$/ or die "illegal date in born macro '$key'";

   my $en = dtexpand ( $key, 'en' );
   my $fi = dtexpand ( $key, 'fi' );

   return qq("born $en|syntynyt $fi");

  }

  when ( 'F' ) { return qq("female|naaras") }

  when ( 'M' ) { return qq("male|uros") }

  when ( 'W' ) {

   my $en = $key;
   $en =~ tr/,/./;
   my $fi = $key;
   $fi =~ tr/./,/;

   return qq("weight $en kg|paino $en kg");

  }

  when ( [ qw ( P X ) ] ) {    # position, general

   $MACRO->{ $key } or die "unknow macro key '$key'";

   return $MACRO->{ $key };

  }

  default { die "unknow macro type $type" }

 } ## end given

} ## end sub macro

memoize ( 'expmacro' );

sub expmacro {

 my $text = shift;

 while ( $text =~ /(^| )(\%([A-Z])(\S*))/ ) {

  # it is imporatant to check that macro starts with the beginning of
  # data or with a space since % encoding may appear in hyperlinks

  my $from = $2;
  my $type = $3;
  my $key  = $4;

  my $to = macro ( $type, $key );

  $text =~ s/$from/$to/g;

 }

 return $text;

} ## end sub expmacro

memoize ( 'plaincat' );

sub plaincat {

 # removes all freetext parts -> just cat data is left

 my $text = shift;

 $text =~ s/\".+?\"//g;

 return trim ( clean ( $text ) );

}

# lenses' internal techical names and the corresponding visible names
const my $LENSNAME => {
 'lbc'           => 'Lensbaby Composer',
 'lbc_dg'        => 'Lensbaby Composer & Double Glass Optic',
 'lbc_sg'        => 'Lensbaby Composer & Single Glass Optic',
 'lbc_sf'        => 'Lensbaby Composer & Soft Focus Optic',
 'peleng8'       => 'Peleng 8mm f/3.5 Fisheye',
 'jupiter85'     => 'MC Jupiter-9 85mm f/2.0',
 'jupiter135'    => 'Jupiter-37AM 135mm f/3.5',
 'tokina17'      => 'Tokina 17mm f/3.5 AT-X Pro',
 'tamron2875'    => 'Tamron SP AF 28-75mm f/2.8 XR Di LD',
 'canon50ii'     => 'Canon EF 50mm f/1.8 II',
 'canon50usm'    => 'Canon EF 50mm f/1.4 USM',
 'canon85usm'    => 'Canon EF 85mm f/1.8 USM',
 'sigma70300'    => 'Sigma 70-300mm f/4-5.6 APO Macro Super II',
 'rubinar500'    => 'MC Rubinar 500mm f/8 Reflex',
 'canon28'       => 'Canon EF 28mm f/2.8',
 'canon1855'     => 'Canon EF-S 18-55mm f/3.5-5.6',
 'canon70200l'   => 'Canon EF 70-200mm f/2.8L IS USM',
 'canon50ii+2x'  => 'Canon EF 50mm f/1.8 II & Tamron 2X MC7 C-AF1 BBAR',
 'canon85usm+2x' => 'Canon EF 85mm f/1.8 USM & Tamron 2X MC7 C-AF1 BBAR',
 'samyang8'      => 'Samyang 8mm f/3.5 Aspherical IF MC Fisheye',
 'sigma10'       => 'Sigma 10mm f/2.8 EX DC HSM Fisheye',
 'sigma15'       => 'Sigma 15mm f/2.8 EX DG Fisheye', 
 'sigma28'       => 'Sigma 28mm f/1.8 EX DG',
 'sigma30'       => 'Sigma 30mm f/1.4 EX DC HSM',
 'sigma50'       => 'Sigma 50mm f/1.4 EX DG HSM',
 'sigma85'       => 'Sigma 85mm f/1.4 EX DG HSM',
 'canon100l'     => 'Canon EF 100mm f/2.8 L Macro IS USM',
 'canon135l'     => 'Canon EF 135mm f/2.0 L USM',
 'canon200l'     => 'Canon EF 200mm f/2.8 L II USM',
 'lx3leica'      => 'Leica DC Vario-Summicron 5.1-12.8mm f/2.0-2.8',
 'lx7leica'      => 'Leica DC Vario-Summilux 4.7-17.7mm f/1.4-2.3', 
 'dmwlw64' => 'Leica DC Vario-Summicron 5.1-12.8mm f/2.0-2.8 & DMW-LW46',
 'nytech_nd4020' => 'Nytech ND-4020 Lens',
 'fujixs1' => 'Fujinon Super EBC 6.1-158.6mm f/2.8-5.6',
 'nokiae7' => 'Nokia E7 Lens',
 'ricohgr' => 'Ricoh GR 18.3mm f/2.8',
};

memoize ( 'lens' );

sub lens {

 my ( $album, $flen, $fnum ) = @_;

 ( $flen and $fnum ) or return undef;    ## no critic

 my $date = substr ( $album, 0, 8 );     # use only date part

 $flen =~ s/ mm$//g;                     # remove ' mm'
 $fnum =~ s/f\///;                       # remove 'f/'

 my $lens;

 given ( $flen ) {

  when ( 15 ) { 

   if ( int($date) > 20130801 ) {
  
    $lens = 'sigma15';
    
   } else { 
   
    continue; # allow previous rules for 15 mm to execute
   
   }  
   
  }
  when ( 17 ) { $lens = 'tokina17' }
  when ( 18 ) {
  
   if ( int($date) > 20130601 and int($date) < 20131101 ) {
  
    $lens = 'ricohgr';
    
   } elsif ( int($date) > 20131101 ) {
   
    $lens = 'lx7leica';
     
   }
  
  }
  when ( 28 ) { $lens = 'sigma28' }
  when ( 50 ) {

   $lens = 'sigma50';

   $date eq '20110828' and $lens = 'canon50usm';

  }
  when ( 85 )  { $lens = 'sigma85' }
  when ( 100 ) { $lens = 'canon100l' }
  when ( 135 ) { $lens = 'canon135l' }
  when ( 200 ) { $lens = 'canon200l' }

  default {

   if ( int($date) > 20131101 ) {
   
    if ( $flen < 18 and $flen > 4 ) {
       $lens = 'lx7leica';
    } else {
     die "unable to resolve lens '$date' '$flen' '$fnum'";
    }

   } else {
   
    if ( $flen < 17 ) {
     if ( $flen < 5 ) {
      $lens = 'dmwlw64';
     }
     else {
      $lens = 'lx3leica';
     }
    } else {
    die "unable to resolve lens '$date' '$flen' '$fnum'";
   }
  
  }
  
 }
  

 } ## end given

 return $lens;

} ## end sub lens

memoize ( 'body' );

sub body {

 $_ = $_[ 0 ];

 m|ND\-4020| and return 'Nytech ND-4020';

 m| 300D| and return 'Canon EOS 300D';

 m|EOS 20D| and return 'Canon EOS 20D';

 m|EOS 40D| and return 'Canon EOS 40D';
 
 m|Mark III| and return 'Canon EOS 1D Mark III';
 
 m|EOS 6D| and return 'Canon EOS 6D';

 m|DMC\-LX3| and return 'Panasonic Lumix DMC-LX3';

 m|DMC\-LX7| and return 'Panasonic Lumix DMC-LX7';
 
 m|X\-S1| and return 'Fujifilm X-S1';
 
 m|E7\-| and return "Nokia E7";
 
 m|GR| and return "Ricoh GR";

 return undef;    ## no critic

}

const my $LENSFLEN => {
 'lbc'           => '50 mm' ,
 'lbc_dg'        => '50 mm' ,
 'lbc_sg'        => '50 mm' ,
 'lbc_sf'        => '50 mm' ,
 'peleng8'       => '8 mm'  ,
 'jupiter85'     => '85 mm' ,
 'jupiter135'    => '135 mm',
 'tokina17'      => '17 mm' ,
 'canon50ii'     => '50 mm' ,
 'canon50usm'    => '50 mm' ,
 'canon85usm'    => '85 mm' ,
 'rubinar500'    => '500 mm',
 'canon28'       => '28 mm' ,
 'canon50ii+2x'  => '100 mm',
 'canon85usm+2x' => '170 mm',
 'samyang8'      => '8 mm'  ,
 'sigma28'       => '28 mm' ,
 'sigma30'       => '30 mm' ,
 'sigma10'       => '10 mm' ,
 'sigma50'       => '50 mm' ,
 'sigma85'       => '85 mm' ,
 'sigma15'       => '15 mm' ,
 'canon100l'     => '100 mm',
 'canon135l'     => '135 mm',
 'canon200l'     => '200 mm',
 'ricohgr'       => '18 mm' ,
};

sub exid {

 my @parts = split /,/, $_[ 0 ];

 my $o = {};

 # technical lens name must be the first part
 my $lens = shift @parts;

 # other parts may vary
 foreach my $part ( @parts ) {

  my ( $key, $val ) = split /=/, $part;

  given ( $key ) {

   when ( /^exif_focal_/ ) {

    $val =~ /^(\d+)/;

    defined $1 or die "illegal focal length '$val'";

    $val = round ( $1, 0 );

    $o->{ flen } = "$val mm";

   }

   when ( /^exif_f_/ ) {

    # if needed adds '.0' to the end
    # accepts f number both with and without 'f/'

    $val =~ /\.\d$/ or $val = "$val.0";

    if ( substr ( $val, 0, 2 ) eq 'f/' ) {

     $o->{ fnum } = $val;

    }
    else {

     $o->{ fnum } = "f/$val";

    }

   }

   when ( /^exif_exposure_t/ ) {

    $val =~ / s$/ or $val = "$val s";

    $o->{ etime } = $val;

   }

   when ( /^exif_iso/ ) {

    substr ( $val, 0, 4 ) eq 'ISO ' or $val = "ISO $val";

    $o->{ iso } = $val;

   }

   when ( /^exif_camera_mo/ ) { $o->{ body } = $val }

   when ( /^exif_flash_/ ) { }    # skip this, this is deprecated

   default { die "unable to process $key at '$_[0]'" }

  } ## end given

 } ## end foreach my $part ( @parts )

 $lens and exists $LENSFLEN->{ $lens } and do {
  $o->{ flen } = $LENSFLEN->{ $lens };
 };

 if ( $lens and exists $LENSNAME->{ $lens } ) {
  $o->{ lens } = $LENSNAME->{ $lens };
 }
 else {
  die "lens '$lens' is giving trouble at line '$_[0]'";
 }

 return $o;

} ## end sub exid

sub exif {

 my ( $album, $file ) = @_;

 my $i = imageinfo ( $file );

 my $o = {};

 foreach my $key ( keys %{ $i } ) {

  given ( $key ) {

   when ( 'FocalLength' ) {

    $i->{ $key } =~ s/ mm$//;

    # filter out unknown focal lengths reported by the body as 0 or 0.0
    $i->{ $key } ne '0'
     and $i->{ $key } ne '0.0'
     and $o->{ flen } = round ( $i->{ $key }, 0 ) . ' mm';

   }

   when ( 'ExposureTime' ) { $o->{ etime } = $i->{ $key } . ' s' }

   when ( 'FNumber' ) {

    # filter out unknown aperture values reported by the body as 0 or 0.0
    $i->{ $key } ne '0'
     and $i->{ $key } ne '0.0'
     and $o->{ fnum } = 'f/'
     . $i->{ $key }

   }

   when ( 'CreateDate' ) {

    $i->{ $key } =~ /(\d\d\d\d).(\d\d).(\d\d) (\d\d).(\d\d).(\d\d)/;
    
    ( 
     defined $1 and 
     defined $2 and
     defined $3 and
     defined $4 and
     defined $5 and 
     defined $6 
    ) or die "unable to deassemble exif CreateDate '$i->{ $key }'";
    
    my $fixit = int ( $4 );
    
    # fix hack 2012-04-21, add one hour
    $album eq '20120414kuopio' and $fixit += 1;
    
    # make sure it has two digits
    $fixit < 10 and $fixit = "0$fixit";

    $o->{ dt } = "$1$2$3$fixit$5$6";
    
    length ( $o->{dt} ) == 14 or die 
     "something went wrong in exit CreateDate conversion: '$o->{dt}'";

   }

   when ( 'ISO' ) { $o->{ iso } = 'ISO ' . $i->{ $key } }

   when ( 'Model' ) {

    body ( $i->{ $key } )
     or die "unable to resolve body name with '$i->{ $key }'";

    $o->{ body } = body ( $i->{ $key } );

   }

  } ## end given

 } ## end foreach my $key ( keys %{ $i...})

 # resolve lens only for albums 2011 and beyond
 int ( substr ( $album, 0, 4 ) ) > 2010 and do {

  if ( $o->{ flen } and $o->{ fnum } ) {

   $o->{ lens } = lens ( $album, $o->{ flen }, $o->{ fnum } );

   $o->{ lens } and ( exists $LENSFLEN->{ $o->{ lens } } ) and do {
    $o->{ flen } = $LENSFLEN->{ $o->{ lens } };
   };

   if ( $o->{ lens } and ( exists $LENSNAME->{ $o->{ lens } } ) ) {
    $o->{ lens } = $LENSNAME->{ $o->{ lens } };
   }
   else {
    die "lens '" . $o->{ lens } . "' is giving trouble at file '$file'";
   }

  }

 };

 return $o;

} ## end sub exif

sub fixgap {

 # should locate the gap (9999 to 0000 ) in photo file numbers
 # and reorder the photos to the correct logical order

 my @photos = @_;

 my $prevnum = undef;

 foreach my $i ( 0 .. $#photos ) {

  my $filenum = filenum ( $photos[ $i ] );

  if ( defined $prevnum ) {

   if ( int ( $filenum ) > ( int ( $prevnum ) + 7000 ) ) {    # gap detected

    my @arr = ();    # new modified array

    # the first part ...
    foreach my $j ( $i .. $#photos ) { push @arr, $photos[ $j ] }

    # ... and the second part
    foreach my $j ( 0 .. $i - 1 ) { push @arr, $photos[ $j ] }

    return @arr;     # return the modified array

   }

  }

  $prevnum = $filenum;

 } ## end foreach my $i ( 0 .. $#photos)

 return @photos;     # return the original array if reached the end

} ## end sub fixgap

const my $LOCS => {
 myrskyla    => 'myrskylä',
 hyvinkaa    => 'hyvinkää',
 jamsa       => 'jämsä',
 palkane     => 'pälkäne',
 hameenlinna => 'hämeenlinna',
 jyvaskyla   => 'jyväskylä',
 seinajoki   => 'seinäjoki',
 jarvenpaa   => 'järvenpää',
 siilinjarvi => 'siilinjärvi',
 riihimaki   => 'riihimäki',
 kemio       => 'kemiö'
};

memoize ( 'loc' );

sub loc {

 my $loc = shift;

 exists $LOCS->{ $loc } and $loc = $LOCS->{ $loc };

 return ucclcc ( $loc ), ucclcc ( $loc );

}

memoize ( 'org' );

sub org {

 given ( shift ) {

  when ( /cornish rex/i ) {
   return 'Cornish Rex Association', 'Cornish Rex -yhdistys'
  }

  when ( /norwegian forest cat/i ) {
   return 'Norwegian Forest Cat Association',
    'Norjalainen Metsäkissa -yhdistys'
  }

  when ( /american curl/i ) {
   return 'American Curl Association', 'American Curl -yhdistys'
  }

  when ( /manxrengas/i ) { return 'Manx Association', 'Manxrengas' }

  when ( /maine coon/i ) {
   return 'Maine Coon Association', 'Maine Coon -yhdistys'
  }

  when ( /korat cat/i ) { return 'Korat Association', 'Korat-yhdistys' }

  when ( /cats of tuuri/i ) {
   return 'The Sacred Birmans in Finland', 'Pyhä Birman Kissa -yhdistys'
  }

  when ( /InCat/ ) { return 'InCat', 'InCat' }

  when ( /SUROK/ ) { return 'SUROK', 'SUROK' }

  when ( /TUROK/ ) { return 'TUROK', 'TUROK' }

  when ( /PIROK/ ) { return 'PIROK', 'PIROK' }

  when ( /RuRok/ ) { return 'RuRok', 'RuRok' }

  when ( /POROK/ ) { return 'POROK', 'POROK' }

  when ( /ISROK/ ) { return 'ISROK', 'ISROK' }

  when ( /KES-KIS/ ) { return 'KES-KIS', 'KES-KIS' }

  when ( /POH-KIS/ ) { return 'POH-KIS', 'POH-KIS' }

  when ( /ERY-SYD/ ) { return 'ERY-SYD', 'ERY-SYD' }

  when ( /URK/ ) { return 'URK', 'URK' }

  when ( /SUVAK/ ) { return 'SUVAK', 'SUVAK' }

  when ( /SRK/ ) { return 'SRK', 'Kissaliitto' }

  when ( /CFF/ ) { return 'CFF', 'CFF' }

  when ( /FINTICAt/ ) { return 'FINTICAt', 'FINTICAt' }

  when ( /Alfa Felis/i ) { return 'Alfa Felis', 'Alfa Felis' }

  when ( /VANGORA/ ) { return 'VANGORA', 'VANGORA' }

  default { return undef, undef }    ## no critic

 } ## end given

} ## end sub org

memoize ( 'umb' );

sub umb {

 given ( $_[ 0 ] ) {

  when ( 'Alfa Felis' ) {

   int ( substr ( $_[ 1 ], 0, 4 ) ) < 2008 and return 'FIFe', 'FIFe';

   return 'TICA', 'TICA';

  }

  when ( 'SUVAK' ) {

   int ( substr ( $_[ 1 ], 0, 4 ) ) < 2008 and return 'other', 'muu';

   return 'FIFe', 'FIFe';

  }

  when ( 'FINTICAt' ) { return 'TICA', 'TICA' }

  when ( 'CFF' ) { return 'CFA', 'CFA' }

  when (
   [
    'InCat', 'SUROK',   'TUROK',   'PIROK',   'RuRok', 'POROK',
    'ISROK', 'KES-KIS', 'POH-KIS', 'ERY-SYD', 'URK',   'SUVAK',
    'SRK'
   ]
   )
  {
   return 'FIFe', 'FIFe'
  }

  default { return 'other', 'muu' }

 } ## end given

} ## end sub umb

1;
