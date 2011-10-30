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

use Catz::Util::File qw ( fileread filewrite fileremove findlatest pathcut );

my $path = '../db';

# removes the latest database if nay after the one of the key file
# so reverts effects of latest database loading after the last roll

# latest key file in database dir
my $keyf = findlatest ( $path, 'txt' );

# get dt from the key file
my $dtold = defined $keyf ? substr ( pathcut ( $keyf ), 0, 14 ) : undef;

if ( $dtold ) {

 my $dbnew = findlatest ( $path, 'db' );
 my $dtnew = defined $dbnew ? substr ( pathcut ( $dbnew ), 0, 14 ) : undef;
 
 if ( $dtnew ) {
 
  if ( $dtold eq $dtnew ) {
 
   say "no new database found after '$dtold'";
 
  } else {
 
   unlink ( $dbnew );
   say "reverted by removing unrolled database '$dtnew' '$dbnew'";
  
  }
  
 } else {
 
  say "unable to locate the latest database file";
 
 }
 
 
} else {

 say "key file not found, unable to revert";
 
}