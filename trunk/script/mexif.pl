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

die "This script is typically not run!";

use 5.12.0;
use strict;
use warnings;

use lib '../lib';

use File::Find;

use Catz::Util::Number qw ( minnum );
use Catz::Util::File qw ( fileread filewrite );

#
# a script to get exif data from current site's HTML pages
# for one-time use
#

my $output = '../data/metaexif.txt';

my $out = '';

find ( \&wanted, '/www/galleries' );

my $i = 0;

my %seen = ();

sub wanted {

 my $bare = $_;
 my $full = $File::Find::name;
 my $dir  = $File::Find::dir;

 -f $full and $full =~ /\/(\d{8}[a-z0-9]+)\/(\d{4}).html$/ and do {

  my $album = $1;

  $seen{ $album } or say "$album";

  $seen{ $album } = 1;

  my $n = minnum ( $2 );

  my $data = fileread ( $full );

  $i++;

  if ( $data =~ /(timestamp\/aikaleima.+?)\<\/font\>/ ) {

   if (
    $data =~ /timestamp\/aikaleima\: (....)-(..)-(..) (..)\:(..)\:(..)\,/ )
   {

    $out = $out . join "\n", ( $album, $n, 'dt', "$1$2$3$4$5$6", "#\n" );

   }

   if ( $data =~ /f\-number\/aukko\: (.+?)\,/ ) {

    $out = $out . join "\n", ( $album, $n, 'fnum', "f/$1", "#\n" );

   }

   if ( $data =~ /exposure time\/valotusaika\: (.+?)\,/ ) {

    $out = $out . join "\n", ( $album, $n, 'etime', $1, "#\n" );

   }

   if ( $data =~ /sensitivity\/herkkyys: (.+?)\,/ ) {

    $out = $out . join "\n", ( $album, $n, 'iso', $1, "#\n" );

   }

   if ( $data =~ /focal length\/polttov.li\: (.+?)\,/ ) {

    $out = $out . join "\n", ( $album, $n, 'flen', $1, "#\n" );

   }

   if ( $data =~ /lens\/objektiivi\: (<.+?>)?(.*?)\</ ) {

    defined $2 and length ( $2 ) > 0 and do {

     my $lens = $2;

     $lens =~ s|fisheye.kalansilm.|Fisheye|;

     $out = $out . join "\n", ( $album, $n, 'lens', $lens, "#\n" );

     }

   }

   if ( $data =~ /body\/runko\: (<.+?>)?(.*?)\</ ) {

    defined $2
     and length ( $2 ) > 0
     and $out = $out . join "\n", ( $album, $n, 'body', $2, "#\n" );

   }

  } ## end if ( $data =~ /(timestamp\/aikaleima.+?)\<\/font\>/)

 };

} ## end sub wanted

filewrite ( $output, $out );
