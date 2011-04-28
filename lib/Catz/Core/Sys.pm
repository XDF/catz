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

package Catz::Core::Sys;

use 5.12.2;
use strict;
use warnings;

use Text::Xslate;

# use all Vaults here
use Catz::Vault::Vector;

# all we need is one static reference
my $tx = Text::Xslate->new();

sub new {

 my $class = shift;
 
 my $self = { 
  data => {}, # completely empty at the creation 
  OK => 200,
  NOTFOUND => 404,
  BOUNCEPERM => 301, 
  BOUNCETEMP => 302, 
  ERROR => 500,
  content_type => 'text/html'
 };
 
 bless ( $self, $class );

 return $self;

}

sub error {

 my ( $self, $reason ) = @_;

}

sub not_found {

 my ( $self, $reason ) = @_;

 $reason = "Not found: $reason";

 my $len = length ( $reason );

 return [ 
  404, 
  [ 'Content-Type' => 'text/plain', 'Content-Length' => length ( $reason ) ],
  [ $reason ]
 ];


}

sub bounce_temp {

 my ( $self, $to ) = @_;

}

sub bounce_perm {

 my ( $self, $to ) = @_;


}

sub render {

 my ( $self, $tmpl ) = @_; 

  $tmpl = "$tmpl.tx";

  return [ 
   $self->{OK},
   [ 'Content-Type' => $self->{data}->{content_type} // $self->{content_type} ],
   [ $tx->render( $tmpl, $self->{data} ) ]
  ];

} 

sub copy { { %{ $_[0] } } } # returns the copy of the object (hashref)                                            