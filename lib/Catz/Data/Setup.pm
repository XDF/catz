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

use strict; use warnings; use 5.10.0;

use parent 'Exporter';

use Bit::Vector;

use POSIX qw ( ceil );

# The external interface is prodecural method calls

our @EXPORT = qw ( setup_init setup_keys setup_values setup_verify );

#
# the system configuration array that should be 
# edited only very seldom and with a MAXIMUM care
#
# changing any values within the existing array leads to random 
# configuration mixups on web users and the only exclusion to
# this rule is to changing the default values
#
# adding more configuration sets to the end of the array should
# be ok since they change only the end of the configuration
# bit vector and so don't affect the bits of the old configuration
#
# each set consists of 
#  configuration key, possible values and the default value
# 
my $conf = [
 [ 'display', [ qw ( none brief full ) ], 'full' ],
 [ 'palette', [ qw ( dark neutral bright ) ], 'dark' ],
 [ 'perpage', [ qw( 10 15 20 25 30 35 40 45 50 ) ], '15' ], 
 [ 'photosize', [ qw ( original fit ) ], 'fit' ],
 [ 'terpage', [ qw( 50 100 200 500 ) ], '100' ], 
 [ 'thumbsize', [ qw ( 100 125 150 175 200 ) ], '150' ],
 # ... if sometimes needed, add new set(s) here ...
];

