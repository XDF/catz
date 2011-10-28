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

package Catz::Util::String;

use 5.10.0; use strict; use warnings;

use base 'Exporter';

our @EXPORT_OK = qw ( 
 clean decode deurl dna encode enurl lcc limit 
 label nobreak noxss trim ucc ucclcc urirest fuse fuseq
 topiles topilex tolines
); 

use Digest::MD5 qw ( md5_base64 );
use URI::Escape::XS qw ( uri_escape uri_unescape );

# prepare a conversion hash to be used by encode
# the hash was addded to make encoding run faster

my %cconv = ();

sub chrprep {
 
 (
  ( ( $_[0] > 47) && ( $_[0] < 58 ) ) || 
  ( ( $_[0]>64 ) && ( $_[0] < 91 ) ) ||
  ( ( $_[0]>96 ) && ( $_[0] < 123 ) ) 
 ) ? chr ( $_[0] ) : 
 ( ( $_[0] == 32 ) ? '_' : ( '-' . sprintf ( "%03d", $_[0] ) ) )
   
}

do { $cconv { chr ($_) } = chrprep ( $_ ) } foreach ( 0 .. 255 );

#
# trims extra spaces = several adjacent spaces becomes a single space
#
sub clean { $_ = shift; s/\s+/ /g; $_; }

#
# converts an encoded string back from its unencoded ascii form
#
# teXT-039-043-045-0631234 -> teXT'+-?1234
# bn-061ch-037-045-045-045 -> bn=ch%---
# This_Ain-039t_Jungle -> This Ain't Jungle
# A-039rdn-225n_Nau_Mau-039s -> A'rdnán Nau Mau's
#

sub decode { $_ = $_[0]; s/\-(\d\d\d)/chr($1)/ge; s|_| |g; return $_; }

#
# url decodes a string
#
sub deurl { uri_unescape $_[0] }
 
#
# returns MD5 checksum for a string as a base64 string
#
sub dna { md5_base64 ( $_[0] ) }

#
# converts a ascii string to a form that has no special characters
# a-z,A-Z and digits are not modified, everything else gets encoded
# an encoded character gets format "-xyz" where xyz is the ascii value
# an exception to this is space which becomes underscore
#
# examples:
# teXT'+-?1234 -> teXT-039-043-045-0631234
# bn=ch%--- -> bn-061ch-037-045-045-045
# This Ain't Jungle -> This_Ain-039t_Jungle
# A'rdnán Nau Mau's -> A-039rdn-225n_Nau_Mau-039s
#

sub encode { join '', map { $cconv { $_ } } split //, $_[0] // '' }

#
# url encodes a string
#
sub enurl { uri_escape $_[0] }

#
# limits string length to a given length, if truncates then adds '...'
#
sub limit {

 $_[0] or return; # no work on undef 

 ( length $_[0] < $_[1] ) and return $_[0];
 
 return substr ( $_[0], 0, $_[1] - 3 ) . '...';

}

#
# converts a string to lower case, manages also some umlaut chars
#
sub lcc { $_ = $_[0]; tr|ÜÅÄÖ|üåäö|; lc }

#
# converts all spaces in a string to HTML nbsp entities
#
sub nobreak { $_ = $_[0]; s/ /\&nbsp;/g; $_; }

#
# filters search query parameter to be included into HTML
# this is not XSS prevention - this is cosmetic
#
sub noxss {

 $_ = $_[0];
 
 s|src\=||gi; 
 s|http\:\/\/||gi;
 
 $_;

};

#
# trims all whitespace chars from the beginning and from the end
#
sub trim { $_ = $_[0]; s/^\s+//; s/\s+$//; $_; }

#
# converts a string to upper case, handles also some umlaut chars
#
sub ucc { $_ = $_[0]; tr|üåäö|ÜÅÄÖ|; uc }

#
# converts "string" to "String", manages also some umlaut chars
#
sub ucclcc { ucc ( substr ( $_[0], 0, 1 ) ) . lcc ( substr ( $_[0], 1 ) ) }

sub urirest { 

 # remove the beginning of uri (the language/config part)
 
 $_[0] =~ m|^\/(?:..(?:[1-9]{6})?)(.*)$|;
 
 $1 ? $1 : '';
   
}

#
# fusion of URL/URI parts
#
sub fuse { join '/', ( '', @_, '' ) }

#
# fusion of URL/URI parts with no ending slash
#
sub fuseq { join '/', ( '', @_ ) }

sub tolines { map { trim( $_ ) } split /\n/, trim ( $_[0] ) }

sub topiles { map { trim( $_ ) } split /\#/, trim ( $_[0] ) }

# new processing for changed metacore format 2011-09-02
sub topilex { map { trim( $_ ) } split /\-{8,}/, trim ( $_[0] ) }

1;