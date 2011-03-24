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

package Catz::Model::Locate;

use strict;
use warnings;

use parent 'Exporter';
our @EXPORT = qw( locate_suggest locate_search );

use Catz::Data::DB;

sub locate_suggest {

 my ( $lang, $pattern ) = @_;

 $pattern = '%' . $pattern . '%';

 my $res = db_all (qq{select pri,sec_$lang,count from ( select pri,sec_$lang,count(distinct x) as count from pri natural join sec natural join snip natural join _x where pri not in ('dt', 'out') and sec_en like ? group by pri,sec_$lang order by random() limit 50 ) order by sec_$lang},$pattern);

 return $res;

}

sub locate_search {

 die 'locate_search not yet implemented';

}

1;
