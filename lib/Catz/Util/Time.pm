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

package Catz::Util::Time;

use strict;
use warnings;

use DateTime;
use DateTime::Format::W3CDTF;
use Email::Date::Format qw( email_gmdate );
use HTTP::Date;
use POSIX qw( floor mktime );
use Time::localtime; 

use parent 'Exporter';

our @EXPORT_OK = qw(
 dtdate dttime dtexpand dt dt2epoch dtlang 
 epoch2rfc822 epoch2http http2epoch dt2w3c
 s2dhms thisyear 
);

#
# expands timestamp from YYYYMMDD or YYYYMMDDHHMMSS into 
# a language specific human-readable form
#
# in: timestamp, language
# out: timestamp converted to a human-readable form
#
sub dtexpand {
 
 # expands YYYYMMDD YYYYMMDDHHMMSS HHMMSS
 
 if ( length $_[0] == 8 ) {
 
  if ( ( $_[1] // 'en' ) eq 'fi' ) {
  
   return 
    int ( substr( $_[0], 6, 2 ) ) . '.' .
    int ( substr( $_[0], 4, 2 ) ) . '.' .
    substr( $_[0], 0, 4 );
  
  } else {

   return 
    substr( $_[0], 0, 4 ) . '-' .
    substr( $_[0], 4, 2 ) . '-' .
    substr( $_[0], 6, 2 );
   
  }    
 
 } elsif ( length $_[0] == 14 ) {

  if ( ( $_[1] // 'en' ) eq 'fi' ) {
  
   return 
    int ( substr( $_[0], 6, 2 ) ) . '.' .
    int ( substr( $_[0], 4, 2 ) ) . '.' .
    substr( $_[0], 0, 4 ) . ' ' .
    substr( $_[0], 8, 2 ) . ':' .
    substr( $_[0], 10, 2 ) . ':' .
    substr( $_[0], 12, 2 );
  
  } else {

   return 
    substr( $_[0], 0, 4 ) . '-' .
    substr( $_[0], 4, 2 ) . '-' .
    substr( $_[0], 6, 2 ) . ' ' .
    substr( $_[0], 8, 2 ) . ':' .
    substr( $_[0], 10, 2 ) . ':' .
    substr( $_[0], 12, 2 );
   
  }   
    
 } elsif ( length $_[0] == 6 ) {
 
   return 
    substr( $_[0], 0, 2 ) . ':' .
    substr( $_[0], 2, 2 ) . ':' .
    substr( $_[0], 4, 2 );
     
 } 
 
 # don't know what to do, to be safe return the input as is
 return $_[0];
  
}

#
# returns the system time in a timestamp format YYYYMMDDHHMMSS
#
sub dt {
 
 my ( $s, $mi, $h, $d, $mo, $y ) = @{ localtime( time ) };
 
 $y += 1900; $mo += 1;
 
 return sprintf( "%04d%02d%02d%02d%02d%02d", $y, $mo, $d, $h, $mi, $s );
  
}


#
# returns the systep time in a human-readable form
#
sub dtlang { dtexpand ( dt , $_[0] ) };

#
# returns the current year
#
sub thisyear {

 my ( undef, undef, undef, undef, undef, $y ) = @{ localtime( time ) };
 
 return $y + 1900;
 
}

sub dtdate { substr $_[0], 0, 8 }

sub dttime { substr $_[0], 8, 6 }

sub dt2epoch {

 my $dt = shift;
  
 $dt =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/;
  
 mktime ( $6, $5, $4, $3, $2 - 1, $1 - 1900 );

}

my $w3c = new DateTime::Format::W3CDTF;

sub dt2w3c {

 my $dt = DateTime->from_epoch ( epoch => dt2epoch $_[0] );

 $w3c->format_datetime ( $dt );

}

sub epoch2rfc822 { email_gmdate ( $_[0] ) }

sub epoch2http { time2str $_[0] }

sub http2epoch { str2time $_[0] }

# seconds to days hours minutes seconds

sub s2dhms {

 my @parts = gmtime shift;
 
 @parts [ 7, 2, 1, 0 ];

}  
 
1;