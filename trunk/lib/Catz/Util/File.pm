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

package Catz::Util::File;

use 5.16.2;
use strict;
use warnings;

use File::Copy;
use File::Find;
use File::Slurp;
use File::stat;

use base 'Exporter';

our @EXPORT_OK = qw (
 dnafolder file2table filecopy filehead fileread fileremove filemove
 filenum filesize filethumb filewrite findfiles findfilesrec finddirs
 findlatest findkey findphotos pathcut filereadcond
);

use Catz::Util::String qw ( dna );

#
# calculates the DNA of a folder
#
# in: folder name
# out: DNA
#
# folder's DNA is based on
# * the number of files in the folder
# * the filenames of the files in the folder
# * the size of each file
# * the modification time of each file
#
sub dnafolder {

 my $folder = $_[ 0 ];

 my @files = sort glob ( $folder . '/*' );

 my $str = scalar ( @files );

 $str = $str .    # using File::stat
  join '|', map { $_ . stat ( $_ )->size . stat ( $_ )->mtime } @files;

 return dna ( $str );    # dna sub is at Catz::Util::String

}

sub filecopy {
 copy ( $_[ 0 ], $_[ 1 ] ) or die "unable to copy '$_[0]' to '$_[1]'";
}

sub filehead {

 $_[ 0 ] =~ /^.*\/(.+?)\....$/;

 $1 and return $1;

 die "unable to find filehead in filename '$_[0]'";

}

sub filemove {
 move ( $_[ 0 ], $_[ 1 ] ) or die "unable to rename '$_[0]' to '$_[1]'";
}

sub filenum {

 $_[ 0 ] =~ /(\d\d\d\d)\....$/;

 $1 and return $1;

 die "unable to find filenum in filename '$_[0]'";

}

#
# reads a file into a string
#
# in: filename
# out: file content as a string
#
sub fileread {

 my $data = read_file $_[0] or die "unable to read file '$_[0]'";

 return $data;

}

#
# reads a file if it exists
# added 2012-02
#
# in: filename
# out: file content as a string, undef if there was any kind of error
#
sub filereadcond {
 
 my $data = ( read_file ( $_[0], err_mode => 'quiet' ) ) // undef;

 return $data;

}


sub fileremove { unlink ( $_[ 0 ] ) or die "unable to remove '$_[0]'" }

sub filesize { -s $_[ 0 ] }

sub filethumb {

 $_[ 0 ] =~ /^(.+)\.(...)$/;

 ( $1 and $2 ) or die "unable to make filethumb from filename '$_[0]'";

 return "$1_LR.$2";

}

#
# write a file
#
# in: filename, data to write as a scalar
#
sub filewrite {

 write_file $_[0], $_[1] or "unable to write file '$_[0]'";

}

sub findfiles {
 sort grep { -f } glob ( $_[ 0 ] . '/* ' );
}

sub findfilesrec {

 my @dirs = @_;

 my @found = ();

 find (
  sub {
   push @found, $File::Find::name;
  },
  @dirs
 );

 return @found;

}

sub finddirs {
 sort grep { -d } glob ( $_[ 0 ] . '/*' );
}

#
# returns the name of the file having "the largest" file name
# if the file names are timestamps then the latest file is returned
#
# in: folder name, file extension
# out: "the largest" file = the latest file
#
sub findlatest {

 my @dbs = grep { -f } glob ( $_[ 0 ] . '/*.' . $_[ 1 ] );

 defined $dbs[ $#dbs ] ? $dbs[ $#dbs ] : undef;

}

sub findphotos {

 sort { substr ( $a, -8, -3 ) <=> substr ( $b, -8, -3 ) }
  grep { /.{4}\d{4}\.JPG$/ } grep { -f } findfiles ( $_[ 0 ] );

}

#
# removes path from a filename
#
sub pathcut { $_[ 0 ] =~ /^.*\/(.+?)$/; defined $1 ? $1 : $_[ 0 ]; }

1;
