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

package Catz::Data::Load;

use strict;
use warnings;

use feature qw( say switch );

use parent 'Exporter';

our @EXPORT = qw ( 
 load_begin load_end load_exec load_folder load_nomatch 
 load_simple load_complex
);

use feature qw ( switch );

use DBI;

use Catz::Data::Conf;
use Catz::Data::Parse;
use Catz::Util::Data qw ( fixgap tolines topiles );
use Catz::Util::File qw ( filehead filesize filethumb findphotos pathcut );
use Catz::Util::Image qw ( exif widthheight );
use Catz::Util::Log qw ( logit );
use Catz::Util::String qw ( trim );

my $sql = { 

 # this hash ref has all SQL statements used by the loader
 # _ins = insert statement
 # _ind = insert statement with automatic primary key generation
 # _upd = update statement
 # _del = delete statement
 # _trn = truncate statement executed automatically at the end of the loading

 run_ins => 'insert into run values (?)',
 run_one => 'select max(dt) from run',
 run_count_one => 'select count(*) from run', 
 
 dna_one => 'select dna from dna where class=? and item=?',
 dna_ins => 'insert into dna (dna,dt,class,item) values (?,?,?,?)',
 dna_upd => 'update dna set dna=?, dt=? where class=? and item=?', 
 dna_trn =>  "delete from dna where class='album' and item not in ( select album from album )",
  
 album_col => 'select album from album order by album',
 album_del => 'delete from album where album=?',
 album_ins => 'insert into album (album,name_en,name_fi,origined,created,modified,location_en,location_fi,country) values (?,?,?,?,?,?,?,?,?)',
  
 org_del => 'delete from org where album=?',
 org_ins => 'insert into org (album,org_en,org_fi) values (?,?,?)',
 org_trn => 'delete from org where album not in ( select album from album )', 
  
 umb_del => 'delete from umb where album=?',
 umb_ins => 'insert into umb (album,umb_en,umb_fi) values (?,?,?)',
 umb_trn => 'delete from umb where album not in ( select album from album )',
 
 photo_del => 'delete from photo where album=?',
 photo_ins => 'insert into photo (album,n,file,width_hr,height_hr,bytes_hr,width_lr,height_lr,bytes_lr) values (?,?,?,?,?,?,?,?,?)', 
   
 fexif_del => 'delete from fexif where album=?',
 fexif_ins => 'insert into fexif (album,n,key,val) values (?,?,?,?)',
 fexif_all => 'select n,key,val from fexif where album=? order by n,key',
 fexif_trn => 'delete from fexif where album not in ( select album from photo )',
 
 mexif_del => 'delete from mexif where album=?',
 mexif_ins => 'insert into mexif (album,n,key,val) values (?,?,?,?)',
 mexif_all => 'select n,key,val from mexif where album=? order by n,key',
   
 snip_del => 'delete from snip where album=?', 
 snip_ins => 'insert into snip (album,n,p,sid) values (?,?,?,?)',
 
 sec_ind => 'insert into sec (pid,sec_en,sort_en,sec_fi,sort_fi) values (?,?,?,?,?)',
 sec_trn => 'delete from sec where ( pid not in (select pid from pri) ) or ( sid not in ( select sid from snip ) )',

 pri_one => 'select pid from pri where pri=?', 
  
};

my $stm = {}; # variable to hold prepared SQL statements

# static database connection initialized at 
# the beginning and closed at the end
my $dbc;

sub load_begin {

 my ( $dt, $dbfile ) = @_;
  
 logit ( "connecting database '$dbfile'" );

 $dbc = DBI->connect( 
  conf ( 'dbconn' ) . $dbfile , '', '', conf ( 'dbargs_load' ) 
 )  or die "unable to connect to database $dbfile: $DBI::errstr";

 logit ( 'preparing ' . scalar ( keys %{ $sql } ). ' predefined SQL statements' );
 
 foreach ( keys %{ $sql } ) { $stm->{$_} = $dbc->prepare ( $sql->{$_} ) }
  
 logit ( "storing run dt '$dt'" );
  
 load_exec ( 'run_ins', $dt ); 
 
}

