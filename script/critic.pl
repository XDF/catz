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
use Perl::Critic;

use Catz::Util::File qw ( findfilesrec );

const my $RC    => './criticrc.txt';
const my @DIRS  => qw ( ../lib ../script ../t ); 
const my $CONF  => {
 -profile => $rc, 
 -severity => 1, 
};

my $cr = Perl::Critic->new();

my @msgs = ();

my @files = findfilesrec @DIRS;

foreach my $file ( reverse grep { $_ =~ /\.(p[ml]|t)$/ } @files ) {

 say $file;
 
 my @out = $cr->critique ( $CONF, $file );

 push @msgs, @out;

}

print @msgs;