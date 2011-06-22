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

package Catz::Data::Result;

use 5.10.0; use strict; use warnings;

use parent 'Exporter';

our @EXPORT = qw ( result_prepare result_pack result_unpack result_process );

use Crypt::Blowfish;
use Crypt::CBC;
use MIME::Base32 qw ( RFC );
use Digest::HMAC_MD5 qw(hmac_md5_hex);

use Catz::Core::Conf;
use Catz::Util::String qw ( trim );
use Catz::Util::Time qw ( dtexpand );

my $eng = Crypt::CBC->new( 
 -key => conf ( 'result_key' ),
 -cipher => 'Blowfish'
);

my $results = { map { $_ => 1 } qw ( 
 BIS BIV BOB BOX CAC CACE CACIB CACS CAGCIB CAGPIB CAP CAPE CAPIB CAPS CH DVM
 EC EP EX EX1 GIC GIP IC IP JW KM NOM PR SC SP 
) };

sub result_prepare {

 my $app = shift; my $s = $app->{stash}; my $keys = shift;
 
 my $date = dtexpand ( shift @$keys, 'en' );
 my $loc = shift @$keys;
 
 my @out = ();

 foreach my $i ( 1 .. scalar @$keys ) {

  my $cat = $keys->[$i-1];

  $cat and push @out, result_pack ( $date, $loc, $cat );

 }
                 
 $s->{resultkey} = \@out;
 
}

sub result_pack {

 # join the data, run it thru encrypter and encode
 my $data = MIME::Base32::encode ( $eng->encrypt ( join '|', @_ ) );
 
 # calculate md5 digest using the configured key, output as hex
 my $dig = uc ( hmac_md5_hex ( $data, conf ( 'result_key' ) ) );
               
 # the outputted key contains 
 # * a letter to make it HTML DOM id save
 # * the encoded data
 # * the digest key for data integrity verification               
 my $key = "CATZ-$data-$dig";
  
 return $key;
  
}

sub result_unpack {

 # unpack the result key, return empty array in case of any error

 my $key = shift;
  
 if ( $key =~ /^CATZ\-([A-Z2-7]+)\-([0-9A-F]{32,32})$/ ) {
 
  my $data = $1; my $dig = $2;
  
  my $cmp = uc ( hmac_md5_hex ( $data, conf ( 'result_key' ) ) );
   
  $dig ne $cmp and return (); # data digest mismatch
 
  return split /\|/, $eng->decrypt ( MIME::Base32::decode ( $data ) );  
  
 } else {
 
  return ();
 
 }
  
}

sub result_process {

 my $raw = shift;

 my @items = ();

 my $rgender = undef;
 my $rclass = undef;

 foreach my $line ( split /\n/, $raw ) {

  my ( $date, $loc, $num, $cat, $class, $gender, $name, $code, $result )
   = split /\t/, $line;
  
  defined $result and push @items, 
   grep { $results->{ $_ } } split /\s+/, trim ( $result );

  $class =~ /(\d+)/;
  
  my $c = defined $1 ? int ( $1 ) : 0;
    
  ( $c == 11 or $c == 12 ) and $rclass = $c;

  ( $gender eq 'F' or $gender eq 'M' ) and $rgender = $gender;

 }
 
 my $result = join ' ', @items;

 if ( defined $rgender and defined $rclass ) {

  return [ $result, $rgender . $rclass ];

 } elsif ( defined $rgender ) {

  return [ $result, $rgender ];

 } else {

  return [ $result, undef ];

 }

}

1;
