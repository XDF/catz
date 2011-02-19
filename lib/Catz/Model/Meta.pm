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

package Catz::Model::Meta;

use parent 'Exporter';
our @EXPORT = qw ( meta_text meta_maxx meta_news_latest meta_news_all );

# a generic module to provide access various meta data stuff
# stored in the database

use Catz::DB;
use Catz::Util qw ( expand_ts );

my %text = ();

my $maxx;

sub meta_text { 

 my $lang = shift;

 exists $text{$lang} or do {
  $text{$lang} = {};
  do { 
   $text{$lang}->{$_->[0]} = $_->[1] 
  } foreach @{ db_all( "select tag,text_$lang from metatext" ) };
 };
 
 return $text{$lang};  
 
}

sub meta_maxx {
 
 defined $maxx or $maxx = db_one ( 'select max(x) from _fid_x' );
 
 return $maxx; 
 
}

sub meta_news_all {

 my $lang = shift;
  
 my $res = db_all ( "select dt,null,title_$lang,text_$lang from metanews order by dt desc" );
   
 foreach my $row ( @$res ) {
 
  $row->[1] = expand_ts ( $row->[0], $lang );
   
 }
 
 return $res;
 
}

sub meta_news_latest {

 my $lang = shift;
   
 my $res = db_all ( "select dt,null,title_$lang from metanews order by dt desc limit 6" );
   
 foreach my $row ( @$res ) {
  
  $row->[1] = expand_ts ( substr ( $row->[0], 0, 8 ), $lang );
 
 }
 
 return $res;
 
}


1;

 