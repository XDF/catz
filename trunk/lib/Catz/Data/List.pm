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

#
# This is the control module for lists and for presentation of subjects.
# This affects to the system both on load time and runtime.
#
# Each subject has an entry here.
#
# modes - controls the modes available on lists
# dividers - set dividers on and off on lists
# refines - defines the pris and their order presented on browse for drill/jump
# jump - sets the drill to be a jump to subject rather than drill (search)

use 5.10.0;
use strict;
use warnings;

use parent 'Exporter';

our @EXPORT = qw ( list_matrix list_node );

use Const::Fast;

const my $MATRIX => {

 album => {
  modes    => [ qw ( cron a2z top ) ],
  dividers => 1,
  refines  => { },
  jump     => { },
 },

 date => {
  modes    => [ qw ( cron top ) ],
  dividers => 1,
  refines  => [ qw ( loc org umb breed breeder lens body ) ],
  jump     => { loc => 1, org => 1, umb => 1 },
 },

 loc => {
  modes    => [ qw ( a2z top first ) ],
  dividers => 0,
  refines  => [ qw ( org umb ) ],
  jump     => { },
 },

 org => {
  modes    => [ qw ( a2z top first ) ],
  dividers => 0,
  refines  => [ qw ( umb loc ) ],
  jump     => { umb => 1 },
 },

 umb => {
  modes    => [ qw ( a2z top first ) ],
  dividers => 0,
  refines  => [ qw ( org loc ) ],
  jump     => { org => 1 },
 },

 folder => {
  modes    => [ ],
  dividers => 0,
  refines  => [ qw ( loc org umb breed breeder lens body ) ],
  jump     => { loc => 1, org => 1, umb => 1 },
 },

 cat => {
  modes    => [ qw ( a2z top first ) ],
  dividers => 1,
  refines  => [ qw ( nick code breed app breeder nat loc ) ],
  jump     => {
   nick    => 1,
   code    => 1,
   breed   => 1,
   app     => 1,
   breeder => 1,
   nat     => 1
  },
 },

 breeder => {
  modes    => [ qw ( a2z top first ) ],
  dividers => 1,
  refines  => [ qw ( breed feat app nat cat ) ],
  jump     => { nat => 1, cat => 1 },
 },

 nat => {
  modes    => [ qw ( a2z top first ) ],
  dividers => 0,
  refines  => [ qw ( breeder breed cat ) ],
  jump     => { breeder => 1, cat => 1 },
 },

 code => {
  modes    => [ qw ( a2z top first ) ],
  dividers => 1,
  refines  => [ qw ( app feat breeder cat ) ],
  jump     => { app => 1, feat => 1, cat => 1 },
 },

 app => {
  modes    => [ qw ( a2z top first ) ],
  dividers => 1,
  refines  => [ qw ( breed feat breeder cat ) ],
  jump     => { feat => 1, cat => 1 },
 },

 breed => {
  modes    => [ qw ( a2z cate top first ) ],
  dividers => 1,
  refines  => [ qw ( code feat breeder cat ) ],
  jump     => { code => 1, cat => 1 },
 },

 cate => {
  modes    => [ qw ( a2z top ) ],
  dividers => 0,
  refines  => [ qw ( breed breeder ) ],
  jump     => { breed => 1 },
 },

 feat => {
  modes    => [ qw ( a2z top first ) ],
  dividers => 0,
  refines  => [ qw ( breed app breeder cat ) ],
  jump     => { app => 1, cat => 1 },
 },

 nick => {
  modes    => [ qw ( a2z top first ) ],
  dividers => 1,
  refines  => [ qw ( cat ) ],
  jump     => { cat => 1 },
 },

 title => {
  modes    => [ qw ( a2z top first ) ],
  dividers => 0,
  refines  => [ qw ( breed breeder cat ) ],
  jump     => { cat => 1 },
 },

 lens => {
  modes    => [ qw ( a2z top first ) ],
  dividers => 0,
  refines  => [ qw ( body flen fnum ) ],
  jump     => { },
 },

 body => {
  modes    => [ qw ( a2z top first ) ],
  dividers => 0,
  refines  => [ qw ( lens iso ) ],
  jump     => { },  
 },

 fnum => {
  modes    => [ qw ( a2z top first ) ],
  dividers => 0,
  refines  => [ qw ( lens body ) ],
  jump     => { }, 
 },

 etime => {
  modes    => [ qw ( a2z top first ) ],
  dividers => 0,
  refines  => [ qw ( lens body ) ],
  jump     => { },
 },

 iso => {
  modes    => [ qw ( a2z top first ) ],
  dividers => 0,
  refines  => [ qw ( body ) ],
  jump     => { },
 },

 flen => {
  modes    => [ qw ( a2z top first ) ],
  dividers => 0,
  refines  => [ qw ( lens etime ) ],
  jump     => { },
 },

};

sub list_matrix { $MATRIX }

sub list_node { exists $MATRIX->{ $_[ 0 ] } ? $MATRIX->{ $_[ 0 ] } : undef }

1;