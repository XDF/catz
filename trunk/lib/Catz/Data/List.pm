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
 },
 
 # folder is not set
 
 date => {
  modes => [ qw ( date top ) ],
  dividers => 1
 },
 
 location => {
   modes => [ qw ( a2z top first ) ],
   dividers => 0
 },
 
 organizer => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0
 },
 
 umbrella => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0
 },
 
 # text is not set
 
 catname => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1
 },
 
 breed => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0
 },
 
 breeder => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1 
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
  dividers => 1
 },
 
 breedcode => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0
 },
 
 feature => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1 
 },
 
 featurecode => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1
 },

 nickname => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1
 },

 title => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1
 },

 titlecode => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1
 },

 lens => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0
 },

 body => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0
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
  dividers => 0
 },

 focallength => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0
 },
 
};

sub list_matrix { $matrix }

sub list_node { exists $matrix->{$_[0]} ? $matrix->{$_[0]} : undef } 