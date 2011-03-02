#
# The MIT License
# 
# Copyright (c) 2010-2011 Heikki Siltala
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

package Catz::Data;

use strict;
use warnings;

use Image::ExifTool qw(:Public);

use Switch;

use Catz::Util qw ( float filenum round trim ucclcc );

my %location = (
 myrskyla => 'myrskyl�',
 hyvinkaa => 'hyvink��',
 jamsa => 'j�ms�',
 palkane => 'p�lk�ne',
 hameenlinna => 'h�meenlinna',
 jyvaskyla => 'jyv�skyl�',
 seinajoki => 'sein�joki',
 jarvenpaa => 'j�rvenp��',
 siilinjarvi => 'siilinj�rvi',
 riihimaki => 'riihim�ki'
);


our %lensname = (
 'lbc' => 'Lensbaby Composer',
 'lbc_dg' => 'Lensbaby Composer & Dougle Glass Optic',
 'lbc_sg' => 'Lensbaby Composer & Single Glass Optic',
 'lbc_sf' => 'Lensbaby Composer & Soft Focus Optic',
 'peleng8' => 'Peleng 8mm f/3.5 Fisheye',
 'jupiter85' => 'MC Jupiter-9 85mm f/2.0',
 'jupiter135' => 'Jupiter-37AM 135mm f/3.5',
 'tokina17' => 'Tokina 17mm f/3.5 AT-X Pro',
 'tamron2875' => 'Tamron SP AF 28-75mm f/2.8 XR Di LD',
 'canon50ii' => 'Canon EF 50mm f/1.8 II',
 'canon50usm' => 'Canon EF 50mm f/1.4 USM',
 'canon85usm' => 'Canon EF 85mm f/1.8 USM',
 'sigma70300' => 'Sigma 70-300mm f/4-5.6 APO Macro Super II',
 'rubinar500' => 'MC Rubinar 500mm f/8 Reflex',
 'canon28' => 'Canon EF 28mm f/2.8',
 'canon1855' => 'Canon EF-S 18-55mm f/3.5-5.6',
 'canon70200l' => 'Canon EF 70-200mm f/2.8L IS USM', 
 'canon50ii+2x' => 'Canon EF 50mm f/1.8 II & Tamron 2X MC7 C-AF1 BBAR',
 'canon85usm+2x' => 'Canon EF 85mm f/1.8 USM & Tamron 2X MC7 C-AF1 BBAR',
 'sigma28' => 'Sigma 28mm f/1.8 EX DG',
 'sigma30' => 'Sigma 30mm f/1.4 EX DC HSM',
 'sigma10' => 'Sigma 10mm f/2.8 EX DC HSM Fisheye',
 'sigma50' => 'Sigma 50mm f/1.4 EX DG HSM',
 'canon135l' => 'Canon EF 135mm f/2.0 L USM',
 'canon200l' => 'Canon EF 200mm f/2.8 L II USM',
 'lx3leica' => 'Leica DC Vario-Summicron 5.1-12.8mm f/2.0-2.8',
 'dmwlw64' => 'Leica DC Vario-Summicron 5.1-12.8mm f/2.0-2.8 & DMW-LW46',
 'nytech_nd4020' => 'Nytech ND-4020 Lens'
);

our %lensflen = (
 'peleng8' => 8,
 'jupiter85' => 85,
 'jupiter135' => 135,
 'tokina17' => 17,
 'canon50ii' => 50,
 'canon50usm' => 50,
 'canon85usm' => 85,
 'rubinar500' => 500,
 'canon28' => 28, 
 'canon50ii+2x' => 100,
 'canon85usm+2x' => 170,
 'sigma28' => 28,
 'sigma30' => 30,
 'sigma10' => 10,
 'sigma50' => 50,
 'canon135l' => 135,
 'canon200l' => 200
);

our $lensurlhead = "/camera_lenses.htm";

