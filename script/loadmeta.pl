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
   
foreach my $file (@Catz::Load::metafiles) {

 my $ffile = $Catz::Load::metapath.'/'.$file.'.txt';
 my $data = readfile($ffile);
 my $table = Catz::Load::file2table($file);
 
 say "FILE $file $ffile " . length ( $data );
 
 my $dold = Catz::Load::run( 'dna_sel', 'FILE', $file );
 my $dnew = dna( $data ); 

 if ( $dold ne $dnew ) {
    
  say "MISMATCH $dold $dnew";
  
  if ( $file eq 'gallerymeta' ) {

   Catz::Load::run ( 'section_trn' );

   my $section_en;
   my $section_fi;
   
   my @newlids = ();
   my @newlines = ();
     
   foreach my $pile ( split /\#/,
    $data ) {
           
    my @lines = Catz::Load::to_lines( $pile );
       
    if( $lines[0] =~ m|^\!(.+)| ) {
      
     my $section = $1;
     
     if( $section =~ m|^(.+)\s+\-\s+(.+)?| ) {
     
      $section_en = $1; $section_fi = $2;
     
     } else {
     
      $section_en = $section; $section_fi = $section;
     } 
     
     shift( @lines );
        
    }
        
    my $album = shift( @lines ) ;
    
    Catz::Load::run ( 'section_ins', $section_en, $section_fi, $album );
    
    my $doldb = Catz::Load::run( 'dna_sel', 'album', $album );
    my $dnewb = dna ( join "\n", @lines );
            
    if ( $doldb ne $dnewb ) {
    
     say "$album MISMATCH $doldb $dnewb";

     my ( $liberty,$years,$lensmode ) = split /\//, shift @lines;
     my ( $created,$modified ) = split /\//, shift @lines; 
     my $name_en = shift @lines;
     my $name_fi = shift @lines;
     my $desc_en = shift @lines;
     my $desc_fi = shift @lines;
     
     my $origined;
     my $location_en;
     my $location_fi;
     my $country;
     my $organizer_en;
     my $organizer_fi;
     my $umbrella_en;
     my $umbrella_fi;
     
     if ( $album =~ /^(20\d\d\d\d\d\d)(.+)$/ ) { 
     
      $origined = $1;
      ( $location_en, $location_fi ) = Catz::Data::location($2);
      $country = Catz::Data::country($location_en);
      ( $organizer_en, $organizer_fi ) = Catz::Data::organizer($name_en);
      defined $organizer_en and ( $umbrella_en, $umbrella_fi ) = Catz::Data::umbrella($organizer_en,$origined);   
     
     }
     
     Catz::Load::run( 'album_del', $album );
     
     Catz::Load::run( 'album_ins', $album, $name_en, $name_fi, $desc_en, $desc_fi, $liberty, $years, $lensmode, $created, $modified, $origined, $location_en, $location_fi, $country, $organizer_en, $organizer_fi, $umbrella_en, $umbrella_fi );

     Catz::Load::run ( 'flesh_line_del', $album );
     Catz::Load::run ( 'exid_del', $album );
             
     foreach my $data (@lines) {
     
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
      
      my $i = $a;
      
      while($i <= $b) {
      
       my $f = Catz::Load::run('flesh_sel', $album, $i );

      ( $f eq '-1' ) and 
        $f = Catz::Load::run( 'flesh_ins', $album, $i );
 
       if ( $def eq 'P' ) {
       
        my $lid = Catz::Load::run('line_sel', $line);
 
        ( $lid == -1 ) and do {
        
          $lid = Catz::Load::run( 'line_ins', $line );
         
          push @newlids, $lid;
          push @newlines, $line;
         
        };
         
        Catz::Load::run( 'flesh_line_ins', $f, $lid );
        
        
       } else { # def eq 'L'
 
        my $exid = Catz::Data::exid( $line );
        
        Catz::Load::run ( 'exid_ins', $f, $$exid{'flen'}, $$exid{'etime_txt'}, $$exid{'etime_num'}, $$exid{'fnum'}, $$exid{'dt'}, $$exid{'iso'}, $$exid{'body'}, $$exid{'lens'} );
        
       }
        
       $i++;
               
      }                  
                 
     }
     
     Catz::Load::put_dna ( 'album', $album, $doldb, $dnewb, $dt );
    
    }
   
   }

   say scalar @newlids ." new lines encountered";
   
   my @newsids = ();
   my @newsnips = ();
   
   while ( scalar @newlids > 0 ) { # if new lines were inserted

    my $lid = shift( @newlids ); 
    my $line = shift( @newlines );
   
    my $snips = Catz::Data::line2snips ( $line );

    my $i = 1;    
    
    foreach my $snip ( @$snips ) {
     
     my $sid = Catz::Load::run( 'snip_sel', $snip );
 
     ( $sid == -1 ) and do {
     
      my ( $out_en, $out_fi ) = Catz::Data::plain( $snip );
        
      $sid = Catz::Load::run( 'snip_ins', $snip, $out_en, $out_fi );
               
      push @newsids, $sid;
      push @newsnips, $snip;
         
     };
    
     Catz::Load::run( 'line_snip_ins', $lid, $sid, $i );     
  
     $i++;
    
    }
   }    
 
   say scalar @newsids ." new snips encountered";
      
   my $newparts = 0;
   
   while ( scalar @newsids > 0 ) { # if new lines were inserted    

    my $sid = shift( @newsids ); 
    my $snip = shift( @newsnips );
    
    foreach my $area ( @Catz::Load::areas ) {
     
      my $sub = 'Catz::Data::get_'.$area.'s';
      my $data;
      
      do { no strict; $data = $sub->( $snip ); };
 
      foreach my $part ( grep { defined } @$data ) {
      
       my $pid = Catz::Load::run( 'part_sel', $area, $part );
 
       ( $pid == -1 ) and do {
     
         $pid = Catz::Load::run( 'part_ins', $area, $part );
         
         $newparts++;
         
       };
    
      Catz::Load::run( 'snip_part_ins', $sid, $pid );     

     }
    
    }
 
   }
   
   say "$newparts new parts encountered";
   
  
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
 
  say "MATCH $dold";
  
 }
 
}

Catz::Load::trn_orp();

Catz::Load::housekeep();

my $etime = time();

say 'done in ' . ( $etime - $btime ) . ' seconds';


__END__


  
 $stm_getdna->execute('FILE',$table);
 
 my $olddna = $stm_getdna->fetchrow_array();
 
 my $newdna = dna ( $data );   
 
 if ( $olddna ne $newdna ) {
    
  say "$olddna<>$newdna $file";
  
  if ( $file eq 'gallerymeta' ) {
  
   Catz::Load::trunc($dbc,'section');
             
   my $stm_section = 
   my $stm_album = $dbc->prepare(Catz::Load::make_sql('data.album',10));
   my $stm_line = $dbc->prepare('select data.put_line(?,?,?)');
   my $stm_exid = $dbc->prepare(Catz::Load::make_sql('exid',10));
   
   my $section = undef;
   

     

    
    my $newdnab = dna ( join "\n", @lines );
    
    $stm_getdna->execute('album',$album);
    
    my $olddnab = $stm_getdna->fetchrow_array();
    
    if ( $olddnab ne $newdnab ) {
    
     say "$olddnab<>$newdnab $album";
                        


     
 
   
     #say "setting dna $newdnab on album $album";
     $stm_setdna->execute('album',$album,$newdnab);
     
    }           

    $stm_section->finish;
    $stm_album->finish;
    $stm_line->finish;
    $stm_exid->finish;
    
    #say "setting dna $newdna on file $file";
    $stm_setdna->execute('FILE',$table,$newdna);
       
   }
   
  

   
   if ( ( scalar @newsids ) > 0 ) { # if new snips were inserted
   
    say "processing ".( scalar @newsids )." snips";
   
    my $stm_out = $dbc->prepare(Catz::Load::make_sql('data.out',3));
    my $stm_part = $dbc->prepare('select data.put_part(?,?,?,?)');
    
    while(scalar(@newsids)>0) {
    
     
     
    }
    
    $stm_out->finish;
    $stm_part->finish;
         
   }
 
  
  } else {
  
   Catz::Load::trunc($dbc,$table);
  
   my $stm = $dbc->prepare(Catz::Load::make_sql($table,$Catz::Load::colcount{$file}));
    
   if ($file eq 'resultmeta' ) {
    
    my @lines = Catz::Load::to_lines($data);
    
    map { $stm->execute($_) } @lines;
    
   } else { 
      
    foreach my $album (split /\#/, 
     $data) {
    
     my @lines = Catz::Load::to_lines($album);
     
     if($file eq 'textmeta') {
            
      if(defined $lines[2]) {
       $stm->execute(@lines);
      } else {
       $stm->execute($lines[0],$lines[1],$lines[1]);
      }
     
     } else { 
     
      $stm->execute(@lines); 
      
     }

    }
   
   } 

   $stm->finish;
   
   $stm_setdna->execute('FILE',$table,$newdna);
        
  }
  
 }

}

