#
# The MIT License
# 
# Copyright (c) 1994-2011 Heikki Siltala
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
 $dbconn = 'dbi:SQLite:dbname=/catz/db/data.db';
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
 
 dna_sel => 'select dna from dna where class=? and item=?',
 dna_ins => 'insert into dna (dna,dt,class,item) values (?,?,?,?)',
 dna_upd => 'update dna set dna=?, dt=? where class=? and item=?', 
 
 section_trn => 'delete from section',
 section_ins => 'insert into section (section_en,section_fi,album) values (?,?,?)',
 
 album_all_sel => 'select album from album natural join section order by s asc',
 
 album_del => 'delete from album where album=?',
 album_ins => 'insert into album (album,name_en,name_fi,desc_en,desc_fi,liberty,years,lensmode,created,modified,origined,location_en,location_fi,country,organizer_en,organizer_fi,umbrella_en,umbrella_fi) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
 
 flesh_sel => 'select fid from flesh where album=? and n=?',
 flesh_test_sel => 'select count(*) from flesh where fid=?',
 flesh_ins => 'insert into flesh (album,n) values (?,?)',
 
 flesh_line_del => 'delete from flesh_line where fid in ( select fid from flesh where album=? )',
 flesh_line_ins => 'insert into flesh_line (fid,lid) values (?,?)',

 exid_del => 'delete from exid where fid in ( select fid from flesh where album=? )',
 exid_ins => 'insert into exid (fid,flen,etime_txt,etime_num,fnum,dt,iso,body,lens) values (?,?,?,?,?,?,?,?,?)',

 exif_del => 'delete from exif where fid in ( select fid from flesh where album=? )',
 exif_ins => 'insert into exif (fid,flen,etime_txt,etime_num,fnum,dt,iso,body,lens) values (?,?,?,?,?,?,?,?,?)',
 
 photo_del => 'delete from photo where fid in ( select fid from flesh where album=? )',
 photo_ins => 'insert into photo (fid,file,width_hr,height_hr,bytes_hr,width_lr,height_lr,bytes_lr) values (?,?,?,?,?,?,?,?)',
 
 line_sel => 'select lid from line where line=?',
 line_ins => 'insert into line (line) values (?)',
 line_clr => 'delete from line where line not in ( select lid from album )',
 
 snip_sel => 'select sid from snip where snip=?',
 snip_ins => 'insert into snip (snip,out_en,out_fi) values (?,?,?)',
 line_snip_ins => 'insert into line_snip (lid,sid,p) values (?,?,?)',

 part_sel => 'select pid from part where area=? and part=?',
 part_ins => 'insert into part (area,part) values (?,?)',
 snip_part_ins => 'insert into snip_part (sid,pid) values (?,?)',
  
 lensmode_sel => 'select lensmode from album where album=?',
 
 album_orp => 'delete from album where album not in ( select album from section )',
 flesh_orp => 'delete from flesh where album not in ( select album from album )',
 flesh_line_orp => 'delete from flesh_line where fid not in ( select fid from flesh ) or lid not in ( select lid from line )',
 exid_orp => 'delete from exid where fid not in ( select fid from flesh )', 
 line_orp => 'delete from line where lid not in ( select lid from flesh )',
 line_snip_orp => 'delete from line_snip where lid not in ( select lid from line )',
 snip_orp => 'delete from snip where sid not in ( select sid from line_snip )',
 snip_part_orp => 'delete from snip_part where sid not in ( select sid from snip )',
 part_orp => 'delete from part where pid not in ( select pid from snip_part )',
 
 photo_orp => 'delete from photo where fid not in ( select fid from flesh )',
 exif_orp => 'delete from exif where fid not in ( select fid from flesh )',
 
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

our @areas = qw ( ems1 ems3 ems4 ems5 nick breeder cat );

sub run {

 my ( $key, @arg ) = @_;
 
 #say "executing $key";

 $stm { $key }->execute ( @arg );
 
 if ( $key eq 'album_all_sel' ) {
 
  return $stm{ $key };
  
 } elsif ( $key =~ m|sel$| ) {
 
  my $arr = $stm{ $key }->fetchrow_arrayref;
    
  defined $arr and return $$arr[0];
   
  return -1;
  
 } elsif ( $key =~ m|ins$| ) {
 
  return $dbc->func('last_insert_rowid');
 
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

sub trn_orp {

 print "deleting orphans"; 

 foreach my $key ( sort grep { m|_orp$| } keys %stm ) {
 
  $key =~ m|^(.+)\_|;
  
  print " $1"; 
 
  run ( $key );
 
 }
  
 print "\n";

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

sub line_flesh_put {

 my ( $album, $n, $line ) = @_;
 
 
}


1;