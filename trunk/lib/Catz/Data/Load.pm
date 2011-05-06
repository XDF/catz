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

use 5.12.2;
use strict;
use warnings;

use parent 'Exporter';

our @EXPORT = qw ( 
 load_begin load_end load_exec load_folder load_nomatch 
 load_simple load_exif load_complex load_post load_secondary 
);

use Data::Dumper;
use DBI;

use Catz::Data::Conf;
use Catz::Data::Parse;
use Catz::Util::Data qw ( exifsort fixgap lens tolines topiles );
use Catz::Util::Time qw ( dtexpand );
use Catz::Util::File qw ( filehead filesize filethumb findphotos pathcut );
use Catz::Util::Image qw ( exif widthheight );
use Catz::Util::Log qw ( logit );
use Catz::Util::Number qw ( fullnum33 );
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
 
 dna_del => 'delete from dna where class=? and item=?',
 dna_one => 'select dna from dna where class=? and item=?',
 dna_ins => 'insert into dna (dna,dt,class,item) values (?,?,?,?)',
 dna_upd => 'update dna set dna=?, dt=? where class=? and item=?', 
 
 album_one => 'select aid from album where folder=?', 
 album_ind => 'insert into album (folder) values (?)',
   
 photo_del => 'delete from photo where aid=?',
 photo_ins => 'insert into photo (aid,n,file,moment,hwidth,hheight,lwidth,lheight) values (?,?,?,?,?,?,?,?)',
 #max_n_one => 'select max(n) from photo where aid=?', 

 inalbum_del => 'delete from inalbum where aid=?',
 inalbum_ins => 'insert into inalbum (aid,sid) values (?,?)',
 
 inexif_one => 'select count(*) from inexif where aid=? and n=? and pid=?',
 inexif_ins => 'insert into inexif (aid,n,pid) values (?,?,?)',
 inexif_data_null_upd => 'update inexif set sid_data=null where aid=?',
 inexif_file_null_upd => 'update inexif set sid_file=null where aid=?',
 inexif_meta_upd => 'update inexif set sid_meta=? where aid=? and n=? and pid=?',
 inexif_data_upd => 'update inexif set sid_data=? where aid=? and n=? and pid=?',
 inexif_file_upd => 'update inexif set sid_file=? where aid=? and n=? and pid=?',
 
 inpos_del => 'delete from inpos where aid=?', 
 inpos_ins => 'insert into inpos (aid,n,p,sid) values (?,?,?,?)',
  
 # strongly assuming that pri & sec_en uniquely identifies a row
 sec_one => 'select sid from sec where pid=? and sec_en=?',
 sec_ind => 'insert into sec (pid,sec_en,sort_en,sec_fi,sort_fi) values (?,?,?,?,?)',
 
 pid_one => 'select pid from pri where pri=?',

 album_col => 'select aid from album order by folder',
 album_s_null_upd => 'update album set s=null',
 album_s_upd => 'update album set s=? where aid=?'
,
 photo_all => 'select aid,n from photo natural join album order by folder desc, n asc',
 photo_x_null_upd => 'update photo set x=null',
 photo_x_upd => 'update photo set x=? where aid=? and n=?',

 prim_del => 'delete from prim',
 secm_del => 'delete from secm',
 pri_meta_all => 'select pid,count(*) from pri natural join sec group by pid',
 sec_meta_inalbum_all => "select sec.sid,count(distinct album.aid),count(distinct x),min(substr(folder,1,8)),max(substr(folder,1,8)) from inalbum natural join photo natural join sec natural join pri natural join album where origin='album' group by sec.sid",
 sec_meta_inexiff_all => "select inexiff.sid,count(distinct album.aid),count(distinct x),min(substr(folder,1,8)),max(substr(folder,1,8)) from photo natural join inexiff natural join album where sid in ( select sid from inexiff ) group by sid",
 sec_meta_inpos_all => "select sec.sid,count(distinct album.aid),count(distinct x),min(substr(folder,1,8)),max(substr(folder,1,8)) from inpos natural join photo natural join sec natural join pri natural join album where origin='pos' group by sec.sid",
 prim_ins => 'insert into prim (pid,cnt) values (?,?)',
 secm_ins => 'insert into secm (sid,cntalbum,cntphoto,first,last) values (?,?,?,?,?)',
 
 album_trn => 'delete from album where aid not in ( select aid from inalbum union select aid from inexif union select aid from inpos union select aid from photo )',
 inexif_trn => 'delete from inexif where sid_meta is null and sid_data is null and sid_file is null',
 sec_trn => 'delete from sec where sid not in ( select sid from inalbum union select sid_meta from inexif union select sid_data from inexif union select sid_file from inexif union select sid from inpos )' 
   
};

