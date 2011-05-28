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
  dividers => 1,
  related => [ qw ( cat breed breeder body lens ) ]  
 },
 
 # folder is not set
 
 date => {
  modes => [ qw ( date top ) ],
  dividers => 1,
  related => [ qw ( cat breed breeder body lens ) ]
 },
 
 loc => {
   modes => [ qw ( a2z top first ) ],
   dividers => 0,
   related => [ qw ( date album org ) ]
 },
 
 org => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0,
  related => [ qw ( date album loc ) ]
 },
 
 umb => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0,
  related => [ qw ( org ) ]
 },
 
 # text is not set
 
 cat => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1,
  related => [ qw ( title feat bcode app code ) ]
 },
 
 breed => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0,
  related => [ qw ( bcode app ) ]
 },
 
 breeder => {
  modes => [ qw ( a2z top first nat ) ],
  dividers => 1,
  related => [ qw ( breed bcode cat org umb ) ] 
 },
 
 code => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1,
  related => [ qw ( cat breeder ) ] 
 },

 app => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1,
  related => [ qw ( cat breeder ) ]
 },
 
 bcode => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0,
  related => [ qw ( breeder feat ) ]
 },
 
 feat => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1,
  related => [ qw ( feat app ) ] 
 },
 
 nick => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1,
  related => [ qw ( cat breed bcode ) ]
 },

 title => {
  modes => [ qw ( a2z top first ) ],
  dividers => 1,
  related => [ qw ( title ) ]
 },

 lens => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0,
  related => [ qw ( body ) ]
 },

 body => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0,
  related => [ qw ( lens ) ]
 },

 fnum => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0,
  related => [ qw ( lens iso etime ) ]
 },

 etime => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0,
  related => [ qw ( lens iso fnum ) ]
 },

 iso => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0,
  related => [ qw ( body iso etime ) ]
 },

 flen => {
  modes => [ qw ( a2z top first ) ],
  dividers => 0,
  related => [ qw ( lens ) ]
 },

 

  
};

sub list_matrix { $matrix }

sub list_node { exists $matrix->{$_[0]} ? $matrix->{$_[0]} : undef } 