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

use Const::Fast;
use Perl::Tidy;

use Catz::Util::File qw ( filecopy findfilesrec fileremove );

#
# WARNING: overwrites silently existing source code files
# with tidy output versions so assuming strongly that all code
# files are under version control system. In case of an error
# it can happen that ALL SOURCE CODE FILES GET SPOILED
#

const my $RC    => './tidyrc.txt';
const my $LOG   => '../log/tidylog.log';
const my $ERROR => '../log/tidyerr.log';
const my $TEMP  => '../temp/tidytemp.txt';
const my @DIRS  => qw ( ../lib ../script ../t );

my @files = findfilesrec @DIRS;

foreach my $file ( grep { $_ =~ /\.(p[ml]|t)$/ } @files ) {

 say $file;

 # create tidy output to temp file

 Perl::Tidy::perltidy (
  source      => $file,
  destination => $TEMP,
  perltidyrc  => $RC,
  logfile     => $LOG,
  errorfile   => $ERROR
 );

 # copy temp file over the source file

 filecopy $TEMP, $file;

 # remove the temp file

 fileremove $TEMP;

} ## end foreach my $file ( grep { $_...})