#say "finishing dna statements";
  
$stm_getdna->finish;
$stm_setdna->finish;

# orphan removals


print "\n";

Catz::Load::housekeep($dbc);

Catz::Load::disconn($dbc);
 
Catz::Load::end($btime);  
  
__END__

select count(*) from part where part like '%im%';

select count(*) from section natural join album_line natural join line_snip natural join snip_part;

select area_en,part,count(*) from album_line natural join line_snip natural join snip_part natural join part natural join area where part like '%ipekke%' group by area,part order by x,part;  

-- select out,count(*) as count from album_line natural join line_snip natural join out group by out;
-- 440 ms

-- create table _AREA_PART_COUNT as select area_en,area,part,x,count(*) as count from album_line natural join line_snip natural join snip_part natural join part natural join area group by x,area,area_en,area_fi,part order by x,part;
-- 12 s
-- select area_en,part,count from _AREA_PART_COUNT where part ilike '%sia%' order by x;
-- 43 ms

-- select area,part,count(*) as count,album,file_lr,width_lr,height_lr from photo natural join image natural join album_line natural join line_snip natural join snip_part natural join part natural join area group by album,file_lr,width_lr,height_lr,area,x,area_en,area_fi,part order by x,part; 
-- 20 s

-- select area,part,count,album,file_lr,width_lr,height_lr from _AREA_PART_THUMB where part like '%sia%' order by random() limit 50;


