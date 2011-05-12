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

package Catz::Model::Find;

use parent 'Exporter';
our @EXPORT = qw ( album maxx news_all news_one find sample search id2x x2id pri x2dt );

use 5.12.2;
use strict;
use warnings;

# a generic module to provide access various meta data stuff
# stored in the database

use Catz::Data::DB;
use Catz::Util::Number qw ( fullnum33 minnum33 );
use Catz::Util::Time qw ( dtexpand );

sub x2dt {

 my ( $db, $lang, $x ) = @_;
   
 my $res = $db->row ('select folder,moment from album natural join photo where x=?',$x);
 
 my $date = substr ( $res->[0], 0, 8 );
 
 $date .= $res->[1] // '';
    
 return dtexpand ( $date, $lang );
 
}

1;

 