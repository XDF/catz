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
use Catz::Util::Number qw ( fullnum33 );
use Catz::Util::String qw ( trim );

# static database connection initialized at 
# the beginning of load and closed at the end of load
my $dbc;

sub run {

 my ( $comm, $sql, @args ) = @_;
  
 my $res;
 
 given ( $comm ) {
  
  when ( 'one' ) {
  
   my $arr = $dbc->selectrow_arrayref( $sql, undef, @args );
  
   $res = $arr->[0];
  
  }
  
  when ( 'row' ) {
  
   $res = $dbc->selectrow_arrayref( $sql, undef, @args );

  }
  
  when ( 'col' ) {
  
   $res = $dbc->selectcol_arrayref( $sql, undef, @args );
  
  }
  
  when ( 'all' ) {
  
   $res = $dbc->selectall_arrayref( $sql, undef, @args );
  
  }
 
  default { die "unknown database command '$comm'" }
 
 }

 return $res;

}

sub stm { $dbc->do($_[0]) }

sub stmx { $dbc->do($_[0]); return $dbc->func('last_insert_rowid') }

sub one { run('one',@_) }

sub row { run('row',@_) }

sub col { run('col',@_) }

sub all { run('all',@_) }

sub load_begin {

 my ( $dt, $dbfile ) = @_;
  
 logit ( "connecting '$dbfile'" );

 $dbc = DBI->connect( 
  conf ( 'dbconn' ) . $dbfile , '', '', conf ( 'dbargs_load' ) 
 )  or die "unable to connect to '$dbfile': $DBI::errstr";

 logit ( "storing run dt '$dt'" );
  
 stm( 'insert into run(dt) values (?)', $dt );
 
 logit ('done'); 
 
}

sub load_end {

 my $vacuum = 0; # default is not to vacuum
 
 my $runs = $dbc->selectrow_array('select count(*) from run');
  
 # for every fifth run do vacuum 
 ( $runs % 5 == 0 ) and $vacuum = 1;
   
 
 logit ( 'truncating orphan albums' );
 stm(qq{delete from album where albumid not in 
  (select albumid from photo)});
 
 logit ( 'truncating orphan objects' );
 stm(qq{delete from object where objectid not in (
   select objectid from inalbum union all
   select objectid from inphoto union all
   select objectid_meta from inexif union all
   select objectid_data from inexif union all
   select objectid_file from inexif union all
   select objectid from inposition)});
 
 logit ( 'committing' );
 $dbc->commit;
 
 logit ( 'analyzing' );
 stm( 'analyze' );
 
 if ( $vacuum ) {
  logit ( 'vacuuming' );
  {  
   local $dbc->{AutoCommit} = 1; 
   do( 'vacuum' );
  }
 }
 logit ( 'disconnecting' );
 $dbc->disconnect;  

}

sub load_nomatch {

 # checks if DNA matches, if it doesn't then store the new DNA

 # returns true if no match = something to do 
 # returns false if match = nothing to do
 
 my ( $class, $item, $dnanew ) = @_;
 
 # the current run is the latest run
 my $dt = one('select max(dt) from run');
 
 # 
 my $dnaold = one(qq{select dna from dna where class=? and item=?},
  $class,$item);
 
 if ( defined $dnaold ) {
 
  if ( $dnaold eq $dnanew ) {

   logit ( "DNA match '$class' '$item' '$dnanew'" ); 
   
   return 0;  
  
  } else {
  
   logit ( "DNA mismatch '$class' '$item' '$dnaold' '$dnanew'" );
   
   stm('update dna set dna=?,dt=? where class=? and item=?',
    $dnanew,$dt,$class,$item);

   return 1;
     
  }
  
 } else {
 
  logit ( "DNA not found '$class' '$item' '$dnanew'" ); 

  stm('insert into dna(class,item,dna,dt) values (?,?,?,?)',
   $class,$item,$dnanew,$dt);

  return 1;
 
 }
  
}

