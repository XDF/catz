#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2014 Heikki Siltala
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

package Catz::Ctrl::Reroute;

#
# handles redirection of old site's URLs under /galleries
#

use 5.16.2;
use strict;
use warnings;
no warnings 'experimental';

use parent 'Catz::Ctrl::Base';

use Const::Fast;

use Catz::Data::Text;
use Catz::Util::Number qw ( fullnum33 );
use Catz::Util::String qw ( acceptlang enurl deurl decode encode );

const my %CLASSIC => map { $_ => 1 } qw (
 2004_wwe_raw_helsinki agility_200910 arokatin_e around_finland
 cesmes_a cesmes_b cesmes_c culture_trip_lake_tuusula hel_sto_hel
 keimola_oldies myllypuro nytech_nd4020_era photoart1 suviyon_a the_farm
);

sub xdf2search {    # converts old search to new search

 my $xdf = shift;

 my @parts = split / +/, $xdf;

 scalar @parts > 30 and return undef;    ## no critic

 do {
  length ( $_ ) > 30 and return undef;    ## no critic
  }
  foreach @parts;

 my @out = ();

 foreach my $part ( @parts ) {

  my $tgt  = '';
  my $oper = '';

  if ( substr ( $part, 0, 1 ) eq '+' ) {

   $oper = '+';
   $part = substr ( $part, 1 );

  }
  elsif ( substr ( $part, 0, 1 ) eq '-' ) {

   $oper = '-';
   $part = substr ( $part, 1 );

  }

  if ( $part =~ /\[(.+)\]/ ) {

   $part = $1;
   $tgt  = 'feat=';

   length ( $part ) > 2 and $tgt = 'breed=';

  }
  elsif ( $part =~ /\{(.+)\}/ ) {

   $part = "*$1*";
   $tgt  = 'breeder=';

  }
  elsif ( $part =~ /\((.+)\)/ ) {

   $part = "*$1*";
   $tgt  = 'nick=';

  }
  else {

   $part = "*$part*";

  }

  push @out, "$oper$tgt$part";

 } ## end foreach my $part ( @parts )

 return join ' ', @out;

} ## end sub xdf2search

