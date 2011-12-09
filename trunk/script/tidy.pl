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

use 5.12.0;
use strict;
use warnings;

use lib '../lib';

use Perl::Tidy;

use Catz::Util::File qw ( filecopy findfilesrec fileremove );

my $rc    = './tidyrc.txt';
my $log   = '../log/tidylog.log';
my $error = '../log/tidyerr.log';
my $temp  = '../temp/tidytemp.txt';

my @files = findfilesrec ( '../lib', '../script', '../t' );

foreach my $file ( grep { $_ =~ /\.(p[ml]|t)$/ } @files ) {

 say $file;

 # create tidy output to temp file

 Perl::Tidy::perltidy (
  source      => $file,
  destination => $temp,
  perltidyrc  => $rc,
  logfile     => $log,
  errorfile   => $error
 );

 # copy temp file over the source file

 filecopy $temp, $file;

 # remove the temp file

 fileremove $temp;

} ## end foreach my $file ( grep { $_...})
