#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2012 Heikki Siltala
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

package Catz::Model::All;

#
# Get all photos
#

use 5.14.2;
use strict;
use warnings;

use parent 'Catz::Model::Vector';

use Bit::Vector;

# in case of all photos the bit vector is a fully filled = all bits on

sub _bits {

 # the first bit is unused so we reserve one bit more
 my $vec = Bit::Vector->new ( $_[ 0 ]->maxx + 1 );

 $vec->Fill;
 
 # the first bit is unused as x counting start from 1
 # so we set it off to make operations not to take it into account
 $vec->Bit_Off ( 0 );
 
 return $vec;

}

1;
