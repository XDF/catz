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

package Catz::Model::Access;

use strict;
use warnings;

use parent 'Exporter';

our @EXPORT = qw ( access );

use Catz::Data::Cache;
use Catz::Data::Conf;
use Catz::Data::DB;

# !!! "static use" of all Model modules here !!!
# otherwise their subs are not found at runtime
use Catz::Model::List;
use Catz::Model::Misc;
use Catz::Model::Photo;
use Catz::Model::Result;
use Catz::Model::Vector;

my $dbs = {}; # static hashref to keep database connections hashed on dt

sub access {

 my ( $dt, $lang, $sub, @args ) = @_;
 
 my $res;
 
 if ( conf('cache_model' ) ) {
 
  # try to get the requested result from the cache
  
  $res = cache_get ( $dt, $lang, $sub, @args );
 
  $res and return $res; # if cache hit then done
 
 }
 
 $dbs->{$dt} or ( $dbs->{$dt} = Catz::Data::DB->new ( $dt ) );
 
 { 

  no strict 'refs';

  $res = $sub->( $dbs->{$dt}, $lang, @args );
 
 }
 
 if ( conf('cache_model' ) ) {
  cache_set ( $dt, $lang, $sub, @args, $res );
 }
 
 return $res; 

}