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

#eval { # main eval begin

my $olddb = findlatest ( conf ( 'path_master' ) , 'db' );

defined $olddb or die "old database lookup failed";

my $newdb = conf ( 'path_master' ) . "/$dt.db";

logit ( "copying database '$olddb' to '$newdb'" );

filecopy ( $olddb, $newdb );

my $changes = 0; # flag that should be turned on if something has changed

load_begin ( $dt, $newdb );

# phase 1: load folders

my @folders =  
 grep { /\d{8}[a-z0-9]+$/ } grep { /2004/ } finddirs ( conf ( 'path_photo' ) );

logit ( 'verifying ' . scalar ( @folders ) . ' folders' );

foreach my $folder ( @folders ) {

 my $dna = dnafolder ( $folder );
 
 my $album = pathcut ( $folder );
 
 if ( load_nomatch ( 'folder', $album, $dna ) ) { # loading required
 
  $changes++;

  load_folder ( $folder );  
 
 }

}

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

# phase 3: secondary tables data generation

load_end;

#}; # main eval end

#if ( $@ ) { # error condition true
#
# logit $@;
 
# die $@;
 

#} else { # no errors 



#}


my $etime = time();

logit ( 'catz loader finished at ' .  dtlang() . ' (' . ( $etime - $btime ) . ' seconds)' );

logclose();

__END__  


Catz::Load::run( 'run_ins', $dt );

say "load $dt " . expand_ts( $dt );

my @folders = #grep { /^2005/ }     
 grep { /^\d{8}/ } map { cutpath ( $_ ) } finddirs ( $Catz::Load::photopath );

say "phase1: folders";

say "verifying " . scalar ( @folders ) . " folders";

# record the number of changed objects
my $changes = 0;
 
foreach my $folder ( @folders ) {

 my $dold = Catz::Load::run( 'dna_se1', 'FOLDER', $folder ) // 'undef';
    
 my $fullpath = $Catz::Load::photopath.'/'.$folder;
  
 my $dnew = folder_dna ( $fullpath );

 if ( $dold ne $dnew ) {
 
  Catz::Load::run( 'file_del', $folder );
  Catz::Load::run( 'exif_del', $folder );
    
  my @photos = Catz::Data::fix_gap( findphotos($fullpath) );
   
  my $n = 1; # photos are numbered from 1
 
  say "$folder ". ( scalar @photos ) . " MISMATCH $dold $dnew";
   
  $changes++; # mark that data has been changed
     
  foreach my $photo (@photos) {
      
   $photo =~ /^.*\/(.+?)\.JPG$/; 
   my $pname = $1;
         
   my $thumb = thumbfile( $photo );

   -f $thumb or die "missing thumb: $thumb";  
   
   my ( $width_hr,$height_hr ) = width_height( $photo );
   my $bytes_hr = filesize( $photo );
  
   my ( $width_lr,$height_lr ) = width_height( $thumb );
   my $bytes_lr = filesize( $thumb );
                
   Catz::Load::run( 'file_ins', $folder, $n, $pname, $width_hr, $height_hr,
    $bytes_hr, $width_lr, $height_lr, $bytes_lr );
    
   my $exif = Catz::Data::exif( $photo );
    
   foreach my $tech ( @Catz::Data::techs ) {
         
    defined $$exif{$tech} and 
     Catz::Load::run ( 'exif_ins', $folder, $n, $tech, $$exif{$tech} );
            
   }
    
   $n++;
    
  }

  Catz::Load::put_dna ( 'FOLDER', $folder, $dnew, $dt );
  
  # force load of gallerymeta and force the load of this album's meta
  
  say "reset gallerymeta";
  
  $dold = Catz::Load::run( 'dna_se1', 'FILE', 'gallerymeta' ) // 'undef';
  Catz::Load::put_dna ( 'FILE', 'gallerymeta', 'force', $dt );
  
  say "reset album $folder";
  
  $dold = Catz::Load::run( 'dna_se1', 'ALBUM', $folder ) // 'undef';
  Catz::Load::put_dna ( 'ALBUM', $folder, 'force', $dt );

 } else {
 
   say "$folder match $dold $dnew";
   
 }

}

say "phase2: meta";