drop table if exists _OUT_COUNT;
create table _OUT_COUNT as select out,count(*) as count from album_line natural join line_snip natural join out group by album,n;
drop table  if exists _AREA_PART_COUNT;
create table _AREA_PART_COUNT as select area_en,area,part,x,count(*) as count from album_line natural join line_snip natural join snip_part natural join part natural join area group by x,area,area_en,area_fi,part order by x,part;
drop table  if exists _AREA_PART_THUMB;
create table _AREA_PART_THUMB as select area,part,count(*) as count,album,n,file_lr,width_lr,height_lr from photo natural join image natural join album_line natural join line_snip natural join snip_part natural join part natural join area group by album,n,file_lr,width_lr,height_lr,area,x,area_en,area_fi,part order by x,part;

drop table if exists _AREA_PART_PHOTO cascade;
create table _AREA_PART_PHOTO as select area,lower(area) as area_lc,part,lower(part) as part_lc,iid,s,album,n,bskey(s,n) as bs,file_hr,width_hr,height_hr,file_lr,width_lr,height_lr from
section natural join album_line natural join line_snip natural join snip_part natural join part natural join image natural join photo group by 
area,part,iid,s,album,n,bskey(s,n),file_hr,width_hr,height_hr,file_lr,width_lr,height_lr order by bskey(s,n) desc;
create index _AREA_PART_PHOTO_AREA_PART on _AREA_PART_PHOTO(AREA_LC,PART_LC);
drop table if exists _AREA_PART_PHOTO_ALL cascade;
create table _AREA_PART_PHOTO_ALL as select iid,album,n,bskey(s,n) as bs,file_hr,width_hr,height_hr,file_lr,width_lr,height_lr from
section natural join album_line natural join line_snip natural join snip_part natural join part natural join image natural join photo group by 
iid,album,n,bskey(s,n),file_hr,width_hr,height_hr,file_lr,width_lr,height_lr order by bskey(s,n) desc;

drop table if exists _XID_album_N cascade;
create table _XID_album_N ( xid serial primary key, album text, n smallint );
insert into _XID_album_N ( album, n ) ( select album, n from section natural join image order by s asc, n asc );
create index _XID_album_N_album_N on _XID_album_N(album,n);


area part xid album n


 

select s,iid,album,n,bs,file_hr,width_hr,height_hr,file_lr,width_lr,height_lr from _AREA_PART_PHOTO where AREA='EMS3' and PART='OSH';
select s,iid,album,n,bs,file_hr,width_hr,height_hr,file_lr,width_lr,height_lr from _AREA_PART_PHOTO where AREA='EMS3' and PART='TUA';




select iid,s,album,n from
section natural join album_line natural join line_snip natural join snip_part natural join part natural join image natural join photo order by s asc, n asc;
 
select sid,album_line.album,album_line.n from line_snip natural join album_line natural join image natural join photo order by album asc, n asc;

select area,part,pid,album_line.album,album_line.n from part natural join snip_part natural join line_snip natural join album_line natural join image natural join photo group by area,part,pid,album_line.album,album_line.n order by album asc, n asc;

select album,file,width,height,
select area_en,part,count from _AREA_PART_COUNT where part like '%sia%' order by x;

select area,part,count,album,file_lr,width_lr,height_lr from _AREA_PART_THUMB where part like '%sia%' order by random() limit 50;

select area,part,count,album,file_lr,width_lr,height_lr from _AREA_PART_THUMB where part like '%mimos%' order by random() limit 50;

selleorder by random() limit 50; 



pile natural join bucket where position(? in lower(snippet))>0 and (language = ? or language = 'AA' ) group by bucket.position,pile.bucket,snippet order by bucket.position,pile.bucket,snippet", 


select * from snip where snip like '% & %';
select * from line where line like '% & %';

SELECT out FROM out
WHERE vector @@ to_tsquery('mikke | mimosa')



 