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

package Catz::Util;

use strict;
use warnings;

use Digest::MD5 qw(md5_base64);
use Image::ExifTool qw(:Public);
use Image::Size;
use File::stat;
use Time::localtime;
use File::Copy;
use POSIX qw/floor ceil/;
use Number::Format;
use List::MoreUtils qw( lastval );
use URI::Escape::XS qw/uri_escape uri_unescape/;
use MIME::Base32 qw ( RFC );

use base 'Exporter';

our @EXPORT_OK = 
 qw( nobreak cutpath round float encode decode ucc lcc ucclcc trim folder_file expand_ts sys_ts sys_ts_lang filesize filenum finddirs copyfile findfiles finddb findphotos width_height thumbfile readfile dna folder_dna tnresize thisyear enurl deurl ); 

my $formatter_en = new Number::Format(-thousands_sep   => ',', -decimal_point   => '.' );
my $formatter_fi = new Number::Format(-thousands_sep   => ' ', -decimal_point   => ',' );

sub nobreak { 
 my $input = shift;
 $input =~ s/ /\&nbsp;/g;
 return $input; 
}

# rounds a float
# in: float, number of decimals (defaults to zero)
# out: rounded float
sub round { defined $_[0] ? sprintf "%.".(defined $_[1] ? $_[1] : 0 )."f", $_[0] : undef }

# converts x/y to float
# in: string in x/y form
# out: float
sub float { defined $_[0] ? ($_[0] =~ m|(\d+)/(\d+)|) ? (int($1)/int($2)) : $_[0] : undef }

# converts a short number to long 4 digit number
# in: short number
# out: four digit number
sub fullnum { sprintf("%04d", $_[0]) }

# converts a long number into shortest possible number
# in: long number
# out: shortest possible number
sub minnum { int($_[0]) }

sub filenum { $_[0] =~ m|....(\d\d\d\d)\.JPG$|; return $1; }

# cuts url so that only last folder and filename are returned
# in: long url 
# out: partial url
sub folder_file { $_[0] =~ m|^.+/(.+)/(.+?)$|; return $1, $2; }

sub table2file { return lc($_[0]).'.txt' };

# converts a srting to upper case
# manages also special chars
# in: string to convert to upper case
# out: string converted to upper case
sub ucc { $_ = $_[0]; tr|üåäö|ÜÅÄÖ|; uc }

# converts a srting to lower case
# manages also special chars
# in: string to convert to lower case
# out: string converted to lower case
sub lcc { $_ = $_[0]; tr|ÜÅÄÖ|üåäö|; lc }

# converts "string" to "String"
# manages also special chars
# in: string to convert
# out: converted string
sub ucclcc { ucc(substr($_[0],0,1)).lcc(substr($_[0],1,9999)) }