# the integer value to character representation conversion array
# you should most likely NEVER modify the base32-compliant string
my $int2char = [ split //, '0123456789abcdefghjkmnpqrstvwxyz' ];

# the character representation to integer value conversion hash
my $char2int = {};

my $i = 0;

do { $char2int->{$_} = $i++ } foreach @$int2char;

# we use base32 that means a fixed 5 bits per a character
my $bitcnt = 5;

my $setkeys = (); # a prepared array of keys

my $def = {}; # detailed definitions

my $elen = 0; # length of bit vector (effective bits) 

foreach my $set ( @$conf ) {

 # collect an array of keys
 push @{ $setkeys }, $set->[0];

 # calculate the required lenght in bits for this key
 my $len = ceil sqrt ( scalar @{ $set->[1] } - 1 );
 
 # storing the start position in bit vector for this key
 $def->{$set->[0]}->{from} = $elen;
 
 $elen += $len;
 
 # storing the end position in bet vector for this key
 $def->{$set->[0]}->{to} = $elen - 1;
 
 # storing the length of bits of this key's values
 $def->{$set->[0]}->{len} = 
  $def->{$set->[0]}->{to} - $def->{$set->[0]}->{from} + 1; 
 
 # generate mappings from integers to strings and vice versa
 my $i = 0;
 
 foreach my $val ( @ { $set->[1] } ) {
 
  $def->{$set->[0]}->{toint}->{$val} = $i;
    
  $def->{$set->[0]}->{tostr}->{$i} = $val;
  
  $i++;
 
 }
 
 # default string value
 
 $def->{$set->[0]}->{defstr} = $set->[2];
 
 exists $def->{$set->[0]}->{toint}->{$set->[2]}
  or die "unable to locate default '$set->[2]' in '$set->[0]'";
 
 # default integer value
 $def->{$set->[0]}->{defint} = $def->{$set->[0]}->{toint}->{$set->[2]};
 
 # list of possible values in correct order
 $def->{$set->[0]}->{set} = $set->[1]; 

}
# length of configuration strings
my $slen = ceil ( $elen / $bitcnt ); 

# practical bit vector length, we use this value in vector creation 
my $blen = $slen * $bitcnt;

# we prepare an empty vector that can easily be cloned when new vectors are needed
my $empty = Bit::Vector->new ( $blen );

# we prepare a mask of least significant bits
my $mask = $empty->Clone;

$mask->Interval_Fill( 0, $bitcnt - 1 );

# we prepare bitmasks for all keys beforehand and store them into def
# they are handy when prosessing the configurations at runtime
  
foreach my $key ( @{ $setkeys } ) {

 my $v = Bit::Vector->new( $blen );
 
 $v->Interval_Fill(
  $def->{$key}->{from},
  $def->{$key}->{to}
 );

 $def->{$key}->{mask} = $v;
  
}

sub char2bit { # conversion from characters to bits

 my $r = $empty->Clone;
 
 my $i = 1; 

 # iterate char by char in reversed order
 foreach my $char ( split //, shift ) {
 
  # this has no effect on first round but 
  # is most important on other rounds
  $r->Move_Left( $bitcnt );
  
  my $v = $empty->Clone;
    
  $v->from_Dec ( $char2int->{ $char } ); 
 
  $r->Or ( $r, $v ); # collect results with OR 
 
 }
 
 return $r;

}

sub bit2char { # conversion from bits to characters

 my $r = shift;
 
 my $out = '';
 
 foreach ( 1 .. $slen ) {
 
  my $v = $mask->Clone;
  
  $v->And ( $r, $v );
  
  $out = $int2char->[ $v->to_Dec ] . $out; # build the output char by char
  
  $r->Move_Right ( $bitcnt ); # discard already processed bits from right
 
 }
 
 return $out;

}

sub bit2arr { # explode a bit representation into arrayref of key,value,key,value...

 my $r = shift;

 my @out = ();
 
 foreach my $key ( @{ $setkeys } ) {
 
  my $v = $def->{$key}->{mask}->Clone;
  
  $v->And ( $r, $v );
  
  $v->Move_Right ( $def->{$key}->{from} );
  
  push @out, $key;
  
  push @out, $def->{$key}->{tostr}->{ $v->to_Dec };

 }
 
 return \@out;

}

sub arr2bit { # implode a key,value,key,value array into bits

 my $arr = shift;
 
 my $r = $empty->Clone();
  
 for ( my $i = 0; $i < scalar( @$arr ); $i = $i + 2 ) {
 
  # key now in $arr->[$i], value in $arr->[$i+1]
  
  my $v = $empty->Clone();
  
  $v->from_Dec ( 
   $def->{ $arr->[$i] }->{toint}->{ $arr->[$i+1] }
  );
  
  # copy these new bits to the result bits
  
  $r->Interval_Substitute(
   $v,
   $def->{ $arr->[$i] }->{from},
   $def->{ $arr->[$i] }->{len},
   0,
   $def->{ $arr->[$i] }->{len}
  );
  
 }
 
 return $r; 
 
}

# prepare a default string representation

my $default = 
 bit2char arr2bit ( [ map { $_, $def->{$_}->{defstr} } @$setkeys ] );

sub setup_change { # change one value on the fly, return the new char repres

 my ( $chars, $key, $value ) = @_;
 
 my $r = char2bit $chars;
  
 my $v = $empty->Clone();
   
 $v->from_Dec ( $def->{ $key }->{toint}->{ $value } );

 $r->Interval_Substitute(
  $v, $def->{ $key }->{from}, $def->{ $key }->{len},
  0, $def->{ $key }->{len}
 );
 
 return bit2char $r;
   
}

sub setup_init { # initialize the setup to application stash

 my $app = shift;
 my $key = shift // $default; # if undef then use the default key
 
 my $pairs = bit2arr char2bit $key;
  
 for ( my $i = 0; $i < scalar @{ $pairs }; $i = $i + 2 ) {
  
  # copy key-value -pairs to stash
 $app->{stash}->{ $pairs->[ $i ] } = $pairs->[ $i + 1 ];
   
 }
 
 # modifies $app object, returns nothing
  
}

sub setup_keys { $setkeys };

sub setup_values { 

 # generates lists of setup values and change targets
 # uses directly application stash variable $langa

 my $langa = shift;
 
 my $lang = substr ( $langa, 0, 2 );
   
 my $chars = length ( $langa ) == 6 ? substr ( $langa, 3 ) : '';
  
 my $out = {};
 
 foreach my $key ( @{ $setkeys } ) {
 
  my @pile = ();
  
  foreach my $t ( @{ $def->{$key}->{set} } ) { 

   my $new = setup_change ( $chars, $key, $t );
   
   $new eq $default and $new = '';
 
   push @pile, [ $t, ( $lang eq '' ? '' : $lang . '_' ) . $new ];
   
  }
  
  $out->{$key} = \@pile;
  
 }
 
 return $out;

}

warn $default;

sub setup_verify { $def->{$_[0]}->{toint}->{$_[1]} ? 1 : 0 }
 

1; 