our %lensurl = (
 'canon50ii+2x' => '/camera_lenses.htm#tamron2x',
 'canon85usm+2x' => '/camera_lenses.htm#tamron2x',
 'canon200l' =>  'http://www.mir.com.my/rb/photography/hardwares/classics/eos/EF-lenses/EF200mmf28LUSM/index1.htm',
 'lx3leica' => '/camera_bodies.htm#panasoniclx3',
 'dmwlw64' => '/camera_bodies.htm#panasoniclx3',
 'nytech' => '/nytech_nd4020_en.htm' 
);

our %macro_p = (
 front => "\"(front)|(edess�)\"",
 back => "\"(back)|(takana)\"",
 bottom => "\"(bottom)|(alimpana)\"",
 top => "\"(top)|(ylimp�n�)\"",
 middle => "\"(middle)|(keskell�)\"",
 center => "\"(middle)|(keskell�)\"",
 left => "\"(left)|(vasemmalla)\"",
 right => "\"(right)|(oikealla)\"",
 floor => "\"(floor)|(lattialla)\""
);

our %macro_x = (
 bonus => "\"bonus photo|bonuskuva\"",
 view => "\"view over the show site|yleiskuvaa n�yttelypaikalta\"",
 panel => "\"the panel|paneeli\""
);


sub location {

 my $loc = $_[0];
   
 $loc =~ s/\d$//; 

 defined $location{$loc} and $loc = $location{$loc};
 
 return ucclcc($loc),ucclcc($loc);
     
}


sub plain {

 # creates plain output in two languages
 
 my $data = $_[0];
 
 $data =~ s/\[(.+?)\]/$1/gs;
 $data =~ s/\{(.+?)\}/$1/gs;
 
 if($data =~ /^\"(.+)\|(.+)\"$/) {

  return $1,$2;  
 
 } elsif($data =~ /^\"(.+)\"$/) {
 
  return $1,$1;
 
 } else {
 
  return $data,$data;
 }
 
}

# get EMS code from cat data
sub ems {
 if($_[0] =~ m|\[([A-Z][A-Z][A-Z].*?)\]|) {
  return trim($1);
 } else {
  return '';
 } 
}

# get breeder name from cat data
sub breeder { 
 if($_[0] =~ m|\{(.+?)\}|) { 
  return $1; 
 } else { 
 return undef; 
 }
}

sub nick {  
 if($_[0] =~ /\((.+?)\)/) {
  my @arr = map { trim($_) } split /\,/, $1;
  return \@arr;
 } 
 return undef;  
}

# get country from cat data if any (pre* or *post)
sub nation {   
 if($_[0] =~ m|([A-Z]+)\*\{|) { return $1 } 
  elsif ($_[0] =~ m|\}\*([A-Z]+)|) { return $1 }
  else { return undef } 
}

