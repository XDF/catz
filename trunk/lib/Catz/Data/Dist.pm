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

use 5.12.0; use strict; use warnings;

use parent 'Exporter';

our @EXPORT = qw ( dist_conf dist_url );

my $cnf = {

 blocks => {
 
  full => [ qw ( +has breed +has cat ) ],
  partial => [ qw ( +has breed -has cat ) ],
  breed => [ qw ( +has breed -breed xc? -has cat ) ],  
  cate => [ qw ( +has breed +breed xc? -has cat ) ],
  none => [ qw ( -has text ) ],
  tailer => [ qw ( -has cat ) ], 
 },
 
 keysall => [ qw ( full partial breed cate none ) ],
 keyscontrib => [ qw ( none cate breed full ) ],
 keyspie => [ qw ( full breed cate none ) ],
 keyslink => [ qw ( partial ) ], 

};

sub dist_conf { $cnf }

sub dist_url {




}