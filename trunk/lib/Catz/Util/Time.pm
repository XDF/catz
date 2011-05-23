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

package Catz::Util::Time;

use strict;
use warnings;

use DateTime;
use Memoize;
use Time::localtime; 
use POSIX qw( floor );

use parent 'Exporter';

our @EXPORT_OK = qw( dtdate dtexpand dt dtlang dtsplit thisyear );

#
# expands timestamp from YYYYMMDD or YYYYMMDDHHMMSS into 
# a language specific human-readable form
#
# in: timestamp, language
# out: timestamp converted to a human-readable form
#

# used a lot with limited set of values -> memoizing
memoize ( 'dtexpand' ); 

sub dtexpand {
 
 # HHMMSS are optional 
 ( $_[0] =~ /^(\d{4})(\d\d)(\d\d)((\d\d)(\d\d)(\d\d))?$/ )
  or die "invalid timestamp input '$_[0]'";

 my $lang = defined $_[1] ? $_[1] : 'en'; # defaults to english
 
 my $str = ( $lang eq 'fi' ? int($3) . '.' . int($2) . '.' . $1 : "$1-$2-$3" );

 defined ( $4 ) and $str = "$str $5:$6:$7";

 return $str;
 
}

#
# returns the systep time in a timestamp format YYYYMMDDHHMMSS
#
sub dt {
 
 my ( $s, $mi, $h, $d, $mo, $y ) = @{ localtime( time ) };
 
 $y += 1900; $mo += 1;
 
 return sprintf( "%04d%02d%02d%02d%02d%02d", $y, $mo, $d, $h, $mi, $s );
  
}

sub dtdate { substr $_[0], 0, 8 }

#
# returns the systep time in a human-readable form
#
sub dtlang { dtexpand ( dt , $_[0] ) };

#
# returns the current year
#
sub thisyear {

 my ( undef, undef, undef, undef, undef, $y ) = @{ localtime( time ) };
 
 return $y + 1900;
 
}
sub dtsplit { substr ( $_[0], 0, 8 ), substr ( $_[0], 8 ) }
1;