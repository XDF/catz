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

package Catz::Load::Loader;

use 5.10.0; use strict; use warnings;

use parent 'Exporter';

our @EXPORT = qw ( 
 load_begin load_end load_exec load_folder load_nomatch 
 load_simple load_exif load_complex load_post load_secondary 
);

use Data::Dumper;
use DBI;

use Catz::Data::List qw ( list_matrix );
use Catz::Load::Data qw ( exifsort exif fixgap lens tolines topiles );
use Catz::Load::Parse;
use Catz::Util::Time qw ( dtexpand );
use Catz::Util::File qw ( filehead filesize filethumb findphotos pathcut );
use Catz::Util::Image qw ( widthheight );
use Catz::Util::Log qw ( logit logadd logdone );
use Catz::Util::Number qw ( fullnum33 );
use Catz::Util::String qw ( trim );

my $sql = { 

 # this hash ref has all SQL statements used by the loader
 # _ins = insert statement
 # _ind = insert statement and return the latest primary key
 # _upd = update statement
 # _del = delete statement
 # _col = select column
 # _all = select more than one column 

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
 
 origin_one => 'select origin from pri where pri=?',
 
 seq_one => 'select seq_init(1)', # initialize sequence to 1
 
 album_null_upd => 'update album set s=null',
 album_col => 'select rowid from album order by fsort(folder)',
 album_upd => 'update album set s=seq_incr() where rowid=?',
 
 photo_null_upd => 'update photo set x=null',
 photo_col => 'select photo.rowid from photo natural join album order by s desc,n asc',
 photo_upd => 'update photo set x=seq_incr() where rowid=?',
 
 origin_one => 'select origin from pri where pri=?',
  
};

my $secsql = [
  
 # creating and populcating pri statistics table 
 qq{drop table if exists _prim},
 qq{create table _prim (pid integer primary key not null,cntpri integer not null)},
 qq{insert into _prim select pid,count(*) from pri natural join sec where sid in ( select sid from inalbum union select sid from inexiff union select sid from inpos ) group by pid},

 # creating and populcating sec statistics table
 # we use special handling of time (moment) where we make sure that a null time doesn't affect the min/max results
 qq{drop table if exists _secm},
 qq{create table _secm (sid integer primary key not null,cntdate integer not null,cntphoto integer not null, first integer not null, last integer not null)},
 qq{insert into _secm select sec.sid,count(distinct substr(folder,1,8)),count(distinct x),replace(min(substr(folder,1,8)||ifnull(moment,'999999')),'999999',''),replace(max(substr(folder,1,8)||ifnull(moment,'000000')),'000000','') from inalbum natural join photo natural join sec natural join pri natural join album where origin='album' group by sec.sid},
 qq{insert into _secm select inexiff.sid,count(distinct substr(folder,1,8)),count(distinct x),replace(min(substr(folder,1,8)||ifnull(moment,'999999')),'999999',''),replace(max(substr(folder,1,8)||ifnull(moment,'000000')),'000000','') from photo natural join inexiff natural join album where sid in ( select sid from inexiff ) group by sid},
 qq{insert into _secm select sec.sid,count(distinct substr(folder,1,8)),count(distinct x),replace(min(substr(folder,1,8)||ifnull(moment,'999999')),'999999',''),replace(max(substr(folder,1,8)||ifnull(moment,'000000')),'000000','') from inpos natural join photo natural join sec natural join pri natural join album where origin='pos' group by sec.sid},

 # instant find requires queries to respond as quick as possible
 # therefore we need these special tables - speed tests were done 2011-05-30 
 # and these tables are really needed
 qq{drop table if exists _find_en},
 qq{drop table if exists _find_fi},
 qq{create table _find_en (sid integer not null, sec text not null)},
 qq{create table _find_fi (sid integer not null, sec text not null)},
 # we use the special ability of SQLite so that we insert rows in certain order
 # and when we use order by rowid on query the order by doesn't cost anything
 # we set synonym secs as -sid = make sid negative
 qq{insert into _find_en select sid,sec from ( select sid,sec,cntphoto,sort from pri natural join _secm natural join sec_en where cntphoto is not null and cntphoto>0 and pri not in ( 'album','folder','text','date' ) union all select sid,dtexpand(sec,'en') as sec,cntphoto,sort from pri natural join _secm natural join sec_en where cntphoto is not null and cntphoto>0 and pri='date' union all select -sid,nat_en,cntphoto,nat_en from pri natural join _secm natural join sec_en,mnat where nat=sec and pri='nat' and cntphoto is not null and cntphoto>0 union all select -sid,breed_en,cntphoto,breed_en from pri natural join _secm natural join sec_en,mbreed where breed=sec and pri='breed' and cntphoto is not null and cntphoto>0 union all select -sid,title_en,cntphoto,title_en from pri natural join _secm natural join sec_en,mtitle where title=sec and pri='title' and cntphoto is not null and cntphoto>0 union all select -sid,feat_en,cntphoto,feat_en from pri natural join _secm natural join sec_en,mfeat where feat=sec and pri='feat' and cntphoto is not null and cntphoto>0 ) order by cntphoto desc, sort asc},
 qq{insert into _find_fi select sid,sec from ( select sid,sec,cntphoto,sort from pri natural join _secm natural join sec_fi where cntphoto is not null and cntphoto>0 and pri not in ( 'album','folder','text','date' ) union all select sid,dtexpand(sec,'fi') as sec,cntphoto,sort from pri natural join _secm natural join sec_fi where cntphoto is not null and cntphoto>0 and pri='date' union all select -sid,nat_fi,cntphoto,nat_fi from pri natural join _secm natural join sec_fi,mnat where nat=sec and pri='nat' and cntphoto is not null and cntphoto>0 union all select -sid,breed_fi,cntphoto,breed_fi from pri natural join _secm natural join sec_fi,mbreed where breed=sec and pri='breed' and cntphoto is not null and cntphoto>0 union all select -sid,title_fi,cntphoto,title_fi from pri natural join _secm natural join sec_fi,mtitle where title=sec and pri='title' and cntphoto is not null and cntphoto>0 union all select -sid,feat_fi,cntphoto,feat_fi from pri natural join _secm natural join sec_fi,mfeat where feat=sec and pri='feat' and cntphoto is not null and cntphoto>0 ) order by cntphoto desc, sort asc},

 # we use sid -> x mapping to execute both pri-sec pair fetches and advanced searches
 # we first look for sids by the pair or search and then map sids to xs with this table
 # xs are then used to create bit vectors 
 qq{drop table if exists _sid_x},
 qq{create table _sid_x (sid integer not null,x integer not null)},
 qq{insert into _sid_x select sid,x from photo natural join inalbum group by sid,x union select sid,x from photo natural join inexiff group by sid,x union select sid,x from photo natural join inpos group by sid,x},
 qq{create index _sid_x1 on _sid_x(sid)},
 qq{create index _sid_x2 on _sid_x(x)},
   
]; 

