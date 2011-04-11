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
our @EXPORT = qw ( photo_thumbs photo_details photo_image photo_texts );

use Catz::Data::DB;
use Catz::Util::Time qw ( dtexpand );

sub photo_thumbs {

 my ( $db, $lang, @xs ) = @_;
 
 my $min = 99999999;
 my $max = 00000000; 
 
 my $thumbs = $db->all( qq{select album,file||'_LR.JPG',width_lr,height_lr 
  from _photo where x in (} . ( join ',', @xs ) .  ') order by x' );

 foreach my $row ( @$thumbs ) {
  # extract date from the album name (first eight characters)
  my $d = int (  substr ( $row->[0], 0, 8 ) );
  $d < $min and $min = $d;
  $d < $max and $max = $d;
 } 

 return ( $thumbs, dtexpand ( $min, $lang ), dtexpand ( $max, $lang ) );

}

sub photo_details {

 my ( $db, $lang, $x ) = @_;

 return $db->all ( qq{select pri,sec_$lang from pri natural join sec natural join snip natural join _x where x=? order by sort_pri,sort_$lang}, $x );

}

sub photo_texts {

 my ( $db, $lang, $x ) = @_;

 return $db->col ( qq{select sec_$lang from pri natural join sec natural join snip natural join _x where x=? and pri='out' order by p}, $x );


}

sub photo_image {

 my ( $db, $lang, $x ) = @_;
 
 return $db->row ( qq{select album,file||'.JPG',width_hr,height_hr from photo natural join _x where x=?},$x);

}

1;