# defined the correct table truncation order
# only tables defined here will be trunacated
# (if there is _trn SQL but the table is not here the SQL is not used)
my @trnorder = qw ( inexif sec album ); 

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

 logit ( 'preparing ' . scalar ( keys %{ $sql } ). ' SQL statements' );
 
 foreach ( keys %{ $sql } ) { $stm->{$_} = $dbc->prepare ( $sql->{$_} ) }
 
 logit ( 'registering functions' );
 
 # registers int s, n to string id converting functions
 $dbc->func( 'makeid', 2, \&fullnum33, 'create_function' );
   
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
 
 defined $stm->{$key} or die "statement '$key' is unknown";
 
 #logit ( "$key " . join ( ',', grep { defined } @args ) );
  
 $stm->{$key}->execute ( @args );
 
 given ( $key ) {
 
  when ( /one$/ ) { return $stm->{$key}->fetchrow_array }
  
  when ( /row$/ ) { return $stm->{$key}->fetchrow_array }
  
  when ( /col$/ ) { # there is no fetchcol_array or fetchcol_arrayref 
  
   my $arr = $stm->{$key}->fetchall_arrayref;
   
   my @out = map { $_->[0] } @{ $arr };
   
   return @out; 
  
  }
  
  when ( /all$/ ) { return @{ $stm->{$key}->fetchall_arrayref } }
  
  when ( /ind$/ ) { return $dbc->func('last_insert_rowid') }
 
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
   
   load_exec ( 'dna_del', $class, $item );
   load_exec ( 'dna_ins', $dnanew, $dt, $class, $item );
   
   return 1;
     
  }
  
 } else {
 
  logit ( "DNA not found '$class' '$item' '$dnanew'" ); 

  load_exec ( 'dna_ins', $dnanew, $dt, $class, $item );

  return 1;
 
 }
  
}

sub get_aid {

 my $album = shift;

 my $aid = load_exec ( 'album_one', $album );
 
 defined $aid or do {
 
  $aid = load_exec ( 'album_ind', $album );
  
 };
 
 return $aid;
 
}

sub get_sid {

 my ( $pri, $sec_en, $sort_en, $sec_fi, $sort_fi ) = @_;
  
 my $pid = load_exec ( 'pid_one', $pri );
 
 defined $pid or die "unknown pri '$pri'";
 
 my $sid = load_exec ( 'sec_one', $pid, $sec_en );
 
 defined $sid or do {
 
  ( ( $sort_fi eq $sec_fi ) or ( $sort_fi eq $sort_en ) ) and $sort_fi = undef;
  $sec_fi eq $sec_en and $sec_fi = undef;
  $sort_en eq $sec_en and $sort_en = undef;

  $sid = load_exec ( 
   'sec_ind', $pid, $sec_en, $sort_en, $sec_fi, $sort_fi  
  );
    
 };

 # logit ( "sid $sid" );
 
 return $sid; 
  
}

sub put_exif {

 my ( $mode, $aid, $n, $pri, $val ) = @_;
 
 my $sort = exifsort ( $pri, $val );
 
 my $pid = load_exec ( 'pid_one', $pri );
 
 defined $pid or die "pid for '$pri' not found";
 
 my $sid = get_sid ( $pri, $val, $sort, $val, $sort );
 
 ( load_exec ( 'inexif_one', $aid, $n, $pid ) == 0 ) and do { # 
 
  load_exec ( 'inexif_ins', $aid, $n, $pid );  
 
 };
 
 load_exec ( 'inexif_' . $mode . '_upd', $sid, $aid, $n, $pid );
 
}