# defined the correct table truncation order
# only tables defined here will be trunacated
# (if there is _trn SQL but the table is not here the SQL is not used)
my @trnorder = qw ( inexif sec album ); 

my $stm = {}; # variable to hold prepared SQL statements

# static database connection initialized at 
# the beginning and closed at the end
my $dbc;

my $seq = undef;

sub seq_init { $seq = $_[0] // 1 }

sub seq_incr { $seq++ }

sub fsort {

 if ( $_[0] =~ /^(.+)(\d)$/ ) { # if folder ends with a number
 
  # reverse the number for sorting 1 -> 9, 2 -> 8 etc
    
  return $1 . ( 10 - int ( $2 ) ); 
  
 } else { return $_[0] } # as is  

}

sub load_begin {

 my ( $dt, $dbfile ) = @_;
  
 logit ( "connecting database '$dbfile'" );

 $dbc = DBI->connect( 
  'dbi:SQLite:dbname=' . $dbfile , undef, undef, 
  { AutoCommit => 0, RaiseError => 1, PrintError => 1 } 
 )  or die "unable to connect to database $dbfile: $DBI::errstr";

 logit ( 'registering functions' );
  
 # sequence
 $dbc->func( 'seq_init', 1, \&seq_init, 'create_function' );
 $dbc->func( 'seq_incr', 0, \&seq_incr, 'create_function' );
 $dbc->func( 'fsort', 1, \&fsort, 'create_function' );
 $dbc->func( 'dtexpand', 2, \&dtexpand, 'create_function' );

 logit ( 'preparing ' . scalar ( keys %{ $sql } ). ' SQL statements' );
 
 do { $stm->{$_} = $dbc->prepare ( $sql->{$_} ) }
  foreach ( keys %{ $sql } );
    
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

sub load_do { my $sql = shift; $dbc->do ( $sql, undef, @_ ) } 

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
   
   when ( 'mnat' ) {
   
    # verify that a flag file is present
    my $fflag = '../../file/flag/' . lc ( $lines[0] ) . '.gif'; 
    -f $fflag or die "unable to locate flag file '$fflag' for '$lines[0]'"; 
    
   }
   
   when ( 'mnews' ) { # set news URLs to null if not given at all
    $lines[5] or $lines[5] = undef;
    $lines[6] or $lines[6] = undef; 
   }
         
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

 foreach my $key ( qw ( folder album loc org umb ) ) {
 
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

sub relate {

 my ( $source, $target ) = @_;
 
 my $o1 = load_exec('origin_one',$source);
 my $o2 = load_exec('origin_one',$target);

 ( $o1 and $o2 ) or die "internal error in fetching sources for related";

 my $join = undef;
 my $tables = undef;

 given ( $o1 ) {

  when ( 'album' ) {

   $join = 'i1.aid=i2.aid';
   
   if ( $o2 eq 'album' ) {

    $tables = 'inalbum i1,inalbum i2';

   } elsif ( $o2 eq 'exif' ) {

    $tables = 'inalbum i1,inexiff i2';

   } elsif ( $o2 eq 'pos' ) {
    
    $tables = 'inalbum i1,inpos i2';

   }

  }

  when ( 'exif' ) {
   
   $join = 'i1.aid=i2.aid and i1.n=i2.n';
   
   if ( $o2 eq 'album' ) {

    $tables = 'inexiff i1,inalbum i2';
    $join = 'i1.aid=i2.aid';

   } elsif ( $o2 eq 'exif' ) {

    $tables = 'inexiff i1,inexiff i2'; 

   } elsif ( $o2 eq 'pos' ) {
    
    $tables = 'inexiff i1,inpos i2';
   
   }

  }

  when ( 'pos' ) {

   if ( $o2 eq 'album' ) {

    $tables = 'inpos i1,inalbum i2';
    $join = 'i1.aid=i2.aid';

   } elsif ( $o2 eq 'exif' ) {

    $tables = 'inpos i1,inexiff i2';
    $join = 'i1.aid=i2.aid and i1.n=i2.n';

   } elsif ( $o2 eq 'pos' ) {
    
    $tables = 'inpos i1,inpos i2';
    $join = 'i1.aid=i2.aid and i1.n=i2.n and i1.p=i2.p';

   }

  }

 }

 ( $join and $tables ) or die "internal error in creating SQL for related";

 return qq{select i1.sid,i2.sid from $tables where i1.sid in (select sid from sec natural join pri where pri='$source') and i2.sid in (select sid from sec natural join pri where pri='$target') and $join group by i1.sid,i2.sid};
  
}

sub load_post {

 logit ( 'processing secondaries' );

 my $i = 0;
 
 foreach my $tbl ( qw ( album photo ) ) {
 
  load_exec ( $tbl . '_null_upd' ); # clear old s
 
  load_exec ( 'seq_one' ); # initialize sequence to 1 

  do { load_exec ( $tbl . '_upd', $_ ) }
   foreach load_exec ( $tbl . '_col' );

  $i++; logadd ( '.' );
 
 }
  
 load_do('delete from album where aid not in ( select aid from inalbum union select aid from inexif union select aid from inpos union select aid from photo )');
 $i++; logadd ( '.' );
 
 load_do('delete from inexif where sid_meta is null and sid_data is null and sid_file is null');
 $i++; logadd ( '.' );

 load_do('delete from sec where sid not in ( select sid from inalbum union select sid_meta from inexif union select sid_data from inexif union select sid_file from inexif union select sid from inpos)');
 $i++; logadd ( '.' );
 
 # delete & insert nat
 
 load_do("delete from inpos where rowid in (select inpos.rowid from inpos natural join sec where pid=(select pid from pri where pri='nat'))");
  
 load_do("delete from sec where pid=(select pid from pri where pri='nat')");
  
 load_do("insert into sec (pid,sec_en) select (select pid from pri where pri='nat'),nat from sec inner join mbreeder on (sec_en=breeder) where pid=(select pid from pri where pri='breeder') group by nat");
  
 load_do("insert into inpos select aid,n,p,s2.sid from inpos i,sec s1,mbreeder m,sec s2 where i.sid=s1.sid and s1.sec_en=m.breeder and m.nat=s2.sec_en and s1.pid=(select pid from pri where pri='breeder') and s2.pid=(select pid from pri where pri='nat')"); 

 $i++; logadd ( '.' ); 
 
 # adding relations
 
 my $matrix = list_matrix;
 
 load_do('drop table if exists _relate');
 load_do('create table _relate(source integer not null,target integer not null)');
 
 foreach my $source ( grep { $matrix->{$_}->{refines} } keys %{ $matrix } ) {

  foreach my $target ( @{ $matrix->{$source}->{refines} } ) {
  
   my $sql = relate ( $source, $target );
     
   load_do("insert into _relate $sql");
  
   $i++; logadd ( '.' ); 
  
  } 
 
 }
 
 load_do('create index _relate1 on _relate(source)');
 load_do('create index _relate2 on _relate(target)');
    
 foreach my $do ( @$secsql ) { load_do ( $do ); $i++; logadd ( '.' ) }
 
 logdone;

 logit ( "$i secondaries processed" ); 

}

1;