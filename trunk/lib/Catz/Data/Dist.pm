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

package Catz::Data::Dist;

use 5.12.0;
use strict;
use warnings;

use parent 'Exporter';

our @EXPORT = qw ( dist_conf dist_prep );

use Const::Fast;

use Catz::Data::Search;

use Catz::Util::Number qw ( round );
use Catz::Util::String qw ( enurl fuse fuseq );

const my $CONF => {

 # definitions for cat data qualifications and 
 # cat data distribution visualizations  

 slices => {

  # slices different levels of data represented
  # as advanded search search term sets

  # photos that are regarded to have complete data
  # and no more data is required from the community 
  full => [ qw ( +has breed +has cat ) ],

  # photos that have breed or category but no cat name
  partial => [ qw ( +has breed -has cat ) ],
    
  # photos that have cat breed but no cat name
  breed => [ qw ( +has breed -breed XC? -has cat ) ],
  
  # photos that have category but no cat name
  cate => [ qw ( +has breed +breed XC? -has cat ) ],

  # photos that have plain text
  plain => [ qw ( +has text -has breed -has cat ) ],
  
  # photos that are regarded to have no data
  none => [ qw ( -has text ) ],
    
 },

 sets => {
 
  # sets are pre-defined ordered sets of slices used in 
  # displaying the data qualifications and visualizations
  
  # all keys
  all => [ qw ( complete full partial breed cate plain none ) ],
 
  # the keys required to do all calculations
  required => [ qw ( full breed cate plain none ) ],
    
  # the presentation of the pie graphs
  pie => [ qw ( complete breed cate none ) ],
  
  # the presentation of the links on the photo browsing page
  link => [ qw ( none partial ) ],
  
 },

};

sub dist_conf { $CONF }

sub dist_prep {

 # prepares distribution data to stash

 my $s = shift; # Mojolicious stash
 
 # calculate more counts
 
 $s->{dist_count_partial} =
  $s->{dist_count_breed} + $s->{dist_count_cate}; 

 $s->{dist_count_complete} =
  $s->{dist_count_full} + $s->{dist_count_plain};
  
 foreach my $key ( @{ $CONF->{sets}->{all} } ) {
    
   # calculcate percentage
 
   $s->{ 'dist_perc_' . $key } = 
    round ( 
     ( ( $s->{ 'dist_count_' . $key } / $s->{ dist_count_all } ) * 100 ), 
     1 
   );
 
  # prepare drill url
  
  $key ne 'complete' and do { 
  
   exists $s->{ 'drillargs_' . $key } or 
    $s->{ 'drillargs_' . $key } = 
     [ @{ $s->{ args_array } }, @{ $CONF->{ slices }->{ $key } } ];  

   $s->{ 'dist_url_' . $key } = 
    fuseq ( $s->{ langa }, ( 
     'search?q=' . enurl ( args2search ( @{ $s->{ 'drillargs_' . $key } } ) ) 
    ) );
    
  };

  # prepare text

  $s->{ 'dist_text_' . $key } =
   $s->{ t }->{ 'HAS' . uc ( $key ) . ( 
    $s->{ 'dist_count_' . $key } == 1 ? '' : 'A' 
   ) };
 
 }
 
 
 # prepare distribution pie url
 
 $s->{url_viz_dist} = fuse ( 
  $s->{ langa }, 'viz', 'dist', $s->{ dist_count_complete }, 
  $s->{ dist_count_breed }, $s->{ dist_count_cate }, 
  $s->{ dist_count_none }, $s->{ version }
 );  
  
}

1;