foreach my $file (@Catz::Load::metafiles) {

 my $ffile = $Catz::Load::metapath.'/'.$file.'.txt';
 my $data = readfile($ffile);
 my $table = Catz::Load::file2table($file);
 
 print "$file " . length ( $data );
 
 my $dold = Catz::Load::run( 'dna_se1', 'FILE', $file ) // 'undef';
 
 my $dnew = dna( $data ); 

 if ( $dold ne $dnew ) {
    
  $changes++;
  
  if ( $file eq 'gallerymeta' ) {
     
   foreach my $pile ( reverse split /\#/,
    $data ) { # process galleries in reverse order (oldest first)
           
    # split a complete gallery metadata into separate lines           
    my @lines = Catz::Load::to_lines( $pile );
    
    # skip section marks and section names, they are deprecated   
    ( $lines[0] =~ m|^\!(.+)| ) and shift @lines;
    
    # album name is now on the first line            
    my $album = shift( @lines ) ;
    
    # skip all albums that don't start YYYYDDMM
    # since they are not cat show photo albums
    
    if( $album =~ /^\d{8}/ ) {
    
     my $doldb = Catz::Load::run( 'dna_se1', 'album', $album ) // 'undef';
     
     # new dna is calculated only from the true album data, 
     # not from the whole pile including gallery name 
     my $dnewb = dna ( join "\n", @lines );

     if ( $doldb ne $dnewb ) {
      
      say "$album MISMATCH $doldb $dnewb";
      
      $changes++; # record changes

      # proceed line by line (shift from @lines)
      my ( undef,undef,$lensmode ) = split /\//, shift @lines;
      my ( $created,$modified ) = split /\//, shift @lines; 
      my $name_en = shift @lines;
      my $name_fi = shift @lines;
      shift @lines; # skip english description, it is deprecated
      shift @lines; # skip finnish description, it is deprecated

      my ( $loc_en, $loc_fi, $country, $org_en, $org_fi, $umb_en, $umb_fi );

      $album =~ /^(20\d{6})([a-z]+)(\d{0,1})$/;
      
      my $origined = $1; # albumn name starts with YYYYDDMM
      my $lockey = $2; # location part follows
      # $3 might be 1,2,3 ... to specify multiple albums 
      # on a same date but is currently unused
         
      ( $loc_en, $loc_fi ) = Catz::Data::location( $lockey );
      
       $country = Catz::Data::country( $loc_en );
     
      ( $org_en, $org_fi ) = Catz::Data::organizer( $name_en );
     
      ( $umb_en, $umb_fi ) = Catz::Data::umbrella( $org_en, $origined );
                 
      Catz::Load::run( 'album_del', $album );
           
      Catz::Load::run( 'album_ins', $album, $name_en, $name_fi, $lensmode,
       $origined, $created, $modified, $loc_en, $loc_fi, $country
      );
            
      Catz::Load::run( 'organizer_del', $album );
      Catz::Load::run( 'organizer_ins', $album, $org_en, $org_fi ); 

      Catz::Load::run( 'umbrella_del', $album );
      Catz::Load::run( 'umbrella_ins', $album, $umb_en, $umb_fi );
      
      Catz::Load::run ( 'snip_del', $album );
      
      my $exia = {}; # to collect all exifs for this album
      
      # initialize exia from database by file exifs
      my $exif = Catz::Load::run ( 'exif_sea', $album );
      
      foreach my $row ( @{ $exif } ) {
       # 0 = n, 1 = pri, 2 = sec
       $exia->{$row->[0]}->{$row->[1]} = $row->[2];
      
      } 
                 
      foreach my $data ( @lines ) {
       
       # process the core album data line by line
     
       my ( $def, $a, $b, $line );
     
       if( $data =~ m|^(\w)(\d+)\:\s+(.+)$| ) { 
       
        # sigle photo definition       
        
        $def = $1; $a = $2; $b = $2; $line = $3;
       
       } elsif ( $data =~ m|^(\w)(\d+)-(\d+)\:\s+(.+)$| ) {
       
        # range definition
            
        $def = $1; $a = $2; $b = $3; $line = $4;
       
       } else { die "album data line format error: $data" }
       
       $def ne 'P' and $def ne 'L' and die "album data line type error: $data";
      
       $a<=$b or die "album data line range error: $data";
       
       my $parts = Catz::Data::line2parts ( $line );
                           
       my $i = $a;
      
       while($i <= $b) { # do the same processing for every photo in the range
       
        if ( $def eq 'P' ) {
        
         foreach my $p ( 0 .. scalar ( @$parts ) - 1) {
         
          # for each part of the line
         
          my ( $pen, $pfi ) = Catz::Data::plain ( $$parts[$p] );

          Catz::Load::run( 'snip_ins', $album, $i, $p+1, 'out', 
           $Catz::Data::order{'out'}, $pen, $pen, $pfi, $pfi
          );
          
          foreach my $pri ( @Catz::Data::softs ) {
     
           my $sub = 'Catz::Data::get_'.$pri.'s';
           my $sdata;
      
           do { no strict; $sdata = $sub->( $$parts[$p] ); };
 
           foreach my $sec ( grep { defined } @$sdata ) {
           
            #say "$album $i ". ( $p+1 )." $pri $sec";
            # at least empty ems5's coming
            
            Catz::Load::run( 'snip_ins', $album, $i, $p+1, $pri, 
             $Catz::Data::order{$pri}, $sec, $sec, $sec, $sec 
            );
          
           }
        
          }
         
         }
         
        } else { # def eq 'L'
                          
         my $exid = Catz::Data::exid( $line );
         
         foreach my $key ( keys %{ $exid } ) {
         
          # exid overwrites file exifs
          defined $$exid{ $key } and $exia->{$i}->{$key} = $$exid{ $key };
         
         }
         
           
        }
       
        $i++;
        
       }

      }
      
      # write all exia data for this gallery 
      Catz::Load::put_exia ( $album, $exia, $lensmode );
      
      Catz::Load::put_dna ( 'ALBUM', $album, $dnewb, $dt );

     } else {
     
      say "$album match $doldb $dnewb";
     
     }
    
    } 
    
   }
  
  } else { # $file ne 'gallerymeta'
  
   Catz::Load::run ( $table . '_trn' );
 
   my $key = $table . '_ins';
   
   if ($file eq 'resultmeta' ) {

    my @lines = Catz::Load::to_lines( $data );
  
    map { Catz::Load::run( $key, $_ ) } @lines;
    
   } else { 
      
    foreach my $album ( split /\#/, 
     $data ) {
    
     my @lines = Catz::Load::to_lines( $album );
     
     if( $file eq 'textmeta' and ( not defined $lines[2] ) ) {
    
      Catz::Load::run( $key, $lines[0], $lines[1], $lines[1] ); 
      
     } else {
     
      Catz::Load::run( $key, @lines ); 
      
     }
      
    }
   
   } 

  }
  
  Catz::Load::put_dna ( 'FILE', $file, $dnew, $dt );
  
 } else {
 
  say " match $dold $dnew";
  
 }
 
}

$changes and Catz::Load::upd_x;

$changes and Catz::Load::housekeep();

my $etime = time();

say "load $changes changes in " . ( $etime - $btime ) . ' seconds';
