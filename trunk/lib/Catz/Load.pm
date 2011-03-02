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
package Catz::Load;

use strict;
use warnings;

use DBI;

use feature qw( say );

use List::MoreUtils qw ( pairwise );

use Catz::Util qw ( trim );

# are we running on windows
my $win = 0;
$^O =~ /win/i and $win = 1;

our $metapath;
our $photopath; 
my $dbconn;

# hard-cded values for initial testing
if ( $win ) {
 $metapath = '/www/galleries/0dat';
 $photopath  = '/www/galleries';
 $dbconn = 'dbi:SQLite:dbname=/catz/db/master.db';
} else {
 die "not on win, unable do work";
}

our @metafiles = qw ( breedmeta breedermeta countrymeta resultmeta gallerymeta newsmeta textmeta );

our %cols = (
 breedmeta => 4,
 breedermeta => 4,
 countrymeta => 3,
 newsmeta => 5,
 resultmeta => 1,
 textmeta => 3
);

our $dbargs = { AutoCommit => 0, RaiseError => 1, PrintError => 1 };

say "connecting $dbconn";

our $dbc = DBI->connect( $dbconn,'','',$dbargs ) 
 or die "unable to connect $dbconn: $DBI::errstr";

my %sql = (

 run_ins => 'insert into run values (?)', 
 
 dna_se1 => 'select dna from dna where class=? and item=?',
 dna_ins => 'insert into dna (dna,dt,class,item) values (?,?,?,?)',
 dna_upd => 'update dna set dna=?, dt=? where class=? and item=?', 
  
 album_all_sel => 'select album from album order by album asc',
 
 album_del => 'delete from album where album=?',
 album_ins => 'insert into album (album,name_en,name_fi,lensmode,origined,created,modified,location_en,location_fi,country) values (?,?,?,?,?,?,?,?,?,?)',
 
 lensmode_se1 => 'select lensmode from album where album=?',
 
 organizer_del => 'delete from organizer where album=?',
 organizer_ins => 'insert into organizer (album,organizer_en,organizer_fi) values (?,?,?)', 
  
 umbrella_del => 'delete from umbrella where album=?',
 umbrella_ins => 'insert into umbrella (album,umbrella_en,umbrella_fi) values (?,?,?)', 
 
 lensmode_sel => 'select lensmode from album where album=?',
 
 flesh_del => 'delete from flesh where album=?',
 flesh_ins => 'insert into flesh (album,n,file) values (?,?,?)',
 flesh_se1 => 'select max(n) from flesh where album=?',
  
 exid_del => 'delete from exid where album=?',
 exid_ins => 'insert into exid (album,n,flen,etime_txt,etime_num,fnum,dt,iso,body,lens) values (?,?,?,?,?,?,?,?,?,?)',
 exid_ser => 'select flen,etime_txt,etime_num,fnum,dt,iso,body,lens from exid where album=? and n=?',

 exif_del => 'delete from exif where album=?',
 exif_ins => 'insert into exif (album,file,flen,etime_txt,etime_num,fnum,dt,iso,body,lens) values (?,?,?,?,?,?,?,?,?,?)',
 exif_ser => 'select flen,etime_txt,etime_num,fnum,dt,iso,body,lens from exif natural join flesh where album=? and n=?',
  
 exia_del => 'delete from exia where album=? and n=?',
 exia_ins => 'insert into exia (album,n,flen,etime_txt,etime_num,fnum,dt,iso,body,lens) values (?,?,?,?,?,?,?,?,?,?)',
 
 file_del => 'delete from file where album=?',
 file_ins => 'insert into file (album,file,width_hr,height_hr,bytes_hr,width_lr,height_lr,bytes_lr) values (?,?,?,?,?,?,?,?)',

 out_del => 'delete from out where album=?',
 out_ins => 'insert into out (album,n,out_en,out_fi) values (?,?,?,?)', 

 snip_del => 'delete from snip where album=?',
 snip_ins => 'insert into snip (album,n,pri,sec) values (?,?,?,?)',
 
 x_del => 'delete from x',
 x_ins => 'insert into x (album,n) select album,n from flesh order by album desc, n asc', 
  
);

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

sub run {

 my ( $key, @arg ) = @_;
 
 $stm { $key }->execute ( @arg );
  
 if ( $key =~ m|se1$| ) {
 
  my $arr = $stm{ $key }->fetchrow_arrayref;
  
  defined $arr and return $arr->[0];
  
  return -1; 
    
 } elsif ( $key =~ m|ser$| ) {
 
  my $arr = $stm{ $key }->fetchrow_arrayref;
  
  return $arr
    
 }

} 

sub end {

 my $btime = shift;

 my $etime = time();
 my $ttime = $etime-$btime;

 my $endts = expand_ts(sys_ts());

 say "execution took $ttime seconds";
 say "finished at $endts";

}

sub put_dna {

 my ( $class, $item, $dold, $dnew, $dt ) = @_;
 
 if ( $dold eq '-1' ) {
 
  #say "inserting dna $dnew $dt";
 
  run ( 'dna_ins', $dnew, $dt, $class, $item  );
 
 } else {
 
  #say "updating dna $dnew $dt";
 
  run ( 'dna_upd', $dnew, $dt, $class, $item );
 
 } 
  
}

sub upd_exia {

 my ( $album, $n ) = @_;
 
 run ( 'exia_del', $album, $n );
 
 my $exif = run ( 'exif_ser', $album, $n );
 my $exid = run ( 'exid_ser', $album, $n );
  
 my @res;
  
 if ( defined $exif and defined $exid ) {
  
  my @res = pairwise { defined $a ? $a : $b } @$exid, @$exif;
  run ( 'exia_ins', $album, $n, @res );
   
 } else {
  
  defined $exid and run ( 'exia_ins', $album, $n, @$exid );
  defined $exif and run ( 'exia_ins', $album, $n, @$exif );
   
 } 
 
}

sub upd_x {

 say "updating x"; 

  run ( 'x_del' );
  run ( 'x_ins' );
 
}

sub housekeep {

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


sub file2table {

 $_[0] =~ m|^(.+)meta$|; 
 'meta'.lc($1);

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