# get cat name from cat data
sub cat {
 length(ems($_[0]))>2 or return undef; # no EMS = no cat name
 $_ = $_[0]; 
 s|\".+?\"||g; # remove free text
 s|\%[A-Z][\S]*||g; # remove macros
 s|[A-Z]+\*\{|\{|; #remove pre country code
 s|\}\*[A-Z]+|\}|; #remove post country code  
 s|\{(.+)\}|$1|; #remove breeder tag chars
 s|\((.+)\)||; #remove nick(s)
 s|^(.+)\s+\[[A-Z][A-Z][A-Z].+$|$1|; # get all before EMS 
 s|^.*?([A-Z][a-z].+$)|$1|; # remove titles 
 return trim($_);
}

sub get_breeders {
 my @arr = ( breeder($_[0]) );
 return \@arr;
}

sub get_cats {
 my @arr;
 $arr[0] = cat($_[0]);
 defined $arr[0] and return \@arr;
 return undef; 
}

sub get_ems1s {
 my $ems = ems($_[0]);
 length($ems)>4 or return undef;
 my @arr = split / /, substr($ems,4);
 scalar(@arr)<1 and return undef;
 my %hash = map { $_=>1 } map { trim($_) } @arr;
 @arr = keys %hash;
 return \@arr; 
}

sub get_ems3s {
 my @arr;
 my $ems = ems($_[0]);
 if(length($ems)>2) {
  @arr = substr($ems,0,3);
 } else {
  @arr = undef;  
 }
 return \@arr; 
}

sub get_ems4s {
 my $ems = ems($_[0]);
 if($ems =~ /^\w\w\w (.*)/) {
  my @arr; 
  $arr[0] = $1; 
  return \@arr;
 }
 return undef; 
}

sub get_ems5s {
 my @arr = ems($_[0]);
 return \@arr; 
}

sub get_nicks {
 length(ems($_[0]))>2 and return nick($_[0]);
 return undef; 
}

sub get_words {
 my %hash = map { $_=>1 } map { lcc($_); } split /\s+/, plain($_[0]);
 my @arr = grep { length($_)>2 && length($_)<51 } keys %hash;    
 return \@arr;
}

sub get_nations {
 my @arr = nation($_[0]);
 return \@arr; 
}

# resolves an age macro
sub expand_macro_a {
 my $k = $_[0]; my $f = $k; $f = s/\./\,/g; 
 $k=~ s/y/ years /; $k =~ s/m/ months /; 
 $k =~ s/w/ weeks /; $k =~ s/d/ days /; 
 $f =~ s/y/ vuotta /; $f =~ s/m/ kuukautta /;
 $f =~ s/w/ viikkoa /; $f =~ s/d/ p�iv�� /;
 return "\"at the age of $k|ik�: $f\"";  
}
# resolves a born macro
sub expand_macro_b {
 my $k = $_[0];
 length($k)==8 or die "illegal B macro key";
 return "\"born ".expand_ts($k,'en')."|syntynyt ". expand_ts($k,'fi')."\"";  
}

sub expand_macro_p {
 defined($macro_p{$_[0]}) or die "unknown P macro key $_[0]";
 return $macro_p{$_[0]};
}

sub expand_macro_w {
 my $str = "\"weight $_[0] kg|paino $_[0] kg\"";
 $str =~ s|(paino \d+?)\.(\d+? kg)|$1\,$2|;
 return $str;
}
sub expand_macro_x {
 defined($macro_x{$_[0]}) or die "unknown X macro key $_[0]";
 return $macro_x{$_[0]};
}

sub expand_gender {
 my $str = shift; 
 $str =~ s/ \%F/ \"female|naaras\"/g; $str =~ s/ \%M/ \"male|uros\"/g;
 return $str;
}

sub expand_freetext {
 my ($str,$lang) = @_;
 if($lang ne 'fi') {
  $str =~ s/\"(.+?)\|(.+?)\"/$1/g; # dual lang
 } else {
  $str =~ s/\"(.+?)\|(.+?)\"/$2/g; # dual lang
 }
 $str =~ s|\"(.+?)\"|$1|g; # single lang
 return $str;
}

# resolves a link
sub expand_link {
 $_ = shift;  s/\<(.+?)\|(.+?)\>/\<a href\=\"$1\"\>$2\<\/a\>/g; return $_;  
}

# general resolves
sub expand_common {  $_ = shift; s/FIFE/FIF�/g; return $_; } 

sub expand_phrase { 
# in: unexpanded phrase, lang, out: expanded phrase

 my($str,$lang) = @_;
 
 while($str =~ m((\%(A|B|P|W|X)(\S+)))) {
  my $c = $2; my $k = $3; my $what = $1; my $with;
  if($c eq 'A') { $with = expand_macro_a($k)
  } elsif($c eq 'B') { $with = expand_macro_b($k)
  } elsif($c eq 'P') { $with = expand_macro_p($k)
  } elsif($c eq 'W') { $with = expand_macro_w($k)
  } elsif($c eq 'X') { $with = expand_macro_x($k)
  } else { die "unable to resolve macro $what" }
  #print "$what->$with";
  $str =~ s/$what/$with/g;
 }
 
 $str = expand_gender($str);
 $str = expand_freetext($str,$lang);
 $str = expand_link($str);
 $str = expand_common($str);

 return $str;
 
}

# the lens resolving function
# please regard this legacy sub as a bad example of Perl programming 
# in: lens mode, focal length, aperture 
# out: lens code 
sub lens {
 my ( $mode, $flen, $fnum ) = @_;
 ( not defined $flen ) and $flen = 0;
 if ( $flen == 0 ) {
  if($mode eq "0017285085135") {
   return "lbc";
  } elsif(($mode eq "JENSE")||($mode eq "DJENSE")) {
   return "jupiter85";
  } else {
   return "peleng8";
  }
 } elsif ($flen==10) {
  return "sigma10";
 } elsif ($flen==17) {
  return "tokina17"; 
 } elsif ($flen==28) {
  if($mode eq "0017285085135") {
   return "sigma28";
  } elsif(($mode eq "NEW285085")||(($mode eq "70200L"))) {
   return "canon28";
  } elsif(($mode eq "TENSE")||($mode eq "DENSE")||($mode eq "DJENSE")||($mode eq "NEWSET")||($mode eq "DEWSET")) {
   return "tamron2875";
  } elsif($mode eq "LENSE") {
   if($fnum>=3.5) { return "canon1855"; } else { return "canon28"; }
  } else { return "canon28"; }
 } elsif ($flen==30) {
  if(($mode eq "1017305085135")||($mode eq "NEW285085")||(($mode eq "70200L"))) {
   return "sigma30";
  } elsif(($mode eq "TENSE")||($mode eq "DENSE")||($mode eq "DJENSE")||($mode eq "NEWSET")||($mode eq "DEWSET")) {
   return "tamron2875";
  } else { return "canon1855"; }
 }  elsif ($flen==50) {
  if($mode eq "0017285085135") { return "sigma50"; } 
   elsif($mode eq "1017305085135") { return "sigma50"; }
   elsif(($mode eq "NEW285085")||(($mode eq "70200L"))) { return "canon50usm"; } 
   elsif($mode eq "TENSE") { return "tamron2875"; } 
   elsif($mode eq "DEWSET") { return "canon50usm"; } 
   elsif($mode eq "NEWSET") {
    if($fnum>=2.8) { return "tamron2875"; } else { return "canon50usm"; } } 
   elsif(($mode eq "DENSE")||($mode eq "DJENSE")) {
    if($fnum>=2.8) { return "tamron2875"; } else { return "canon50ii"; } } 
   else { return "canon50ii"; }
 } else {
 
   my $lenss;
 
   if(($mode eq "0017285085135")||($mode eq "1017305085135")||($mode eq "NEW285085")||(($mode eq "70200L"))) {
     $lenss = "canon85usm";
   } elsif(($mode eq "NEWSET")||($mode eq "DEWSET")) {
    if(($flen>84)&&($flen<86)) { $lenss = "canon85usm"; } else { $lenss = "tamron2875"; }
   } elsif((($mode eq "TENSE")||($mode eq "DENSE")||($mode eq "DJENSE"))&&(round(float($2),0)>26)&&(round(float($2),0)<77)) {
    $lenss = "tamron2875";
   } else {
    if($flen>55) { $lenss = "sigma70300"; } else { $lenss = "canon1855"; }
   }
    
   if(($mode eq "70200L")&&($flen>69)&&($flen<201)&&($fnum>=2.8)) {
    $lenss = "canon70200l";
   }
       
   if((($mode eq "0017285085135")||($mode eq "1017305085135"))&&(($flen>134)&&($flen<136))) {
    $lenss = "canon135l";
   }
       
   if(($mode eq "0017285085135")&&($flen>199)&&($flen<201)) {
    $lenss = "canon200l";
   }
   
   #print $flen."\n";
       
   if((($mode eq "0017285085135")||($mode eq "1017305085135"))&&(($flen>5)&&($flen<12.9))&&(not($flen==10))) {
    $lenss = "lx3leica";
   }
       
   if(((($mode eq "0017285085135")||($mode eq "1017305085135")))&&(($flen>3.8)&&($flen<4.0))) {
    $lenss = "dmwlw64";
   }
   
   return $lenss;
   
  }
  
 return undef;
}

sub body {
  $_ = $_[0]; 
 (m|^Nytech|) and return 'Nytech ND-4020';
 (m| 300D|) and return 'Canon EOS 300D';
 (m|EOS 20D|) and return 'Canon EOS 20D';
 (m|EOS 40D|) and return 'Canon EOS 40D';
 (m|Mark III|) and return 'Canon EOS 1D Mark III';
 (m|DMC-LX3|) and return 'Panasonic Lumix DMC-LX3';
 return undef;
}

sub body_old {
  $_ = $_[0]; 
 (m|^Nytech|) && do { return 'Nytech ND-4020','/nytech_nd4020_en.htm'; };
 (m| 300D|) && do { return 'Canon EOS 300D','/camera_bodies.htm#canon300d'; };
 (m|EOS 20D|) && do { return 'Canon EOS 20D','/camera_bodies.htm#canon20d'; };
 (m|EOS 40D|) && do { return 'Canon EOS 40D', '/camera_bodies.htm#canon40d'; };
 (m|Mark III|) && do { return 'Canon EOS 1D Mark III','/camera_bodies.htm#canon1d3'; };
 (m|DMC-LX3|) && do { return 'Panasonic Lumix DMC-LX3','/camera_bodies.htm#panasoniclx3'; };
 return undef,undef;
}

sub convert_flash {

 my $input = $_[0];

 length($input)<1 and return 'false';
 $input =~ /not fire/ and return 'false';
 $input =~ /Fired/ and return 'true';
 $input eq 'no' and return 'false';
 $input =~ /^No/ and return 'false';
 $input eq 'yes' and return 'true';
 
 die "unable to handle exif flash information $input"; 

}

# internal conversion function
sub convert_exif_dt {
 $_[0] =~ /(\d\d\d\d).(\d\d).(\d\d) (\d\d).(\d\d).(\d\d)/; 
 return $1.$2.$3.$4.$5.$6;
}


# retrieves ja processes photo file exifs
# out: processed exifs as a hash 
sub exif {
 
 my ( $lensmode, $file ) = shift;
 
 my $exifs = ImageInfo($file); 
 
 my %output = ();
  
 foreach my $key ( keys %{ $exifs } ) {
 
   $_ = $$exifs{$key};
    
  ($key eq 'FocalLength') && do { s/ mm$//; $output{'flen'} = $_; };
  
  ($key eq 'ExposureTime') && do { 
    s/ s$//; $output{'etime_txt'} = $_; $output{'etime_num'} = float($_); 
   };
   
  ($key eq 'FNumber') && do { $output{'fnum'} = $_; };
    
  ($key eq 'CreateDate') && do { $output{'dt'} = convert_exif_dt($_) };
  
  ($key eq 'ISO') && do { $output{'iso'} = $_ };
  
  ($key eq 'Model') && do { $output{'body'} = body($_) };

 }
 
 $output{'lens'} = lens($lensmode,$output{'flen'},$output{'fnum'});
    
 if(defined($output{'lens'})) {

   if(defined($lensflen{$output{'lens'}})) {
    $output{'flen'} = $lensflen{$output{'lens'}};  
  }

  $output{'lens'} = $lensname{$output{'lens'}};
 
 }
     
 return \%output;
 
}

# processes exif data from galleriesmeta in classic format
# 
sub exid {

 my $estr = shift;
 
 my %output = ();
 
 my @exids = split /,/, $estr;
 
 $output{'lens'} = shift @exids;
 
 foreach my $exid (@exids) {
 
  my ($key,$value) = split /=/, $exid;
  
  $_ = $key;
    
  (m|^exif_focal_|) && do { $value =~ s/ mm$//; $output{'flen'} = $value; };
    
  (m|^exif_f_|) && do { $output{'fnum'} = $value; };
    
  (m|^exif_exposure_t|) && do {
    $value =~ s/ s$//; $output{'etime_txt'} = $value; $output{'etime_num'} = float($value); 
   };
    
  (m|^exif_iso|) && do { $value =~ s/^ISO //; $output{'iso'} = $value; };
    
  (m|^exif_camera_mod|) && do {
   $output{'body'} = body($value);
  };
  
 }
 
 my $lensname =  $lensname { $output{'lens'} };
 
 defined $lensname or die "unable to resolve lensname for ".$output{'lens'};
 
 $output{'lens'} = $lensname;
    
 return \%output;
}
 
sub fix_gap {

 my @photos = @_;

 my $prevnum = undef;
 
 foreach my $i ( 0 .. ( scalar ( @photos ) - 1 ) ) {
  my $filenum = filenum($photos[$i]);
  if(defined $prevnum) {
   if(int($filenum)>(int($prevnum)+5000)) {
    # gap detected
    my @arr = ();
    foreach my $j ($i..(scalar(@photos)-1)) {
     push @arr, $photos[$j];
    }
    foreach my $j (0..$i-1) { 
     push @arr, $photos[$j];
    }
    return @arr;
   }
  }
  $prevnum = $filenum;
 }
  
 return @photos; # return the original ref if reached the end 

}

sub each_gallery {
 my $data = $_[0];
 my @arr = map { trim($_) } split /\#/, join "\n", 
  grep { substr($_,0,1) ne '!' } split /\n/, $data;
 #print $arr[0]."\n"; 
 return \@arr;
}

sub organizer {
  $_ = $_[0];
 (m|cornish rex|i) && do 
  { return 'Norwegian Forest Cat Association','Norjalainen Mets�kissa -yhdistys'; };
 (m|norwegian forest cat|i) && do 
  { return 'Cornish Rex Association','Cornish Rex -yhdistys'; };
 (m|american curl|i) && do 
  { return 'American Curl Association','American Curl -yhdistys'; };
 (m|manxrengas|i) && do 
  { return 'Manx Association','Manxrengas'; };
 (m|maine coon|i) && do 
  { return 'Maine Coon Association','Maine Coon -yhdistys'; };
 (m|korat cat|i) && do 
  { return 'Korat Association','Korat-yhdistys'; };

 (m|InCat|) && do { return 'InCat','InCat'; };         
 (m|SUROK|) && do { return 'SUROK','SUROK'; };
 (m|TUROK|) && do { return 'TUROK','TUROK'; };
 (m|PIROK|) && do { return 'PIROK','PIROK'; };
 (m|RuRok|) && do { return 'RuRok','RuRok'; };
 (m|POROK|) && do { return 'POROK','POROK'; };
 (m|ISROK|) && do { return 'ISROK','ISROK'; };
 (m|KES-KIS|) && do { return 'KES-KIS','KES-KIS'; };
 (m|POH-KIS|) && do { return 'POH-KIS','POH-KIS'; };
 (m|ERY-SYD|) && do { return 'ERY-SYD','ERY-SYD'; };
 (m|URK|) && do { return 'URK','URK'; };
 (m|SUVAK|) && do { return 'SUVAK','SUVAK'; };
 (m|SRK|) && do { return 'SRK','Kissaliitto'; };
 (m|CFF|) && do { return 'CFF','CFF'; };
 (m|FINTICAt|) && do { return 'FINTICAt','FINTICAt'; };
 (m|Alfa Felis|i) && do { return 'Alfa Felis','Alfa Felis'; };
 
 
 return undef,undef;
}

sub umbrella {

 switch($_[0]) {
  
  case 'Alfa Felis' {
   int(substr($_[1],0,4))<2008 and return 'FIFe','FIFe'; 
   return 'TICA','TICA';
  }

  case 'SUVAK' {
   int(substr($_[1],0,4))<2008 and return 'other','muut'; 
   return 'FIFe','FIFe';
  }
  
  case 'FINTICAt' { return 'TICA','TICA' }
   
  case 'CFF' { return 'CFA','CFA' }
  
  case ['InCat','SUROK','TUROK','PIROK','RuRok','POROK','ISROK','KES-KIS','POH-KIS','ERY-SYD','URK','SUVAK','SRK']
  { return 'FIFe','FIFe' }
 
  else {
   return 'other','muut'
  }
 } 
}

sub country { defined $_[0] ? 'FI' : undef }

sub line2snips { 
           #map { s|\&\&|\&|g } 
 my @arr = map { trim( $_ ) } split / & /, $_[0];
 
 return \@arr;
  
}
