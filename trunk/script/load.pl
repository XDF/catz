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

use 5.10.0; use strict; use warnings;

use lib '../lib'; use lib '../libi';

use File::Path qw( remove_tree );

use Catz::Core::Conf;

use Catz::Load::Loader;
use Catz::Load::Parse;
use Catz::Load::Data qw ( topiles );

use Catz::Util::File qw ( 
 dnafolder filecopy fileread finddirs filewrite findlatest pathcut 
);
use Catz::Util::Log qw ( logclose logopen logit );
use Catz::Util::String qw ( dna );
use Catz::Util::Time qw ( dt dtexpand dtlang );

$| = 1; # unbuffered printing

# store the beginning timestamp to be able to 
# calculate  total exectution time in secods
my $btime = time(); 

my $dt = dt(); # the run is identified by YYYYMMSSHHMMSS

logopen ( "../log/$dt.log" );

logit ( 'catz loader started at ' . dtexpand ( $dt ).' (dt '.$dt.')' );

my $changes = 0; # flag that should be turned on if something has changed

my $loaded = {}; # to store names of loaded folders and albums

my $olddb = findlatest ( '../db', 'db' );

defined $olddb or die "old database lookup failed";

my $db = "../db/$dt.db";

logit ( "copying database '$olddb' to '$db'" );

filecopy ( $olddb, $db );

load_begin ( $dt, $db );

my %guide = ();

foreach my $arg ( map { lc $_ } @ARGV ) { $guide{$arg} = 1 }

scalar @ARGV == 0 and do {
 $guide{'folder'} = 1; 
 $guide{'meta'} = 1;
 $guide{'post'} = 1;
};

# phase 1: load folders

$guide{'folder'} or goto SKIP_FOLDER;

my @folders =  
 grep { /\d{8}[a-z0-9]+$/ } finddirs ( '../../file/photo' );

logit ( 'verifying ' . scalar ( @folders ) . ' folders' );

foreach my $folder ( @folders ) {

 my $dna = dnafolder ( $folder );
 
 my $album = pathcut ( $folder );
 
 if ( load_nomatch ( 'folder', $album, $dna ) ) { # loading required
 
  $changes++;

  load_folder ( $folder );
  
  $loaded->{ $album } = 1;  
 
 }
}

SKIP_FOLDER:

# phase 2: load files

$guide{'meta'} or goto SKIP_META;

my @metafiles =  qw ( 
 metaexif metanews metanat metabreed metabreeder metafeat metatitle metacore
);

logit ( 'verifying ' . scalar @metafiles  . ' files' );

foreach my $head ( @metafiles ) {

 my $file =  $head . '.txt'; # meta files extension is txt
 
 my $full = "../data/$file";
  
 my $data = fileread ( $full );
 
 my $dna = dna ( $data );
 
 if ( load_nomatch ( 'file', $head, $dna ) ) { # loading required
  
  $changes++; 
 
  if ( $head eq 'metacore' ) { # complex loading
  
   # reverse makes the oldest gallery to load first and get the smallest S
   foreach my $pile ( reverse topiles ( $data ) ) {  
   
    if ( $pile =~ /^(\!.+?\n)?(20\d{6}[a-z]+\d{0,1})\n/g ) {
    
     # cat show gallery    
    
     my $album = $2;
     
     my $dnaa = dna ( $pile ); 
    
     if ( load_nomatch ( 'album', $album, $dnaa ) ) { # loading required
      
      load_complex ( $album, $pile );
        
      $loaded->{ $album } = 1;  
    
     } 

    }
    
   }
      
  } else { # simple loading
  
   my $table;
 
   $file =~ /^meta(.+)\./;
  
   $1 or die "unable to convert file name '$_[0]' to table name";
    
   $table = "m$1" ;
      
   if ( $table eq 'mexif' ) {
  
    load_exif ( $table, $data );
    
   } else {
   
    load_simple ( $table, $data );
    
   }
  
  }
  
 }
 
}

SKIP_META:

# phase 3: postprocessing

$guide{'post'} or goto SKIP_POST;

load_post;

SKIP_POST:

load_end; # finish

my $etime = time();

logit ( 'catz loader finished at ' .  dtlang() . ' (' . ( $etime - $btime ) . ' seconds)' );

logclose();

