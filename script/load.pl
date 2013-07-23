#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2013 Heikki Siltala
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

use 5.16.2;
use strict;
use warnings;

use lib '../lib';

use Const::Fast;

use Catz::Data::Conf;
use Catz::Load::Check;
use Catz::Load::Loader;
use Catz::Load::Parse;

use Catz::Util::File qw (
 dnafolder filecopy fileread finddirs filewrite findlatest pathcut
);
use Catz::Util::Log qw ( logclose logopen logit );
use Catz::Util::String qw ( dna tolines topiles topilex );
use Catz::Util::Time qw ( dt dtexpand dtlang );

$| = 1;    # unbuffered printing

# store the beginning timestamp to be able to
# calculate  total exectution time in secods
my $btime = time ();

my $dt = dt ();    # the run is identified by YYYYMMSSHHMMSS

logopen ( "../log/$dt.log" );

logit ( 'catz loader started at ' . dtexpand ( $dt ) . ' (dt ' . $dt . ')' );

my $changes = 0;    # flag that should be turned on if something has changed

my $loaded = {};    # to store names of loaded folders and albums

const my $OLDDB => findlatest ( '../db', 'db' );

defined $OLDDB or die "old database lookup failed";

const my $DB => "../db/$dt.db";

logit ( "copying database '$OLDDB' to '$DB'" );

filecopy ( $OLDDB, $DB );

my %guide = ();     # contains the features requested

foreach my $arg ( map { lc $_ } @ARGV ) {
 $guide{ $arg } = 1;
}

scalar @ARGV == 0 and do { $guide{ $_ } = 1 }
 foreach ( qw ( folder meta post check ) );

( $guide{ 'folder' } or $guide{ 'meta' } or $guide{ 'post' } )
 or goto NO_LOAD;

load_begin ( $dt, $DB );

# phase 1: load folders

$guide{ 'folder' } or goto SKIP_FOLDER;

my @folders =
 grep { /\d{8}[a-z0-9]+$/ } finddirs ( '../../static/photo' );

logit ( 'verifying ' . scalar ( @folders ) . ' folders' );

foreach my $folder ( @folders ) {

 my $dna = dnafolder ( $folder );

 my $album = pathcut ( $folder );

 if ( load_nomatch ( 'folder', $album, $dna ) ) {    # loading required

  $changes++;

  load_folder ( $folder );

  $loaded->{ $album } = 1;

 }
}

SKIP_FOLDER:

# phase 2: load files

$guide{ 'meta' } or goto SKIP_META;

my @metafiles = qw (
 metaexif metanews metaskip metanat metacate metabreed
 metabreeder metafeat metatitle metacore
);

logit ( 'verifying ' . scalar @metafiles . ' files' );

foreach my $head ( @metafiles ) {

 my $file = $head . '.txt';    # meta files extension is txt

 my $full = "../data/$file";

 my $data = fileread ( $full );

 my $dna = dna ( $data );

 if ( load_nomatch ( 'file', $head, $dna ) ) {    # loading required

  $changes++;

  if ( $head eq 'metacore' ) {                    # complex loading

   foreach my $pile ( topilex ( $data ) ) {
   
    # 2012-11-22: quite nasty but must get rid of comment lines
    my $pile = join "\n", tolines ( $pile ); 

    $pile =~ /^\>{3}\s+(20\d{6}[a-z]+\d{0,1})\n/g
     or die "malformed album beginning";

    my $album = $1;

    my $dnaa = dna ( $pile );

    if ( load_nomatch ( 'album', $album, $dnaa ) ) {    # loading required

     load_complex ( $album, $pile );

     $loaded->{ $album } = 1;

    }

   }

  } ## end if ( $head eq 'metacore')
  else {                                                # simple loading

   my $table;

   $file =~ /^meta(.+)\./;

   $1 or die "unable to convert file name '$_[0]' to table name";

   $table = "m$1";

   if ( $table eq 'mexif' ) {

    load_exif ( $table, $data );

   }
   else {

    load_simple ( $table, $data );

   }

  } ## end else [ if ( $head eq 'metacore')]

 } ## end if ( load_nomatch ( 'file'...))

} ## end foreach my $head ( @metafiles)

SKIP_META:

# phase 3: postprocessing

$guide{ 'post' } or goto SKIP_POST;

load_post;

SKIP_POST:

load_end;    # finish

NO_LOAD:

$guide{ 'check' } or goto SKIP_CHECK;

$dt = check_begin ( $DB );

logit "running data checks";

check_any ( 'subject_case' );
check_any ( 'subject_approx_1' );
check_any ( 'subject_approx_2' );
check_any ( 'breed_exists' );
check_any ( 'feature_exists' );
check_any ( 'title_exists' );
check_any ( 'nation_core_exists' );
check_any ( 'nation_breeder_exists' );
check_any ( 'breeder_nation' );

check_end;

SKIP_CHECK:

my $etime = time ();

logit ( 'catz loader finished at '
  . dtlang () . ' ('
  . ( $etime - $btime )
  . ' seconds)' );

logclose ();
