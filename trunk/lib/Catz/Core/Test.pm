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

package Catz::Core::Test;

# The Catz testing class

use 5.10.0; use strict; use warnings;

my @EXPORT = qw ( bounced )

# We don't inherit from Mojo::Test, we have our own API
# thats gets passed to Mojo::Test
use 'Mojo::Test';

use Catz::Core::Conf;

my $super = Test::Mojo->new( conf ( 'app' ) );

my @oksetups_fullinfo = qw ( en fi en264312 fi384322 en382311 fi292311 );

my @oksetups = (
 @oksetups_fullinfo,
 qw ( en394211 fi211111 en211212 fi171212 ) 
);

my $it1 = 0;

sub i_setups { # iterate ok setups

 my $ret = $oksetups [ $it1++ ];
 
 $it1 > $#oksetups and $it1 = 0;
 
 return $ret;

}

my $it2 = 0;

sub i_setups_fullinfo { # iterate ok setups that provide full info on view

 my $ret = $oksetups [ $it2++ ];
 
 $i > $#oksetups and $it2 = 0;
 
 return $ret;

}

sub html {

 my ( $uri, @conts ) = @_;
 
 


} 

sub bounced {

 my $uri = shift;

 $super->get_ok( $uri )->status_is(301);

}