sub obj {

 my ( $subject, $obj_en, $sort_en, $obj_fi, $sort_fi ) = @_;
 
 my $subjectid = one('select subjectid from subject where subject=?',$subject);

 defined $subjectid or die "subject '$subject' is unknown";

 # redundant values are converted to null
 $sort_fi eq $obj_fi and $sort_fi = undef;
 $obj_fi eq $obj_en and $obj_fi = undef;
 $sort_en eq $obj_en and $sort_en = undef;
  
 my $objectid = one(qq{select objectid from object where subjectid=? 
  and object_en=?},$subjectid,$obj_en);
  
 if ( defined $objectid ) {  
 
  # we do an update even there is really nothing to update
  stm(qq{update object set object_en=?,sort_en=?,object_fi=?,sort_fi=?
   where objectid=?},$obj_en,$sort_en,$obj_fi,$sort_fi,$objectid);
 
 } else { # new object
  
  $objectid = stmx(qq{insert into object(subjectid,object_en,sort_en,object_fi,
   sort_fi) values (?,?,?,?,?)});
 
 }
 
 return $objectid; 

}

sub load_folder {

 my $folder = shift;
 
 my $album = pathcut ( $folder );
 
 my @photos = fixgap ( findphotos ( $folder ) );

 logit ('loading '. scalar @photos . " photos from '$folder'" );
 
 my $albumid = one('select albumid from album where folder=?',$album);
 
 defined $albumid or do { # new album
 
  $albumid = stmx('insert album(folder) values (?)',$album);

 };
 
 # deleteting photos that are "out of scope"
 stm('delete from photo where albumid=? and n>?',$albumid,scalar @photos);
 
 my $n = 1; # photos are numbered starting from 1
 
 foreach my $photo (@photos) {

  my $file = filehead ( $photo );
             
  my $thumb = filethumb ( $photo );

  -f $thumb or die "missing thumbnail file '$thumb'";  
   
  my ( $hwidth, $hheight ) = widthheight( $photo );
  
  my $hbytes = filesize ( $photo );
  
  my ( $lwidth, $lheight ) = widthheight( $thumb );
  
  my $lbytes = filesize ( $thumb );

  my $photoid = one('select photoid from photo where albumid=? and n=?',
   $albumid, $n );
   
  if ( defined $photoid ) {
  
   # we do an update even there is really nothing to update
   
   stm(qq{update photo set file=?,hwidth=?,hheight=?,hbytes=?,lwidth=?,
    lheight=?,lbytes=? where photoid=?},$file,$hwidth,$hheight,$hbytes,$lwidth,
    $lheight,$lbytes,$photoid);
  
  } else {
  
   $photoid = stmx(qq{insert into photo(file,n,hwidth,hheight,hbytes,lwidth,
   lheight,lbytes) values (?,?,?,?,?,?,?,?)},$file,$n,$hwidth,$hheight,
    $hbytes,$lwidth,$lheight,$lbytes,$photoid);  
  
  }
  
  my $exif = exif ( $album, $photo );
  
 }
 
}

1; 
  