sub load_end {

 my $vacuum = 0; # default is not to vacuum
 
 # for every fifth run do vacuum 
 ( load_exec ( 'run_count_one' ) % 5 == 0 ) and $vacuum = 1;
   
 logit ( 'finishing statements' );
 
 foreach ( keys %{ $stm } ) { $stm->{$_}->finish } 
 
 logit ( 'committing database' );

 $dbc->commit;
 
 logit ( 'analyzing database' );
 
 $dbc->do( 'analyze' );
 
 if ( $vacuum ) {
 
  logit ( 'vacuuming database' );

  {
  
   local $dbc->{AutoCommit} = 1;
 
   $dbc->do( 'vacuum' );
 
  }
  
 }

 logit ( 'disconnecting database' );

 $dbc->disconnect;  

}

sub load_exec {

 # general database statement executor
 # the statement key points to the statement to get executed

 my ( $key, @args ) = @_;
  
 $stm->{$key}->execute ( @args );
 
 given ( $key ) {
 
  when ( /one$/ ) { return $stm->{$key}->fetchrow_array }
  
  when ( /row$/ ) { return $stm->{$key}->fetchrow_array }
  
  when ( /col$/ ) { return $stm->{$key}->fetchcol_array }
  
  when ( /all$/ ) { return $stm->{$key}->fetchall_array }
  
  when ( /ind$/ ) { return $dbc->sqlite_last_insert_rowid() }
 
 }
 
 # default is not to return anything

}

sub load_nomatch {

 #
 # checks if DNA matches, if it doesn't then store the new DNA

 # returns true if no match = something to do 
 # returns false if match = nothing to do
 
 my ( $class, $item, $dnanew ) = @_;
 
 my $dt = load_exec ( 'run_one' ); # get the current run's dt
 
 my $dnaold = load_exec ( 'dna_one', $class, $item );
 
 if ( defined $dnaold ) {
 
  if ( $dnaold eq $dnanew ) {

   logit ( "DNA match '$class' '$item' '$dnanew'" ); 
   
   return 0;  
  
  } else {
  
   logit ( "DNA mismatch '$class' '$item' '$dnaold' '$dnanew'" ); 

   load_exec ( 'dna_ins', $dnanew, $dt, $class, $item );
     
  }
  
 } else {
 
  logit ( "DNA not found for '$class' '$item', storing the new DNA '$dnanew'" ); 

  load_exec ( 'dna_ins', $dnanew, $dt, $class, $item );

  return 1;
 
 }
  
}

sub load_folder {

 my $folder = shift;
 
 my $album = pathcut ( $folder );
 
 load_exec ( 'photo_del', $album );
 load_exec ( 'fexif_del', $album );
    
 my @photos = fixgap ( findphotos ( $folder ) );

 logit ('loading '. scalar @photos . " photos from '$folder'" );
 
 my $n = 1; # photos are numbered staring from 1
 
 foreach my $photo (@photos) {
      
  my $head = filehead ( $photo );
             
  my $thumb = filethumb ( $photo );

  -f $thumb or die "missing thumbnail file '$thumb'";  
   
  my ( $width_hr, $height_hr ) = widthheight( $photo );
  
  my $bytes_hr = filesize ( $photo );
  
  my ( $width_lr, $height_lr ) = widthheight( $thumb );
  
  my $bytes_lr = filesize ( $thumb );
  
  load_exec ( 
   'photo_ins', $album, $n, $head, $width_hr, $height_hr,
   $bytes_hr, $width_lr, $height_lr, $bytes_lr 
  );
  
  my $exif = exif ( $photo );
  
  do {
   load_exec ( 'fexif_ins', $album, $n, $_, $exif -> { $_ }  ) 
  } foreach keys %{ $exif };
      
  $n++;
    
 }

}

