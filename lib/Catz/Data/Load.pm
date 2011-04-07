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
 load_simple load_complex load_pprocess load_secondary 
);

use feature qw ( switch );

use Data::Dumper;
use DBI;

use Catz::Data::Conf;
use Catz::Data::Parse;
use Catz::Util::Data qw ( exifsort fixgap lens tolines topiles );
use Catz::Util::Time qw ( dtexpand );
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
 
 dna_del => 'delete from dna where class=? and item=?',
 dna_one => 'select dna from dna where class=? and item=?',
 dna_ins => 'insert into dna (dna,dt,class,item) values (?,?,?,?)',
 dna_upd => 'update dna set dna=?, dt=? where class=? and item=?', 
 dna_trn =>  "delete from dna where class='album' and item not in ( select album from album )",
  
 album_col => 'select album from album order by album',
 album_del => 'delete from album where album=?',
 loc_row => 'select loc_en,loc_fi from album where album=?',
 album_ins => 'insert into album (album,name_en,name_fi,origined,created,modified,loc_en,loc_fi,nat) values (?,?,?,?,?,?,?,?,?)',
  
 org_del => 'delete from org where album=?',
 org_ins => 'insert into org (album,org_en,org_fi) values (?,?,?)',
 org_row => 'select org_en,org_fi from org where album=?',
 org_trn => 'delete from org where album not in ( select album from album )', 
  
 umb_del => 'delete from umb where album=?',
 umb_ins => 'insert into umb (album,umb_en,umb_fi) values (?,?,?)',
 umb_row => 'select umb_en,umb_fi from umb where album=?',
 umb_trn => 'delete from umb where album not in ( select album from album )',
 
 photo_one => 'select count(*) from photo where album=? and n=?',
 photo_del => 'delete from photo where album=?',
 photo_ins => 'insert into photo (album,n,file,width_hr,height_hr,bytes_hr,width_lr,height_lr,bytes_lr) values (?,?,?,?,?,?,?,?,?)',
 max_n_one => 'select max(n) from photo where album=?', 

 dexif_del => 'delete from dexif where album=?',
 dexif_ins => 'insert into dexif (album,n,key,val) values (?,?,?,?)',
 dexif_all => 'select n,key,val from dexif where album=? order by n,key',
 dexif_trn => 'delete from dexif where album not in ( select album from album )',
   
 fexif_del => 'delete from fexif where album=?',
 fexif_ins => 'insert into fexif (album,n,key,val) values (?,?,?,?)',
 fexif_all => 'select n,key,val from fexif where album=? order by n,key',
 fexif_trn => 'delete from fexif where album not in ( select album from photo )',
 
 mexif_del => 'delete from mexif where album=?',
 mexif_ins => 'insert into mexif (album,n,key,val) values (?,?,?,?)',
 mexif_all => 'select n,key,val from mexif where album=? order by n,key',
   
 snip_del => 'delete from snip where album=?', 
 snip_ins => 'insert into snip (album,n,p,sid) values (?,?,?,?)',
 snip_trn => 'delete from snip where album not in ( select album from album )', 
 
 sec_one => 'select sid from sec where pid=? and sec_en=?', 
 # strongly assuming that pid, sec_en uniquely identifies an row
 sec_ind => 'insert into sec (pid,sec_en,sort_en,sec_fi,sort_fi) values (?,?,?,?,?)',
 sec_trn => 'delete from sec where ( pid not in (select pid from pri) ) or ( sid not in ( select sid from snip ) )',

 pri_one => 'select pid from pri where pri=?',
 
 exif_keys_col => 'select key from dexif where album=? and n=? union select key from fexif where album=? and n=? union select key from mexif where album=? and n=?',  
 dexif_val_one => 'select val from dexif where album=? and n=? and key=?',
 fexif_val_one => 'select val from fexif where album=? and n=? and key=?',
 mexif_val_one => 'select val from mexif where album=? and n=? and key=?'
  
};

