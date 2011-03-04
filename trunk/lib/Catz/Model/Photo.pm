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

package Catz::Model::Photo;

use parent 'Exporter';
our @EXPORT = qw ( photo_thumbs photo_details photo_image photo_texts );

use Catz::DB;
use Catz::Util qw ( expand_ts );

sub photo_thumbs {

 my ( $lang, $xs ) = @_; 
 
 my $thumbs = db_all( "select album,n,file||'_LR.JPG',width_lr,height_lr,null from file natural join x where x in (" 
  . ( join ',', @$xs ) .  ') order by x' );

 foreach my $row ( @$thumbs ) {
  # using date as a default metadata for thumbs
  # extract if from the album name (first eight characters)
  # and convert it to a language specific format
  $row->[5] = expand_ts ( substr ( $row->[1], 0, 8 ), $lang );
 }

 return $thumbs;

}

sub photo_details {

 my ( $lang, $x ) = @_;

 return db_all ( qq{select pri,sec_$lang from snip natural join x where x=? order by pri_sort,sec_$lang}, $x );

}

sub photo_texts {

 my ( $lang, $x ) = @_;

 return db_col ( qq{select sec_$lang from snip natural join x where x=? and pri='out' order by p}, $x );


}

sub photo_image {

 my $x = shift;
 
 return db_row ( "select album,file||'.JPG',width_hr,height_hr from file natural join x where x=?",$x);

}





 
1;