sub load_simple {

 my ( $table, $data ) = @_;
 
 $dbc->do ( "delete from $table" );
 
 my $stm = $dbc->prepare ( "select * from $table" );
 
 my @cols = @{ $stm->{'NAME'} };
 
 $stm->finish;
 
 $stm = $dbc->prepare ( 
  "insert into $table values (" . ( join ',', map { '?' } @cols ) . ')' 
 );
 
 my $r = 0; # loaded rows counter
 
 foreach my $pile ( topiles ( $data ) ) {
 
  $r++;
  
  # immediately convert ? to null 
  my @lines = map { $_ eq '?' ? undef : $_ } tolines ( $pile );
  
  given ( $table  ) {
  
   # skip the photo URL which comes last  
   when ( 'mbreed' ) { pop @lines };
   
   # skip the photo URL that comes as third value
   when ( 'mbreeder' ) { @lines = ( $lines[0], $lines[1], $lines[3] ) };
    
  } 
  
  $stm->execute ( @lines );
        
 }
 
 $stm->finish;
 
 logit ( "$r rows loaded to table '$table'" );
 
}

sub load_complex {

 my ( $album, $data ) = @_;
 
 my $d = parse_pile ( $data );
 
 


}

1;

__END__

 
sub end {

 my $btime = shift;

 my $etime = time();
 my $ttime = $etime-$btime;

 my $endts = expand_ts(sys_ts());

 say "execution took $ttime seconds";
 say "finished at $endts";

}



sub put_exia {

 my ( $album, $exia, $lensmode ) = @_;
 
 foreach my $a ( keys %{ $exia } ) { # foreach photo 1, 2, 3 ...
 
  defined $exia->{$a}->{lens} or do {
   my $lens = Catz::Data::lens ( 
    $lensmode, $exia->{$a}->{flen}, $exia->{$a}->{fnum} 
   );
   defined $lens and $exia->{$a}->{lens} = $lens;
  };  
 
  foreach my $b ( keys %{ $exia->{$a} } ) { #foreach flen, fnum, etime ...
  
   say "$album $a $b " . $exia->{$a}->{$b};

   run ( 'snip_ins', $album, $a, 0, $b, $Catz::Data::order{$b}, 
    $exia->{$a}->{$b}, $exia->{$a}->{$b},
    $exia->{$a}->{$b}, $exia->{$a}->{$b} 
   ); 
  
  }
 }
}
 
sub upd_x {

 say "updating x"; 

  run ( 'x_del' );
  run ( 'x_ins' );
 
}



sub file2table {

 $_[0] =~ m|^(.+)meta$|; 
 'meta'.lc($1);

}

sub load_getmeta {


}


sub to_lines {

  my $album = $_[0];
  $album = trim($album);
  my @lines = split /\n/, $album;
  @lines = map { trim($_) } @lines;
  length($lines[0])<1 and return ();
  return @lines;
          
}

1;

__END__

sub finish {

 say "finishing statements";
 foreach my $key (keys %stm) { $stm{ $key }->finish }

 say "committing";
 $dbc->commit;
 
 say "analyzing";
 $dbc->do('analyze');

 #say "vacuuming";
 #{
 # local $dbc->{AutoCommit} = 1;
 #  $dbc->do('vacuum');
 #}

 say "disconnecting";
 $dbc->disconnect;  

}


sub run {

 my ( $key, @arg ) = @_;
 
 $stm { $key }->execute ( @arg );
   
 if ( $key =~ m|se1$| ) {
 
  return $stm{ $key }->fetchrow_array;
    
 } elsif ( $key =~ m|ser$| ) {
 
  return $stm{ $key }->fetchrow_arrayref;
      
 } elsif ( $key =~ m|sea$| ) {
 
  return $stm{ $key }->fetchall_arrayref;
    
 }

}
foreach my $file ( grep { $_ ne 'gallerymeta' } @metafiles ) {

 my $table = file2table( $file );

 $sql{ $table . '_trn' } = 'delete from ' . $table;
 
 my $es = '?';
 
 foreach ( 2 .. $cols { $file } ) { $es .= ',?' }
 
 $sql{ $table . '_ins' } = "insert into $table values ($es)";

}

my %stm = ();

foreach my $key (keys %sql) {

 #say "preparing $key";

 $stm { $key } = $dbc->prepare ( $sql { $key } );

}

our @pris = qw ( ems1 ems3 ems4 ems5 nick breeder cat );