sub reroute {    # does the job

 my $self = shift;
 my $p = $self->{ stash }->{ src } // '/';

 my $lang = acceptlang ( $self->req->headers->accept_language );

 my $t = text ( $lang );

 given ( $p ) {

  when ( [ qw ( / index.htm index.html ) ] ) {
   return $self->moveto ( "/$lang/" );
  }

  when ( [ qw ( dates.htm dates.html ) ] ) {
   return $self->moveto ( "/$lang/list/date/cron/" );
  }

  when ( [ qw ( locations.htm locations.html ) ] ) {
   return $self->moveto ( "/$lang/list/loc/a2z/" );
  }

  when (
   [
    qw (
     breeders breeders/ breeders/index.htm breeders/index.html
     ems/breeders.htm ems/breeders.html
     )
   ]
   )
  {
   return $self->moveto ( "/$lang/list/breeder/a2z/" );
  }

  when ( m|^breeders/([a-zA-Z0-9_-]{1,200})\.html$| ) {

   my $br = decode ( $1 );

   if ( $self->fetch ( "reroute#isbreeder", $br ) ) {

    return $self->moveto ( "/$lang/browse/breeder/" . encode ( $br ) . '/' );

   }
   else {

    return $self->fail ( 'unknown breeder' );

   }

  }

  when ( [ qw ( ems ems/ ems/index.htm ems/index.html ) ] ) {
   return $self->moveto ( "/$lang/list/breed/a2z/" );
  }

  when ( m|^ems/([a-zA-Z]{3,3})\.htm(l)?$| ) {

   my $br = uc $1;

   ( $br eq 'PKU' ) and $br = 'HCL';
   ( $br eq 'PKN' ) and $br = 'HCL';
   ( $br eq 'PKX' ) and $br = 'HCL';

   ( $br eq 'LKU' ) and $br = 'HCS';
   ( $br eq 'LKN' ) and $br = 'HCS';
   ( $br eq 'LKX' ) and $br = 'HCS';

   if ( $self->fetch ( "reroute#isbreed", $br ) ) {

    return $self->moveto ( qq{/$lang/browse/breed/$br/} );

   }
   else {

    return $self->fail ( 'unknown breed' );

   }

  } ## end when ( m|^ems/([a-zA-Z]{3,3})\.htm(l)?$|)

  when ( m|^bestofbest| ) {
   return $self->moveto ( "/$lang/" );
  }

  when ( m|^stat| ) {
   return $self->moveto ( "/$lang/" );
  }

  when ( [ qw ( xdf xdf/ ) ] ) {
   return $self->moveto ( "/$lang/search/" );
  }

  when ( m|^xdf/(.{1,777}?)(\~\d{4})?$| ) {

   my $tgt = xdf2search ( $1 );

   # not found if conversion failed
   defined $tgt or return $self->fail ( 'search conversion error' );

   $tgt = enurl $tgt;

   return $self->moveto ( qq{/$lang/search?q=$tgt} );

  }

  default {    # process leftover folders

   my ( $folder, $tail ) = split /\//, $p;

   $tail or $tail = '';

   # ghost url mappings _misc _panel _gala

   if ( $folder =~ m|^(\d{8}[a-z]+)_misc$| ) {

    $folder = $1 . '1';

   }
   elsif ( $folder =~ m|^(\d{8}[a-z]+)_panel$| ) {

    $folder = $1 . '2';

   }
   elsif ( $folder =~ m|^(\d{8}[a-z]+)_gala$| ) {

    $folder = $1 . '2';

   }

   if ( exists $CLASSIC{ $folder } ) {

    # this is an classic folder still in .com

    return $self->moveto ( "$t->{URL_CLASSIC}photos/$folder/$tail/" );

   }
   elsif ( my $s = $self->fetch ( "reroute#folder2s", $folder ) )
   {    # current folder

    if ( $tail eq '' or $tail eq 'index.htm' or $tail eq 'index.html' ) {

     return $self->moveto ( "/$lang/browse/folder/$folder/" );

    }
    elsif ( $tail eq 'check1.htm' or $tail eq 'check1.html' ) {

     my $search = enurl "+folder=$folder -has=text";

     return $self->moveto ( "/$lang/search?q=$search" );

    }
    elsif ( $tail eq 'check2.htm' or $tail eq 'check2.html' ) {

     my $search = enurl "+folder=$folder +has=breed -has=cat";

     return $self->moveto ( "/$lang/search?q=$search" );

    }
    elsif ( $tail =~ /^(\d{4})\-\d{4}\.htm(l)?$/ ) {

     my $id = fullnum33 ( $s, int ( $1 ) );

     return $self->moveto ( "/$lang/browse/folder/$folder/$id/" );

    }
    elsif ( $tail =~ /^(\d{4})\.htm(l)?$/ ) {

     my $id = fullnum33 ( $s, int ( $1 ) );

     return $self->moveto ( "/$lang/view/folder/$folder/$id/" );

    }
    elsif ( $tail =~ /^(.+\.(JPG|jpg))$/ ) {

     my $tgt = uc $1;
     
     # handling some very old direct image URLs
     # added 2012-03-14
     $tgt =~ /^(.+)\s\(CUSTOM\)(\.JPG)$/ and $tgt = $1 . '_LR' . $2;
     
     return $self->moveto ( $t->{URL_CATZA} . "static/photo/$folder/$tgt" );

    }
    else { return $self->fail ( 'folder mapping error' ) }

   } ## end elsif ( my $s = $self->fetch... [ if ( exists $CLASSIC{ ...})])

   return $self->fail ( 'old url leftover' );

  } ## end default

 } ## end given

} ## end sub reroute

1;
