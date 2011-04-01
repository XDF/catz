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

use strict;
use warnings;

use lib '../lib';

use feature qw ( say );

use Catz::Data::Conf;
use Catz::Data::Load;
use Catz::Data::Parse;
use Catz::Util::Data qw ( topiles );
use Catz::Util::File qw ( 
 dnafolder filecopy fileread finddirs filewrite findlatest pathcut 
);
use Catz::Util::Log qw ( logclose logopen logit );
use Catz::Util::String qw ( dna );
use Catz::Util::Time qw ( dt dtexpand dtlang );

my $lock = conf ( 'file_lock' );

# the existence of the lock file prevents further
# processing and exists silently
-f $lock and exit;

# store the beginning timestamp to be able to 
# calculate  total exectution time in secods
my $btime = time(); 

my $dt = dt(); # the run is identified by YYYYMMSSHHMMSS

# creating lock file to prevent further cron executions
# DISABLE FOR TESTING 
#file_write ( $lock, "Catz loader lock file $dt" );

logopen ( conf ( 'path_log' ) . "/$dt.log" );

logit ( 'catz loader started at ' . dtexpand ( $dt ).' (dt '.$dt.')' );

my $loaded = {}; # to store names of loaded folders and albums 

my $olddb = findlatest ( conf ( 'path_master' ) , 'db' );

defined $olddb or die "old database lookup failed";

my $newdb = conf ( 'path_master' ) . "/$dt.db";

logit ( "copying database '$olddb' to '$newdb'" );

filecopy ( $olddb, $newdb );

my $changes = 0; # flag that should be turned on if something has changed

load_begin ( $dt, $newdb );

lc($ARGV[0]) eq 'meta' and goto SKIP_FOLDERS;

# phase 1: load folders

my @folders =  
 grep { /\d{8}[a-z0-9]+$/ } finddirs ( conf ( 'path_photo' ) );

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

SKIP_FOLDERS:

# phase 2: load files

logit ( 'verifying ' . scalar (  @{ conf ( 'metafiles' ) } ) . ' files' );

foreach my $head ( @{ conf ( 'metafiles' ) } ) {

 my $file =  $head . '.' . conf ( 'ext_meta' );
 
 my $full = conf ( 'path_meta' ) . '/' . $file;
  
 my $data = fileread ( $full );
 
 my $dna = dna ( $data );
 
 if ( load_nomatch ( 'file', $head, $dna ) ) { # loading required
 
  $changes++; 
 
  if ( $head eq 'gallerymeta' ) { # complex loading
  
   foreach my $pile ( topiles ( $data ) ) {  
   
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
   
   { 
   
    no strict 'refs';
    
    $table = conf ( 'file2table' ) -> ( $file );   
   }
  
   load_simple ( $table, $data );
  
  }
  
 }
 
}

# phase 3: postprocessing = inserting to sec more elements

$changes == 0 and goto SKIP_POST;

logit ( "postprocessing secondaries" ); 

load_pprocess ( $loaded );

# phase 4: recreating secondary tables

logit ( "recreating secondary tables" ); 

load_secondary;

SKIP_POST:

load_end; # finish

my $etime = time();

logit ( 'catz loader finished at ' .  dtlang() . ' (' . ( $etime - $btime ) . ' seconds)' );

logclose();