__END__
  
  foreach my $key ( keys %{ $exif } ) {
  
   my $objectid = obj ( $_,  $exif -> { $_ },  $exif -> { $_ },  
    $exif -> { $_ },  $exif -> { $_ } );
    
   if ( one('select count(*) from inexif where photoid=? and objectid_file=?',
    $photoid,$objectid ) ) { # insert new
    
    do('insert into inexif(photoid,objectid_file')
    
    
   } else { # update 
   
    do 
   
   } 
  
  }
  
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
 
 # albums must be inserted from oldest to newest in order this to generate
 # collect order numbers to S
 my $s = load_exec ( 'album_count_one' ) + 1;
 
 load_exec ( 
  'album_ins', $album, $s, $d->{name_en}, $d->{name_fi}, $d->{origined},
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
  get_sid ( 'album', $album, $album, $album, $album )
 );
 
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
 
 qq{ create table _x (x integer primary key not null, album text not null, 
  n integer not null, id text not null) },
  
 qq{ insert into _x (album,n,id) select album,n,makeid(s,n) from photo 
  natural join album order by s desc,n asc },
 
 qq{ create index _x_ix1 on _x ( album, n ) },
 qq{ create index _x_ix2 on _x ( id ) },
 
 qq{ drop table if exists _photo },
 
 qq{ create table _photo (x integer primary key not null, id text not null,   
  album text not null, file text not null, width_hr not null, height_hr not
  null, bytes_hr not null, width_lr not null, height_lr not null, bytes_lr
  not null)},
  
 qq{ insert into _photo (x,id,album,file,width_hr,height_hr,bytes_hr,width_lr,
  height_lr,bytes_lr) select x,id,album,file,width_hr,height_hr,bytes_hr,
  width_lr,height_lr,bytes_lr from photo natural join _x order by x },
  
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

 # delete old cuntry secondaries
 qq{ delete from sec where pid in ( select pid from pri where pri='nat' ) },
 
 # inserting all countries as secs
 qq{ insert into sec ( pid, sec_en, sort_en, sec_fi, sort_fi )
 select pid, nat_en, nat_en, nat_fi, nat_fi from mbreeder
 natural join mnat,pri where pri='nat' group by pid,nat_en,nat_fi },
 
  # delete all old country information (and also other orphans if any)
 qq{ delete from snip where sid not in ( select sid from sec ) },
 
 # and then duplicating every breeder snip to a nat snip  
 qq{ insert into snip (album,n,p,sid) select c.album,c.n,c.p,f.sid from pri a 
 natural join sec b natural join snip c inner join mbreeder d on 
 (b.sec_en=d.breeder) natural join mnat e inner join sec f on
 (e.nat_en=f.sec_en) inner join pri g on (f.pid=g.pid) where 
 a.pri='breeder' and g.pri='nat' },
    
 qq{ drop table if exists _pri_sec_count },
 
 qq{ create table _pri_sec_count ( pri text not null, sort_pri integer not null, 
  sec_en text not null, sort_en text not null, sec_fi text not null, sort_fi text not null, 
  count integer not null, x integer not null ) },
  
 qq { insert into _pri_sec_count ( pri,sort_pri,sec_en,sort_en,sec_fi,sort_fi,count,
  x ) select pri,sort_pri,sec_en,sort_en,sec_fi,sort_fi,
  count(distinct x),min(x) from pri natural join sec natural join snip join _x 
  where sort_pri<10000 and snip.album=_x.album and (snip.n=_x.n or snip.n=0)
  group by pri,sec_en,sec_fi order by count(distinct x) desc,
  sort_pri asc,sort_en asc,sort_fi asc },
  # sorting is vital: rows are stored in the order they are later fetched
  # by 'order by rowid' to speed up the performance
 
 qq{ drop table if exists _pri_count },
 
 qq{ create table _pri_count ( pri text,sort_pri integer,count integer,
  coverage integer ) },
 
 qq{ insert into _pri_count ( pri,sort_pri,count,coverage ) select pri,
  sort_pri,count(distinct sec_en),count(distinct x) from pri natural join 
  sec natural join snip join _x where sort_pri<10000 and snip.album=_x.album 
  and (snip.n=_x.n or snip.n=0) group by pri order by sort_pri }, 
   
 # creating pre-orderder listings to be able to show lists faster at runtime
 qq { drop table if exists _list },
 
 qq { create table _list (ord text,lang text,pri text,sec text,
  count integer, x integer) },
 
 qq { insert into _list select 'a2z','en',pri,sec_en,count,min_x from (
  select pri,sort_pri,sec_en,sort_en,count(distinct x) as count,min(x)
  as min_x from pri natural join sec natural join snip join _x where
  sort_pri<10000 and snip.album=_x.album and (snip.n=_x.n or snip.n=0)
  group by pri,sec_en ) order by sort_pri,sort_en },    

 qq { insert into _list select 'top','en',pri,sec_en,count,min_x from (
  select pri,sort_pri,sec_en,sort_en,count(distinct x) as count,min(x)
  as min_x from pri natural join snip natural join sec join _x where 
  sort_pri<10000 and snip.album=_x.album and (snip.n=_x.n or snip.n=0) 
  group by pri,sec_en ) order by sort_pri,count desc,sort_en },
  
 qq { insert into _list select 'a2z','fi',pri,sec_fi,count,min_x from (
  select pri,sort_pri,sec_fi,sort_fi,count(distinct x) as count,min(x)
  as min_x from pri natural join snip natural join sec join _x where 
  sort_pri<10000 and snip.album=_x.album and (snip.n=_x.n or snip.n=0)
  group by pri,sec_fi ) order by sort_pri,sort_fi },    

 qq { insert into _list select 'top','fi',pri,sec_fi,count,min_x from (
  select pri,sort_pri,sec_fi,sort_fi,count(distinct x) as count,min(x)
  as min_x from pri natural join snip natural join sec join _x where 
  sort_pri<10000 and snip.album=_x.album and (snip.n=_x.n or snip.n=0)
  group by pri,sec_fi ) order by sort_pri,count desc,sort_fi },
  
 qq { create index _list_ix1 on _list(ord,lang,pri) },
   
);

sub load_secondary {

 do { $dbc->do( $_ ) } foreach @secondary;

}

1;