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

package Catz::Util::Log;

use strict;
use warnings;
use 5.10.0;

use parent 'Exporter';

our @EXPORT_OK = qw ( logclose logit logadd logdone logopen );

my $log = undef;

sub logit {

 say $log $_[ 0 ];
 say $_[ 0 ];    # also print it out

}

sub logadd {

 print $log $_[ 0 ];
 print $_[ 0 ];    # also print it out

}

sub logdone {

 print $log "\n";
 print "\n";       # also print it out

}

sub logclose {

 close $log;

}

sub logopen {

 my $logfile = shift;

 open my $log, '>', $logfile
  or die "unable to open logfile '$logfile' for writing";

}
