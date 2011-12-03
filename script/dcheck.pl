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

use 5.12.0; use strict; use warnings;

use lib '../lib';

use Catz::Data::Conf;

use Catz::Load::Check qw ( check_begin check_any check_end );

use Catz::Util::Log qw ( logadd logclose logopen logit logdone );
use Catz::Util::Time qw ( dt dtlang dtexpand s2dhms dt2epoch );

use Catz::Util::File qw ( filecopy findlatest );

$| = 1; # unbuffered printing

logopen ( "../log/dcheck.log" );

logit "----- catza.net dcheck started at " . dtlang ( 'en' );

my $db = findlatest ( '../db', 'db' );

#my $olddb = findlatest ( '../db', 'db' );

#defined $olddb or die "old database lookup failed";

#my $db = "../db/$dt.db";

#logit ( "copying database '$olddb' to '$db'" );

#filecopy ( $olddb, $db ); 

my $dt = check_begin ( $db );

logit "checking data version '$dt'";

check_any ( 'breed_exists' );

check_any ( 'feature_exists' );

check_any ( 'title_exists' );

check_any ( 'subject_case' );

check_any ( 'subject_approx' );

check_any ( 'nation_exists' );

check_any ( 'breeder_nation' );

check_end;

logit "----- catza.net dcheck finished at " . dtlang ( 'en' ) ;

logclose;