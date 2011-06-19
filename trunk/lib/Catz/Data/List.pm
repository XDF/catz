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

package Catz::Data::List;

use 5.10.0; use strict; use warnings;

use parent 'Exporter';

our @EXPORT = qw ( list_matrix list_node );

my $matrix = {

 album => {
  modes => [ qw ( date a2z top ) ],
  dividers => 1
  # no refines  
 },
 
 date => {
  modes => [ qw ( date top ) ],
  dividers => 1,
  refines => [ qw ( location organizer umbrella lens body breedcode ) ] 
 },
 
 location => {
   modes => [ qw ( a2z top first ) ],
   dividers => 0,
   refines => [ qw ( organizer umbrella ) ]
 },
 
 organizer => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0,
  refines => [ qw ( umbrella location ) ] 
 },
 
 umbrella => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0
  # no refines
 },
 
 folder => {
  # no modes
  # no dividers
  refines => [ qw ( location organizer umbrella lens body breedcode ) ] 
 },

 catname => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1,
  refines => [ qw ( nickname breedcode emscode breeder nationcode location ) ] 
 },
 
 breed => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0
  # no refines
 },
 
 breeder => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1,
  refines => [ qw ( breedcode featurecode nationcode catname location ) ],
  jump => { catname => 1 },
  limit => { catname => 9999 } 
 },
 
 nation => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0
 },

 nationcode => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0
 },
 
 emscode => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1
 },

 facadecode => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1,
  refines => [ qw ( breedcode featurecode ) ],
  jump => { featurecode => 1 }
 },
 
 breedcode => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0,
  refines => [ qw ( facadecode featurecode ) ]
 },
 
 feature => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0,
 },
 
 featurecode => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0,
  refines => [ qw ( breedcode facadecode ) ], 
  jump => { facadecode => 1 }
 },

 nickname => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1,
  refines => [ qw ( catname ) ]
 },

 title => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1
 },

 titlecode => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1,
  refines => [ qw ( breeder breedcode nationcode ) ],
 },

 lens => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0,
  refines => [ qw ( body fnumber ) ]
 },

 body => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0,
  refines => [ qw ( lens sensitivity ) ]
 },

 fnumber => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0
 },

 exposuretime => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0
 },

 sensitivity => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0,
  refines => [ qw ( body ) ]
 },

 focallength => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0,
  refines => [ qw ( lens ) ]
 },
 
};

sub list_matrix { $matrix }

sub list_node { exists $matrix->{$_[0]} ? $matrix->{$_[0]} : undef } 