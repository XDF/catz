
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

# hard-coded value for initial testing
if ( $win ) { use lib '/catz/lib' } 
 else { die "not on win, out of ideas" }
 
use strict;
use warnings;

use feature qw( say );

use Switch;
use DBI;

use Catz::Util qw ( expand_ts filesize findphotos finddirs folder_dna sys_ts thumbfile width_height );
use Catz::Data;
use Catz::Load;

my $btime = time();
my $dt = sys_ts();

Catz::Load::run( 'run_ins', $dt );

say "loadphoto dt $dt " . expand_ts( $dt );

my $req = $ARGV[0];

my @folders = grep { /^\d{8}/ }   
 map { substr ( $_, length($Catz::Load::photopath) + 1 ) }
 finddirs ( $Catz::Load::photopath ) ;
 
my $changes = 0;
 
foreach my $folder ( @folders ) {

 if(defined $req and (($req eq 'ALL' ) or ( $req eq $folder ))) {
  
  my $dold = Catz::Load::run( 'dna_se1', 'FOLDER', $folder );
    
  my $fullpath = $Catz::Load::photopath.'/'.$folder;
  
  my $dnew = folder_dna ( $fullpath );
   
  if ( $dold ne $dnew ) {
  
   my $lensmode = Catz::Load::run( 'lensmode_sel', $folder );
   
   $lensmode eq '-1' and die "lensmode not found for $folder";
     
   Catz::Load::run( 'flesh_del', $folder );
   Catz::Load::run( 'file_del', $folder );
   Catz::Load::run( 'exif_del', $folder );
    
   my $n = 1;
 
   my @photos = Catz::Data::fix_gap( findphotos($fullpath) );
   
   say "$folder MISMATCH $dold $dnew " . ( scalar @photos ) . ' photos';
   
   $changes++;
      
   foreach my $photo (@photos) {
      
    $photo =~ /^.*\/(.+?)\.JPG$/; 
    my $pname = $1;
         
    my $thumb = thumbfile( $photo );

    -f $thumb or die "missing thumb: $thumb";  
   
    my ( $width_hr,$height_hr ) = width_height( $photo );
    my $bytes_hr = filesize( $photo );
  
    my ( $width_lr,$height_lr ) = width_height( $thumb );
    my $bytes_lr = filesize( $thumb );
    
    Catz::Load::run('flesh_ins', $folder, $n, $pname );
            
    Catz::Load::run( 'file_ins', $folder, $pname, $width_hr, $height_hr, $bytes_hr, $width_lr, $height_lr, $bytes_lr );
    
    my $exif = Catz::Data::exif( $lensmode, $photo );
    
    $$exif{'flen'}||$$exif{'etime_txt'}||$$exif{'etime_num'}||$$exif{'fnum'}||$$exif{'ts'}||$$exif{'iso'}||$$exif{'body'}||$$exif{'lens'} and do {
     
     Catz::Load::run( 'exif_ins', $folder, $pname, $$exif{'flen'}, $$exif{'etime_txt'}, $$exif{'etime_num'}, $$exif{'fnum'}, $$exif{'dt'}, $$exif{'iso'}, $$exif{'body'}, $$exif{'lens'});
     
     Catz::Load::upd_exia ( $folder, $n );   
    
    };
    
    $n++;
    
   }
   
   Catz::Load::put_dna ( 'FOLDER', $folder, $dold, $dnew, $dt );
    
  } else {
    say "$folder match $dold $dnew";
  }
 }
}

$changes and Catz::Load::upd_x;

$changes and Catz::Load::housekeep();

my $etime = time();

say "$changes changes done in " . ( $etime - $btime ) . ' seconds';