sub load_folder {

 my $folder = shift;
 
 my $album = pathcut ( $folder );
     
 my @photos = fixgap ( findphotos ( $folder ) );
 
 logit ('loading '. scalar @photos . " photos from '$folder'" );
 
 scalar @photos > 0 or die "too few photos";

 my $aid = get_aid ( $album );
 
 load_exec ( 'photo_del', $aid );
 
 load_exec ( 'inexif_file_null_upd', $aid );
  
 my $n = 1; # photos are numbered staring from 1
 
 foreach my $photo (@photos) {
      
  my $head = filehead ( $photo );
             
  my $thumb = filethumb ( $photo );

  -f $thumb or die "missing thumbnail file '$thumb'";  
   
  my ( $width_hr, $height_hr ) = widthheight( $photo );
    
  my ( $width_lr, $height_lr ) = widthheight( $thumb );
    
  my $exif = exif ( $album, $photo );
  
  my $moment = undef; # by default moment is null
  

  defined $exif->{dt} and do { # if exif contains dt

   # YYYYMMDD must match in dt and album name in order to 
   # take HHHHMMSS from dt and store it as moment
     
   ( substr ( $exif->{dt}, 0, 8 ) eq substr ( $album, 0, 8 ) ) and
    $moment = substr ( $exif->{dt}, 8, 6 );
  
  };
  
  load_exec ( 
   'photo_ins', $aid, $n, $head, $moment, 
   $width_hr, $height_hr, $width_lr, $height_lr,  
  );
  
  
  do {  
   put_exif ( 'file', $aid, $n, $_, $exif -> { $_ }  ) 
  } foreach grep { $_ ne 'dt' } keys %{ $exif };
        
  $n++;
    
 }

}

