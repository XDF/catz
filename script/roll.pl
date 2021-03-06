#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2014 Heikki Siltala
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

use 5.16.2;
use strict;
use warnings;

use lib '../lib';

use Const::Fast;

use Catz::Data::Conf;
use Catz::Util::File qw ( fileread filewrite fileremove findlatest pathcut );

const my $PATH => '../db';

my $rolled = 0;

# rolls to the latest database by updating the key file

# latest key file
my $keyold = findlatest ( $PATH, 'txt' );

# current dt
my $dtold = defined $keyold ? substr ( pathcut ( $keyold ), 0, 14 ) : undef;

# latest database file
my $dbnew = findlatest ( $PATH, 'db' );

# new dt
my $dtnew = defined $dbnew ? substr ( pathcut ( $dbnew ), 0, 14 ) : undef;

if ( not defined $dtold ) {

 # no old db, just make a key file
 filewrite ( "$PATH/$dtnew.txt", "Catz database key file" );

 say "rolled initially to '$dtnew'";
 $rolled++;

}
else {

 if ( $dtold eq $dtnew ) {

  say "already at the latest dt '$dtold', no need to roll";

 }
 else {

  filewrite ( "$PATH/$dtnew.txt", "Catz database key file" );

  # remove the old key file
  fileremove ( $keyold );

  say "rolled from '$dtold' to '$dtnew'";
  $rolled++;

 }

}

if ( $rolled and conf ( 'prod' ) ) {

 chmod ( 0444, $dbnew ) || die $!;

 say "set read only '$dbnew'";
 
 chmod ( 0444, "$PATH/$dtnew.txt" ) || die $!;
 
 say "set read only '$PATH/$dtnew.txt'";

}
