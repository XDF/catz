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

use 5.10.0; use strict; use warnings;

use parent 'Catz::Model::Common';

my $HR = '.JPG';
my $LR = '_LR.JPG';


sub _thumb {

 my ( $self, @xs ) = @_;
 
 my $min = 99999999;
 my $max = 00000000; 
 
 my $thumbs = $self->dball( qq{select x,s,n,folder,file||'$LR',lwidth,lheight from album natural join photo where x in (} . ( join ',', @xs ) .  ') order by x' );

 foreach my $row ( @$thumbs ) { 
  # extract date from the folder name (first eight characters) 
  my $d = int (  substr ( $row->[3], 0, 8 ) ); 
  $d < $min and $min = $d;
  $d > $max and $max = $d;
 } 

 # send min and max date with the thumbs set
 [ $thumbs, $min ne 99999999 ? $min : undef, $max ne 00000000 ? $max : undef ];

}

sub _detail {

 my ( $self, $x ) = @_; my $lang = $self->{lang};

 return $self->dball( 
  qq{select pri,sec from (
   select pri,disp,sec,sort from pri natural join sec_$lang natural join inalbum natural join photo where pri<>'album' and x=? union all
   select pri,disp,sec,sort from pri natural join sec_$lang natural join inexiff natural join photo where x=? union all
   select pri,disp,sec,sort from pri natural join sec_$lang natural join inpos natural join photo where pri<>'text' and x=? union all
   select 'time','99',moment,moment from photo where x=? and moment is not null
  ) group by pri,sec order by disp,sort}, $x, $x, $x, $x 
 );

}

sub _resultkey {

 my ( $self, $x ) = @_; my $lang = $self->{lang};

 my $loc = $self->dbone ( "select sec from pri natural join sec_$lang natural join inalbum natural join photo where x=? and pri='location'", $x ); # 0 ms / 2011-05-29
 
 my $date = $self->dbone ( "select sec from pri natural join sec_$lang natural join inalbum natural join photo where x=? and pri='date'", $x ); # 0 ms / 2011-05-29

 my @cats = ();

 # this returns undef if the photo doesn't have comment
 my $top = $self->dbone ( 'select max(p) from photo natural join inpos where x=?', $x ); # 0 ms / 2011-05-29

 $top and do { 
 
  do {

   push @cats, $self->dbone ( "select sec from pri natural join sec_$lang natural join inpos natural join photo where x=? and p=? and pri='catname'", $x, $_ ); # 0 ms / 2011-05-29

  } foreach ( 1 .. $top );
  
 };

 [ $date, $loc, @cats ];

}

sub _text {

 my ( $self, $x ) = @_; my $lang = $self->{lang};

 return $self->dbcol( 
  qq{select sec from pri natural join sec_$lang natural join inpos natural join photo where pri='text' and x=? order by p}, $x 
 );

}

sub _texts {

 my ( $self, @xs ) = @_; my $lang = $self->{lang};

 my $res = $self->dball( 
  qq{select x,sec from pri natural join sec_$lang natural join inpos natural join photo where pri='text' and x in (} . ( join ',', @xs ) .  ') order by x,p' # 0 ms / 2011-05-29   
 );
 
 my $texts = {};
  
 do {
 
  if ( exists $texts->{ $_->[0] } ) {
  
   $texts->{ $_->[0] } .=  ' & ' . $_->[1];
  
  } else {
  
   $texts->{ $_->[0] } =  $_->[1];
  
  }

 } foreach ( @$res );
  
 return $texts 
 
}


sub _image {

 my ( $self, $x ) = @_;
 
 $self->dbrow(qq{select s,n,folder,file||'$HR',hwidth,hheight from album natural join photo where x=?},$x);

}

1;