# trims all whitespace chars from string
# in: string to trim
# in: trimmed string
sub trim { $_ = $_[0]; s/^\s+//; s/\s+$//; return $_; }

sub copyfile {
 copy($_[0],$_[1]) or die "unable to copy $_[0] to $_[1]";
}

# returns MD5 checksum for a string (uppercase hex)
# in: string where to calculate the checksum
# out: checksum
sub dna { md5_base64($_[0]) }

#
# folder DNA is based on 
# * number of files in the folder
# * filenames of the files in the folder
# * size of each file
# * modification time of each file
# 
sub folder_dna {

 my $folder = $_[0];
 my $str = '';
 
 my @files = sort glob ($folder.'/*');
 
 $str = $str.scalar(@files);
 $str = $str.join '', map { $_.stat($_)->size.stat($_)->mtime } @files;

 return dna($str);
 
}

sub cutpath { $_[0] =~ /^.*\/(.+?)$/; defined $1 ? $1 : $_[0]; }

sub findfiles { sort grep { -f } glob($_[0].'/*') }

sub finddirs { sort grep { -d } glob($_[0].'/*') }

sub findphotos { 

 return sort { substr($a,-8,-3)<=>substr($b,-8,-3) } 
  grep { m|....\d\d\d\d\.JPG$| } grep { -f  } findfiles ($_[0]);
  
}

# reads a file into a string
# in: filename
# out: file contents as a string
sub readfile { # in: filename, out: data
 local $/=undef;
 open FILE, $_[0] or die "file open error when reading ".$_[0];
 my $data = <FILE>; close FILE; return $data;
}

# returns the file size
# in: filename
# out: filesize
sub filesize { -s $_[0] }

# convert image file name to thumbnail file name
# in: image file name
# out: thumbnail file name
sub thumbfile { substr($_[0],0,-4).'_LR.JPG' }

# an utility function called by encode
sub chrsolve { 
 ((($_[0]>47)&&($_[0]<58))||(($_[0]>64)&&($_[0]<91))||(($_[0]>96)&&($_[0]<123)))
  ? chr($_[0]) : ( ( $_[0]==32 ) ? '_' : ( '-'.sprintf("%03d",$_[0]) ))  
}
#memoize(chrsolve);

# converts a string to a form that has no special characters
# a-z,A-Z and digits are OK, everything else gets encoded
# an encoded character gets format "-xyz" where xyz is the ascii value
# an exception is space which becomes underscore
#
# in: string to be encoded
# out: string in the encoded form
#
# an encoded character gets format "-xyz" where xyz is the ascii value
#
# teXT'+-?1234 -> teXT-039-043-045-0631234
# bn=ch%--- -> bn-061ch-037-045-045-045
# This Ain't Jungle -> This_Ain-039t_Jungle
# A'rdnán Nau Mau's -> A-039rdn-225n_Nau_Mau-039s
#
sub encode { join '', map { chrsolve(ord($_)) } split //, $_[0] }
#memoize(encode);

#
# converts a string back from its unencoded form
#
# in: string to be decoded
# out: decoded string
#
# teXT-039-043-045-0631234 -> teXT'+-?1234
# bn-061ch-037-045-045-045 -> bn=ch%---
# This_Ain-039t_Jungle -> This Ain't Jungle
# A-039rdn-225n_Nau_Mau-039s -> A'rdnán Nau Mau's
#

sub decode { $_ = $_[0]; s|\-(\d\d\d)|chr($1)|ge; s|_| |g; return $_; }
#memoize(decode);

# expands timestamp from YYYYMMDD to YYYYMMDDHHMMSS into
# a language specific readable/printable form
#
# in: timestamp, language
# out: readable format
#
sub expand_ts { 
 $_[0] =~ m|^(\d\d\d\d)(\d\d)(\d\d)(\d\d)?(\d\d)?(\d\d)?$|;
 my $lang = defined $_[1] ? $_[1] : 'en';
 my $str = ( $lang eq 'fi' ? int($3).'.'.int($2).'.'.$1 : "$1-$2-$3" ); 
 do { $str = "$str $4" } if defined($4); # handle hours if present
 do { $str = "$str:$5" } if defined($5); # handle minutes if present
 do { $str = "$str:$6" } if defined($6); # handle seconds if present
 return $str;
}
#memoize(expand_ts);

# returns the systemp time in a timestamp format YYYYMMDDHHMMSS
sub sys_ts {
 my ($s, $mi, $h, $d, $mo, $y) = @{localtime(time)};
 $y += 1900; $mo += 1;
 return sprintf("%04d%02d%02d%02d%02d%02d",$y,$mo,$d,$h,$mi,$s); 
}

sub thisyear {

 my (undef, undef, undef, undef, undef, $y) = @{localtime(time)};
 
 return $y+1900;
 
}

sub sys_ts_lang { expand_ts(sys_ts,$_[0]) };

# get image width and height
# in: filename
# out: width, height
sub width_height { return imgsize($_[0]); }

sub fmt {
 
 # number formatting according the language
 
 if($_[1] eq 'fi') {
 
  return $formatter_fi->format_number($_[0]);
    
 } else {
 
  return $formatter_en->format_number($_[0]);
 
 } 
 
}

sub tnresize {

 round($_[2]/($_[0]/$_[1])) 

}

sub enurl { join '/', ( map { uri_escape( $_ ) } split /\//, $_[0] ) }

sub deurl { join '/', ( map { uri_unescape( $_ ) } split /\//, $_[0] ) }

# no longer needed 2011-02-23
# sub pid2pik { lc ( base32_encode( shift ) ) }
# sub pik2pid { base32_decode ( shift ) }

1;