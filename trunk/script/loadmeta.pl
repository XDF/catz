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

# autoflush on to print immediately to STDOUT
$| = 1; 

# are we running on windows
my $win = 0;
$^O =~ /win/i and $win = 1;

# hard-coded value for intiail testing
if ( $win ) { use lib '/catz/lib' } 
 else { die "unconfigured" }

use strict;
use warnings;

use feature qw( say );

use Catz::Util qw ( dna expand_ts readfile sys_ts );
use Catz::Data;
use Catz::Load;

my $btime = time();
my $dt = sys_ts();

Catz::Load::run( 'run_ins', $dt );

say "loadmeta dt $dt " . expand_ts( $dt );

my $changes = 0;
   
foreach my $file (@Catz::Load::metafiles) {

 my $ffile = $Catz::Load::metapath.'/'.$file.'.txt';
 my $data = readfile($ffile);
 my $table = Catz::Load::file2table($file);
 
 print "FILE $file " . length ( $data );
 
 my $dold = Catz::Load::run( 'dna_se1', 'FILE', $file );
 my $dnew = dna( $data ); 

 if ( $dold ne $dnew ) {
    
  say " MISMATCH $dold $dnew";
  
  $changes++;
  
  if ( $file eq 'gallerymeta' ) {
     
   foreach my $pile ( reverse split /\#/,
    $data ) {
           
    my @lines = Catz::Load::to_lines( $pile );
    
    # skip section marks, they are deprecated   
    ( $lines[0] =~ m|^\!(.+)| ) and shift @lines;
                
    my $album = shift( @lines ) ;
    
    # skip all albums that don't start YYYYDDMM
    
    if( $album =~ /^\d{8}/ ) {
    
     my $doldb = Catz::Load::run( 'dna_se1', 'album', $album );
     my $dnewb = dna ( join "\n", @lines );

     if ( $doldb ne $dnewb ) {
    
      say "$album MISMATCH $doldb $dnewb";
      
      $changes++;
      
      my ( undef,undef,$lensmode ) = split /\//, shift @lines;
      my ( $created,$modified ) = split /\//, shift @lines; 
      my $name_en = shift @lines;
      my $name_fi = shift @lines;
      shift @lines; # skip desc_en
      shift @lines; # skip desc_fi

      my $location_en;
      my $location_fi;
      my $country;
      my $organizer_en;
      my $organizer_fi;
      my $umbrella_en;
      my $umbrella_fi;

      $album =~ /^(20\d\d\d\d\d\d)(.+)$/;
      
      my $origined = $1;
      my $lockey = $2;
       
      ( $location_en, $location_fi ) = Catz::Data::location( $lockey );
      
      $country = Catz::Data::country( $location_en );
     
      ( $organizer_en, $organizer_fi ) = Catz::Data::organizer( $name_en );
     
      ( $umbrella_en, $umbrella_fi ) = Catz::Data::umbrella(
        $organizer_en, $origined
       );
                 
      Catz::Load::run( 'album_del', $album );
     
      Catz::Load::run( 'album_ins', $album, $name_en, $name_fi, $lensmode,
       $origined, $created, $modified, $location_en, $location_fi, $country
      );
      
      Catz::Load::run( 'organizer_del', $album );
      #say "$album $organizer_en $organizer_fi";
      Catz::Load::run( 'organizer_ins', $album, $organizer_en, $organizer_fi ); 

      Catz::Load::run( 'umbrella_del', $album );
      Catz::Load::run( 'umbrella_ins', $album, $umbrella_en, $umbrella_fi ); 

      Catz::Load::run ( 'exid_del', $album );
      Catz::Load::run ( 'out_del', $album );
      Catz::Load::run ( 'snip_del', $album );
     
      foreach my $data ( @lines ) {
     
       my ( $def, $a, $b, $line );
     
       if( $data =~ m|^(\w)(\d+)\:\s+(.+)$| ) {
       
        $def = $1; $a = $2; $b = $2; $line = $3;
       
       } elsif ( $data =~ m|^(\w)(\d+)-(\d+)\:\s+(.+)$| ) {
            
        $def = $1; $a = $2; $b = $3; $line = $4;
       
       } else {
      
        die "format error: $data";
       
       }
       
       $def ne 'P' and $def ne 'L' and die "type error: $data";
      
       $a<=$b or die "range error: $data";
              
       my ( $out_en, $out_fi ) = Catz::Data::plain( $line );
      
       my $i = $a;
      
       while($i <= $b) {
       
        if ( $def eq 'P' ) {
        
         Catz::Load::run( 'out_ins', $album, $i, $out_en, $out_fi );
         
         foreach my $pri ( @Catz::Load::pris ) {
     
          my $sub = 'Catz::Data::get_'.$pri.'s';
          my $sdata;
      
          do { no strict; $sdata = $sub->( $line ); };
 
          foreach my $sec ( grep { defined } @$sdata ) {
          
           Catz::Load::run( 'snip_ins', $album, $i, $pri, $sec );
          
          }
        
         }
         
        } else { # def eq 'L'
         
         my $exid = Catz::Data::exid( $line );
        
         Catz::Load::run ( 'exid_ins', $album, $i, $$exid{'flen'}, 
          $$exid{'etime_txt'}, $$exid{'etime_num'}, $$exid{'fnum'}, 
          $$exid{'dt'}, $$exid{'iso'}, $$exid{'body'}, $$exid{'lens'} ); 

         Catz::Load::upd_exia ( $album, $i );
                  
        }
       
        $i++;
        
       }

      }
      
      Catz::Load::put_dna ( 'ALBUM', $album, $doldb, $dnewb, $dt );

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
  
  Catz::Load::put_dna ( 'FILE', $file, $dold, $dnew, $dt );
  
 } else {
 
  say " match $dold $dnew";
  
 }
 
}

$changes and Catz::Load::upd_x;

$changes and Catz::Load::housekeep();

my $etime = time();

say "$changes changes done in " . ( $etime - $btime ) . ' seconds';
 