#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2011 Heikki Siltala
# Licensed under The MIT License
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

package Catz::Model::Photo;

use parent 'Exporter';
our @EXPORT = qw ( photo_thumb photo_detail photo_image photo_resultkey photo_text );

use Catz::Data::DB;
use Catz::Util::Time qw ( dtexpand );

sub photo_thumb {

 my ( $db, $lang, @xs ) = @_;
 
 my $min = 99999999;
 my $max = 00000000; 
 
 my $thumbs = $db->all( qq{select s,n,folder,file||'_LR.JPG',lwidth,lheight from album natural join photo where x in (} . ( join ',', @xs ) .  ') order by x' );

 foreach my $row ( @$thumbs ) {
  # extract date from the folder name (first eight characters)
  my $d = int (  substr ( $row->[2], 0, 8 ) ); 
  $d < $min and $min = $d;
  $d > $max and $max = $d;
 } 

 return [ 
  $thumbs, 
  $min ne 99999999 ? $min : undef, 
  $max ne 00000000 ? $max : undef
 ];

}

sub photo_detail {

 my ( $db, $lang, $x ) = @_;

 return $db->all ( qq{select pri,sec from (
  select pri,disp,sec,sort from pri natural join sec_$lang natural join inalbum natural join photo where x=? union all
  select pri,disp,sec,sort from pri natural join sec_$lang natural join inexiff natural join photo where x=? union all
  select pri,disp,sec,sort from pri natural join sec_$lang natural join inpos natural join photo where pri<>'text' and x=?
 ) order by disp,sort}, $x, $x, $x );

}

sub photo_resultkey {

 my ( $db, $lang, $x ) = @_;

 my $loc = $db->one ( "select sec from pri natural join sec_$lang natural join inalbum natural join photo where x=? and pri='loc'", $x );
 my $date = $db->one ( "select sec from pri natural join sec_$lang natural join inalbum natural join photo where x=? and pri='date'", $x );

 my $poss = $db->one ( 'select max(p) from photo natural join inpos where x=?', $x );

 my @cats = ();

 foreach my $p ( 1 .. $poss ) {

  my $cat = $db->one ( "select sec from pri natural join sec_$lang natural join inpos natural join photo where x=? and p=? and pri='cat'", $x, $p );
  
  push @cats, $cat; # push even undefs

 }

 return [ $date, $loc, @cats ];

}

sub photo_text {

 my ( $db, $lang, $x ) = @_;

 my $res = $db->col ( qq{select sec from pri natural join sec_$lang natural join inpos natural join photo where pri='text' and x=? order by p}, $x );
 
 return $res;

}

sub photo_image {

 my ( $db, $lang, $x ) = @_;
 
 return $db->row ( qq{select s,n,folder,file||'.JPG',hwidth,hheight from album natural join photo where x=?},$x);

}

1;