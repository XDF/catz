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

use feature qw( say );

use parent 'Exporter';

our @EXPORT = qw ( load_begin );

use DBI;

use Catz::Data::Conf;
use Catz::Util::Log qw ( logit );
use Catz::Util::String qw ( trim );

# are we running on windows
my $win = 0;
$^O =~ /win/i and $win = 1;

our $metapath;
our $photopath; 
my $dbconn;

if ( $win ) {
 $metapath = '/www/galleries/0dat';
 $photopath  = '/www/galleries';
 $dbconn = 'dbi:SQLite:dbname=/catz/db/master.db';
} else {
 die "not on win, unable do work";
}

# defined what meta files should be loaded and also the loading order
our @metafiles = 


our %cols = (
 breedmeta => 4,
 breedermeta => 4,
 countrymeta => 3,
 newsmeta => 5,
 resultmeta => 1,
 textmeta => 3
);



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
   
 exif_del => 'delete from exif where album=?',
 exif_ins => 'insert into exif (album,n,pri,sec) values (?,?,?,?)',
 exif_sea => 'select n,pri,sec from exif where album=?',
   
 file_del => 'delete from file where album=?',
 file_ins => 'insert into file (album,n,file,width_hr,height_hr,bytes_hr,width_lr,height_lr,bytes_lr) values (?,?,?,?,?,?,?,?,?)',

 snip_del => 'delete from snip where album=?',
 snip_spec_del => 'delete from snip where album=? and pri=?', 
 snip_ins => 'insert into snip (album,n,p,pri,pri_sort,sec_en,sec_sort_en,sec_fi,sec_sort_fi) values (?,?,?,?,?,?,?,?,?)',
 
 x_del => 'delete from x',
 x_ins => 'insert into x (album,n) select album,n from file order by album desc, n asc', 
  
);

my %stm;

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

# static database connection initialized at 
# the beginning and closed at the end
my $dbc;  

sub load_begin {

 my $dbfile = shift;
 
 logit ( "connecting database '$dbfile'" );

 $dbc = DBI->connect( 
  conf ( 'dbconn' ) . $dbfile , '', '', conf ( 'dbargs_load' ) 
 )  or die "unable to connect to database $dbfile: $DBI::errstr";

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

 my ( $class, $item, $dnew, $dt ) = @_;
 
 my $dold = run ( 'dna_se1', $class, $item ) // 'undef';
  
 if ( $dold eq 'undef' ) {
  
  run ( 'dna_ins', $dnew, $dt, $class, $item  );
 
 } else {
 
  run ( 'dna_upd', $dnew, $dt, $class, $item );
 
 }
   
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