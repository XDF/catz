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

package Catz::Model::Meta;

use parent 'Exporter';
our @EXPORT = qw ( meta_text meta_maxx meta_news );

# a generic module to provide access various meta data stuff
# stored in the database

use Catz::Data::DB;
use Catz::Util::Time qw ( dtexpand );

my %text = ();

my $maxx;

sub meta_text { 

 my $lang = shift;

 exists $text{$lang} or do {
  $text{$lang} = {};
  do { 
   $text{$lang}->{$_->[0]} = $_->[1] 
  } foreach @{ db_all( "select tag,text_$lang from mtext" ) };
 };
 
 return $text{$lang};  
 
}

sub meta_maxx {
 
 defined $maxx or $maxx = db_one ( 'select max(x) from _x' ) + 1;
 
 # notice: adding 1 to make room for indexing from 1 to n
 # to be on a safe size, not only from 0 to n-1
 
 return $maxx; 
 
}

sub meta_news {

 my $lang = shift;
  
 my $res = db_all ( "select dt,null,title_$lang,text_$lang from mnews order by dt desc" );
   
 foreach my $row ( @$res ) {
 
  $row->[1] = dtexpand ( $row->[0], $lang );
   
 }
 
 return $res;
 
}

1;

 