sub load_simple {

 my ( $table, $data ) = @_;
 
 # delete all previously loaded rows
  $dbc->do ( "delete from $table" );
 
 my $stm = $dbc->prepare ( "select * from $table" );
  
 my @cols = @{ $stm->{NAME} };
 
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

sub load_exif {

 my ( $table, $data ) = @_;
 
 # clear all previously loaded meta exifs from all photos
 $dbc->do ( 'update inexif set sid_meta=null' );
  
 my $r = 0; # loaded rows counter
 
 foreach my $pile ( topiles ( $data ) ) {
 
  $r++;
  
  my @lines = tolines ( $pile );
 
  if ( $lines[2] ne 'dt' ) { # skip all dt elements, they are not used }
  
   do { defined $lines[ $_ ] or die "malformed data in mexif '$pile'" } 
    foreach ( 0 .. 3 );

   my $aid = get_aid ( $lines[0] );
   
   put_exif ( 'meta', $aid, $lines[1], $lines[2], $lines[3] );
  
  }
            
 }
  
 logit ( "$r rows loaded to table '$table'" );
 
}

sub load_complex {

 my ( $album, $data ) = @_;
 
 my $d = parse_pile ( $data );
  
 # $d should now contain completely parsed and processed album data
 # ready to be iterated over and inserted into the database
   
 my $aid = get_aid ( $album );
 
 load_exec ( 'inalbum_del', $aid );

 # loading album level elements
  
 my $date = substr ( $album, 0, 8 );
 
 my $sid = get_sid ( 'date', $date, $date, $date, $date );
 
 load_exec ( 'inalbum_ins', $aid, $sid );

 foreach my $key ( qw ( name loc org umb ) ) {

  $sid = get_sid ( $key, 
   $d->{$key.'_en'}, $d->{$key.'_en'},
   $d->{$key.'_fi'}, $d->{$key.'_fi'} 
  );

  load_exec ( 'inalbum_ins', $aid, $sid );
    
 }
  
 # loading position level elements
 
 load_exec ( 'inpos_del', $aid );
 load_exec ( 'inexif_data_null_upd', $aid );
   
 foreach my $n ( 1 .. ( scalar @{ $d->{data} } - 1 ) ) {
 
  # $n is the photo number
        
  defined $d->{data}->[ $n ] and do {
  
   foreach my $i ( 0 .. ( scalar @{ $d->{data}->[ $n ] } - 1 ) ) {
  
    my $p = $i + 1; # $p is the position number within the photo
    
    my $sid = get_sid ( 'text', 
     $d->{data}->[ $n ]->[ $i ]->[ 0 ],
     $d->{data}->[ $n ]->[ $i ]->[ 0 ],
     $d->{data}->[ $n ]->[ $i ]->[ 1 ],
     $d->{data}->[ $n ]->[ $i ]->[ 1 ]
    );
    
    load_exec ( 'inpos_ins', $aid, $n, $p, $sid );
    
    my $hash;
   
    defined ( $hash = $d->{data}->[ $n ]->[ $i ]->[ 2 ] ) and do {
   
     foreach my $key ( keys  %{ $hash } ) {
      
      if ( ref ( $hash->{ $key } ) ) { # is an array, must load elements
     
       foreach my $elem ( @{ $hash->{ $key } } ) {
      
        my $sid = get_sid ( $key, $elem, $elem, $elem, $elem );
      
        load_exec ( 'inpos_ins', $aid, $n, $p, $sid );
      
       }
      
      } else { # only a scalar
     
       my $sid = get_sid ( $key, 
        $hash->{ $key } , $hash->{ $key } , $hash->{ $key }, $hash->{ $key }
       );

       load_exec ( 'inpos_ins', $aid, $n, $p, $sid );
      
      }
      
     }
   
   };
    
  }
 
  };
  
 }
 # loading data exif elements
   
 foreach my $n ( 1 .. ( scalar @{ $d->{exif} } - 1 ) ) {
 
  defined $d->{exif}->[ $n ] and do {
     
   do {
   
    put_exif ( 'data', $aid, $n, $_, $d->{exif}->[ $n ]->{ $_ }  );
       
   } foreach keys %{ $d->{exif}->[ $n ] }; 
           
  }
 
 }
 
}

sub load_post {

 logit ( 
  'truncating orphan values from ' . scalar ( @trnorder ) . ' tables' 
 );
 
 foreach my $trn ( @trnorder ) {
 
  $dbc->do ( $sql->{ $trn . '_trn' } );
 
 }
 
 logit ( 'updating album s' ); 

 load_exec ( 'album_s_null_upd' );

 my $i = 1;
 
 foreach my $aid ( load_exec ( 'album_col' ) ) {
 
  load_exec ( 'album_s_upd', $i++, $aid ); 
 
 }

 logit ( 'updating photo x' );

 load_exec ( 'photo_x_null_upd' );

 $i = 1;

 foreach my $row ( load_exec ( 'photo_all' ) ) {
 
  load_exec ( 'photo_x_upd', $i++, $row->[0], $row->[1] ); 
 
 }

 logit ( 'inserting prim' );

 load_exec ( 'prim_del' ); # delete all previous counts on pri
                                                           
 foreach my $row ( load_exec ( 'pri_meta_all' ) ) {

  load_exec ( 'prim_ins',  @{ $row } );

 } 

 load_exec ( 'secm_del' ); # delete all previous counts on sec

 logit ( 'inserting secm inalbum' );

 foreach my $row ( load_exec ( 'sec_meta_inalbum_all' ) ) {

  logit ( $row->[0] );

  # if first and last albums are the same set the last to null
  $row->[3] eq $row->[4] and $row->[4] = undef;

  load_exec ( 'secm_ins', @{ $row } );

 }

 logit ( 'inserting secm inexiff' );
 
 foreach my $row ( load_exec ( 'sec_meta_inexiff_all' ) ) {
 
  logit ( $row->[0] );

  # if first and last albums are the same set the last to null
  $row->[3] eq $row->[4] and $row->[4] = undef;

  load_exec ( 'secm_ins', @{ $row } );

 }

 logit ( 'inserting secm inpos' );

 foreach my $row ( load_exec ( 'sec_meta_inpos_all' ) ) {

  logit ( $row->[0] );
  
  # if first and last albums are the same set the last to null
  $row->[3] eq $row->[4] and $row->[4] = undef;

  load_exec ( 'secm_ins', @{ $row } );

 }  

}

1;