# defined the correct table truncation order
# only tables defined here will be trunacated
# (if there is _trn SQL but the table is not here the SQL is not used)
my @trnorder = qw ( dna dexif fexif snip sec umb org ); 

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
  
 logit ( "storing run dt '$dt'" );
  
 load_exec ( 'run_ins', $dt ); 
 
}

sub load_end {

 my $vacuum = 0; # default is not to vacuum
 
 # for every fifth run do vacuum 
 ( load_exec ( 'run_count_one' ) % 5 == 0 ) and $vacuum = 1;
   
 logit ( 'finishing statements' );
 
 foreach ( keys %{ $stm } ) { $stm->{$_}->finish }
 
 logit ( 
  'truncating orphan values from ' . scalar ( @trnorder ) . ' tables' 
 );
 
 foreach my $trn ( @trnorder ) {
 
  $dbc->do ( $sql->{ $trn . '_trn' } );
 
 }  
 
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
 
 #logit ( "$key " . join ( '-', @args ) );
  
 $stm->{$key}->execute ( @args );
 
 given ( $key ) {
 
  when ( /one$/ ) { return $stm->{$key}->fetchrow_array }
  
  when ( /row$/ ) { return $stm->{$key}->fetchrow_array }
  
  when ( /col$/ ) { # there is no fetchcol_array or fetchcol_arrayref 
  
   my $arr = $stm->{$key}->fetchall_arrayref;
   
   my @out = map { $_->[0] } @{ $arr };
   
   return @out; 
  
  }
  
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
   
   load_exec ( 'dna_del', $class, $item );
   load_exec ( 'dna_ins', $dnanew, $dt, $class, $item );
   
   return 1;
     
  }
  
 } else {
 
  logit ( "DNA not found for '$class' '$item', the new DNA is '$dnanew'" ); 

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
  
  my $exif = exif ( $album, $photo );
  
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

sub get_sid {

 my ( $pri, $sec_en, $sort_en, $sec_fi, $sort_fi ) = @_;
  
 my $pid = load_exec ( 'pri_one', $pri );
 
 defined $pid or die "unknown pri '$pri'";
 
 my $sid = load_exec ( 'sec_one', $pid, $sec_en );
 
 defined $sid or $sid = load_exec ( 
  'sec_ind', $pid, $sec_en, $sort_en, $sec_fi, $sort_fi  
 );

 return $sid; 
  
}

sub load_complex {

 my ( $album, $data ) = @_;
 
 my $d = parse_pile ( $data );
  
 # $d should then contain completely parsed and processed album data
 # ready to be iterated over and inserted into the database  
 
 load_exec ( 'album_del', $album );
 load_exec ( 
  'album_ins', $album, $d->{name_en}, $d->{name_fi}, $d->{origined},
  $d->{created}, $d->{modified}, $d->{loc_en}, $d->{loc_fi}, 
  $d->{nat}
 );

 load_exec ( 'org_del', $album ); 
 load_exec ( 'org_ins', $album, $d->{org_en}, $d->{org_fi} );

 load_exec ( 'umb_del', $album );
 load_exec ( 'umb_ins', $album, $d->{umb_en}, $d->{umb_fi} );
 
 # loading data elements
 
 load_exec ( 'snip_del', $album );
 
 # inserting general elements common to all photos in an album
 # n = 0, undefined photo
 # p = 0, undefinied position in photo
 
 load_exec ( 'snip_ins', $album, 0, 0,  
  get_sid ( 'date', 
   dtexpand ( $d->{origined}, 'en' ), $d->{origined}, 
   dtexpand ( $d->{origined}, 'fi' ), $d->{origined} 
  )
 );
 
 foreach my $key ( qw ( loc org umb ) ) {
 
  load_exec ( 'snip_ins', $album, 0, 0,  
   get_sid ( $key, 
    $d->{$key . '_en'}, $d->{$key . '_en'}, 
    $d->{$key . '_fi'}, $d->{$key . '_fi'} 
   )
  );
 
 }
 
 foreach my $n ( 1 .. ( scalar @{ $d->{data} } - 1 ) ) {
 
  # $n is the photo number
        
  defined $d->{data}->[ $n ] and do {
  
   my $isphoto = load_exec ( 'photo_one', $album, $n );
   
   # skip on debugging !!!!!!!!!!!!!!
   # $isphoto or die "photo doesn't exists '$album' '$n'";

   foreach my $i ( 0 .. ( scalar @{ $d->{data}->[ $n ] } - 1 ) ) {
  
    my $p = $i + 1; # $p is the position number within the photo
    
    my $sid = get_sid ( 'out', 
     $d->{data}->[ $n ]->[ $i ]->[ 0 ],
     $d->{data}->[ $n ]->[ $i ]->[ 0 ],
     $d->{data}->[ $n ]->[ $i ]->[ 1 ],
     $d->{data}->[ $n ]->[ $i ]->[ 1 ]
    );
    
    load_exec ( 'snip_ins', $album, $n, $p, $sid );
    
    my $hash;
   
    defined ( $hash = $d->{data}->[ $n ]->[ $i ]->[ 2 ] ) and do {
   
     foreach my $key ( keys  %{ $hash } ) {
      
      if ( ref ( $hash->{ $key } ) ) { # is an array, must load elements
     
       foreach my $elem ( @{ $hash->{ $key } } ) {
      
        my $sid = get_sid ( $key, $elem, $elem, $elem, $elem );
      
        load_exec ( 'snip_ins', $album, $n, $p, $sid );
      
       }
      
      } else { # only a scalar
     
       my $sid = get_sid ( $key, 
        $hash->{ $key } , $hash->{ $key } , $hash->{ $key }, $hash->{ $key }
       );

       load_exec ( 'snip_ins', $album, $n, $p, $sid );
      
      }
      
     }
   
   }; 
  }
 
  };
  
  
 }
 # loading data exif elements
 
 load_exec ( 'dexif_del', $album );
  
 foreach my $n ( 1 .. ( scalar @{ $d->{exif} } - 1 ) ) {
 
  defined $d->{exif}->[ $n ] and do {
     
   do {
    load_exec ( 'dexif_ins', $album, $n, $_, $d->{exif}->[ $n ]->{ $_ }  ) 
   } foreach keys %{ $d->{exif}->[ $n ] }; 
           
  }
 
 }
 
}

sub load_pprocess {

 # postprocessing currently means processing of exifs

 my $loaded = shift;
 
 foreach my $album ( sort keys %{ $loaded } ) {
 
  my $max = load_exec ( 'max_n_one', $album );
  
  defined $max or die "unable to detect photo count for album '$album'";
   
  foreach my $n ( 1 .. $max ) {
  
   my @keys = load_exec ( 'exif_keys_col', $album, $n, $album, $n, $album, $n );
   
   #$album eq '20050917kuopio' and $n == 266 and logit ( join '-', @keys );
   
   foreach my $key ( @keys ) { 
   
    my $val = load_exec ( 'dexif_val_one', $album, $n, $key );
 
    $val or $val = load_exec ( 'mexif_val_one', $album, $n, $key ); 
    
    $val or $val = load_exec ( 'fexif_val_one', $album, $n, $key );
    
    #$album eq '20050917kuopio' and $n == 266 and logit ( "$key=$val" );
    
    $val or die "exif prosessing error '$album' '$n' '$key'";
    
    my $sort = exifsort ( $key, $val );
    
    load_exec ( 'snip_ins', $album, $n, 0, # p = position = 0, unspecified  
     get_sid ( $key, $val, $sort, $val, $sort )
    );
        
   }
   
  }

 }

}

my @secondary = (

 qq{ drop table if exists _x },
 
 qq{ create table _x ( x integer primary key not null, album text not null, 
 n integer not null) },
  
 qq{ insert into _x ( album, n ) select album,n from photo order by
 album desc,n asc },
 
 qq{ create index _x_ix1 on _x ( album, n ) },
 
 qq{ drop table if exists _pri_sec_count },
 
 qq{ create table _pri_sec_count ( pri text not null, sort_pri integer not null, 
  sec_en text not null, sort_en text not null, sec_fi text not null, sort_fi text not null, 
  count integer not null, min_x integer not null, album text not null,
  n integer not null ) },
  
 qq { insert into _pri_sec_count ( pri,sort_pri,sec_en,sort_en,sec_fi,sort_fi,count,
  min_x,album,n ) select pri,sort_pri,sec_en,sort_en,sec_fi,sort_fi,
  count(distinct x),min(x),_x.album,_x.n from 
  pri natural join sec natural join snip, _x where sort_pri<10000
  and snip.album=_x.album and (snip.n=_x.n or snip.n=0)
  group by pri,sec_en,sec_fi order by count(distinct x) desc,
  sort_pri asc,sort_en asc,sort_fi asc },
  # sorting is vital: rows are stored in the order they are later fetched
  # by 'order by rowid' to speed up the performance
 
 qq{ drop table if exists _pri_count },
 
 qq{ create table _pri_count ( pri text,sort_pri integer,count integer,
  coverage integer ) },
 
 qq{ insert into _pri_count ( pri,sort_pri,count,coverage ) select pri,
  sort_pri,count(distinct sec_en),count(distinct x) from pri natural join 
  sec natural join snip natural join _x where sort_pri<10000 group by pri 
  order by sort_pri }, 
  
 # delete old breed secondaries
 qq{ delete from sec where pid in ( select pid from pri where pri='breed' ) },
 
 # first inserting all breeds as secondaries
 qq{ insert into sec ( pid, sec_en, sort_en, sec_fi, sort_fi ) select 
 pid, breed_en, breed_en, breed_fi, breed_fi from mbreed, pri where
 pri='breed' },
 
 # delete all old breed information (and also other orphans if any)
 qq{ delete from snip where sid not in ( select sid from sec ) },
  
 # then creating a snip for each ems3 counterpart, this is kinda tricky :-D
 # what effectively happens that every ems3 data loaded based on the data
 # gets duplicated so that there is a correct breed snip for it
 qq{ insert into snip (album,n,p,sid) select a.album,a.n,a.p,d.sid from snip 
 a inner join sec b on (a.sid=b.sid) inner join mbreed c on (b.sec_en=c.ems3)
 inner join sec d on (c.breed_en=d.sec_en) inner join pri e on (d.pid=e.pid)
 inner join pri f on (b.pid=f.pid) where e.pri='breed' and f.pri='ems3' },

 # creating pre-orderder listings to be able to show lists faster at runtime
 qq { drop table if exists _list },
 
 qq { create table _list (ord text,lang text,pri text,sec text,
  count integer, album text,n integer) },
 
 qq { insert into _list select 'a2z','en',pri,sec,count,album,n from (
  select pri,sec_en as sec,count(distinct x) as count,min(x),
  _x.album,_x.n from pri natural join snip natural join sec
  natural join _x where pri not in ( 'dt', 'out' )
  group by pri,sec_en ) order by sort_pri,sort_en },    

 qq { insert into _list select 'top','en',pri,sec,count,album,n from (
  select pri,sec_en as sec,count(distinct x) as count,min(x),
  _x.album,_x.n from pri natural join snip natural join sec
  natural join _x where pri not in ( 'dt', 'out' )
  group by pri,sec_en ) order by sort_pri,count desc,sort_en },
  
 qq { insert into _list select 'a2z','fi',pri,sec,count,album,n from (
  select pri,sec_fi as sec,count(distinct x) as count,min(x),
  _x.album,_x.n from pri natural join snip natural join sec
  natural join _x where pri not in ( 'dt', 'out' )
  group by pri,sec_fi ) order by  sort_pri,sort_fi },    

 qq { insert into _list select 'top','fi',pri,sec,count,album,n from (
  select pri,sec_fi as sec,count(distinct x) as count,min(x),
  _x.album,_x.n from pri natural join snip natural join sec
  natural join _x where pri not in ( 'dt', 'out' )
  group by pri,sec_fi ) order by sort_pri,count desc,sort_fi },
  
 qq { create index _list_ix1 on _list(ord,lang,pri) },  
   
);

sub load_secondary {

 do { $dbc->do( $_ ) } foreach @secondary;

}

1;