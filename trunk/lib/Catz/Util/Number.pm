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

package Catz::Util::Number;

use 5.12.0;
use strict;
use warnings;

use POSIX;    # for floor and ceil
use Number::Format;

use base 'Exporter';

our @EXPORT_OK = qw(
 floor ceil float fmt fullnum3 fullnum4 fullnum33 minnum minnum33 round logn
);

# floor and ceil are pass-thrus to POSIX so there no subs here

# Static creation of Number::Format objects, used later in formatting sub

my $fmt_en = new Number::Format (
 -thousands_sep => ',',
 -decimal_point => '.'
);

my $fmt_fi = new Number::Format (
 -thousands_sep => ' ',
 -decimal_point => ','
);

#
# converts x/y string representation to a float
#
sub float {

 my ( $a, $b ) = split /\//, $_[ 0 ];

 ( int ( $a ) / int ( $b ) )

}

#
# formats nubmer according to the langauge code
#
# in: number, language code
# out: formatted number (string)
#

sub fmt {

 $_[ 1 ] eq 'fi' and return $fmt_fi->format_number ( $_[ 0 ] );

 return $fmt_en->format_number ( $_[ 0 ] );

}

#
# converts an integer to null padded 3 digit integer
#
sub fullnum3 { sprintf ( "%03d", $_[ 0 ] ) }

#
# converts two integers to null padded 3 digit integers
# places them after eachother
#
sub fullnum33 { sprintf ( "%03d%03d", $_[ 0 ], $_[ 1 ] ) }

#
# converts an integer to null padded 4 digit integer
#
sub fullnum4 { sprintf ( "%04d", $_[ 0 ] ) }

#
# converts a null padded integer into a real integer
#
sub minnum { int ( $_[ 0 ] ) }

#
# converts two integers each padded to 3 digits to real integers
#
sub minnum33 {

 ( int ( substr ( $_[ 0 ], 0, 3 ) ), int ( substr ( $_[ 0 ], 3, 3 ) ) )

}

#
# rounds a float
#
# in: float, number of decimals (defaults to zero)
# out: the rounded float
#
sub round { sprintf '%.' . ( defined $_[ 1 ] ? $_[ 1 ] : 0 ) . 'f', $_[ 0 ] }

sub logn { log ( $_[ 0 ] ) / log ( $_[ 1 ] ) }

1;
