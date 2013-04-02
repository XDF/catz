#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2013 Heikki Siltala
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

package Catz::Data::Text;

use 5.16.2;
use strict;
use warnings;

use Const::Fast;

use Catz::Util::File   qw ( fileread        );
use Catz::Util::String qw ( tolines topiles );

use base 'Exporter';

our @EXPORT = qw( text );

# hashrefs to tags
my $ten = {};
my $tfi = {};

my $text = fileread ( '../lib/text.txt' );

# populate $en, $fi on module load

foreach my $pile ( topiles ( $text ) ) {

 my @lines = tolines ( $pile );

 ( $lines[ 0 ] and $lines[ 1 ] and $lines[ 2 ] )
  or die "text definition error: '$lines[0]' '$lines[1]' '$lines[2]'";

 $ten->{ $lines[ 0 ] } = $lines[ 1 ];
 $tfi->{ $lines[ 0 ] } = $lines[ 2 ];

}

const my $EN => $ten;
const my $FI => $tfi;

$ten = undef;
$tfi = undef;

sub text { $_[ 0 ] eq 'fi' ? $FI : $EN; }

1;