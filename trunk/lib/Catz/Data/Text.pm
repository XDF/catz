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

package Catz::Data::Text;

use strict;
use warnings;

use Catz::Util::Data qw ( tolines topiles );

use base 'Exporter';

our @EXPORT = qw( text ); # force export of 'text' whenever used

# hashrefs to texts
my $en = {};
my $fi = {};

# initilize $en, $fi on module load 
foreach my $pile ( topiles ( join '', <DATA> ) ) {
    
 my @lines = tolines ( $pile );

 ( $lines[0] and $lines[1] and $lines[2] ) or die "text definition error";
 
 #print "storing $lines[0] = $lines[1]\n";
 #print "storing $lines[0] = $lines[2]\n";
 
 $en->{$lines[0]} = $lines[1];  
 $en->{$lines[0]} = $lines[2];
        
}

sub text { $_[0] eq 'fi' ? $fi : $en; }

1; 

__DATA__
ALL
all
kaikki
#
ALBUM
album
albumi
#
ALBUMS
albums
albumit
#
ALBUMS_LATEST
latest albums
tuoreimmat albumit
#
APPLICATION
catz web application platform and photo delivery engine
catz verkkosovellusalusta ja valokuvien jakelumoottori
#
AUTHOR
Heikki Siltala
Heikki Siltala
#
CAT
cat
kissa
#
CATS
cats
kissat
#
CREDITS
Mojolicious, Perl, SQLite, jQuery, Linux
Mojolicious, Perl, SQLite, jQuery, Linux
#
BODY
body
runko
#
BODYS
bodies
rungot
#
BREEDER
breeder
kasvattaja
#
BREEDERS
breeders
kasvattajat
#
COMPLETE_LIST
complete list
katso kaikki
#
COPYRIGHT
Copyright
Copyright
#
FIRSTYEAR
1994
1994
#
DATE
date
p‰iv‰m‰‰r‰
#
DATES
dates
p‰iv‰m‰‰r‰t
#
ETIME
exposure time
valotusaika
#
ETIMES
exposure times
valotusajat
#
FLEN
focal length
polttov‰li
#
FLENS
focal lengths
polttov‰lit
#
FNUM
aperture
aukko
#
FNUMS
apertures
aukot
#
GALLERIES
photo galleries
valokuvagalleriat
#
HAS
has
sis‰lt‰‰
#
BREED
breed
rotu
#
BREEDS
breeds
rodut
#
EMS1
EMS snippet
EMS-koodin osa
#
EMS1S
EMS snippets
EMS-koodin osat
#
EMS3
EMS breed
EMS-rotu
#
EMS3S
EMS breeds
EMS-rodut
#
EMS4
EMS color and pattern
EMS v‰ri ja kuvio
#
EMS4S
EMS colors and patterns
EMS v‰rit ja kuviot 
#
EMS5
EMS
EMS-koodi
#
EMS5S
EMS's
EMS-koodit
#
LOC
location
paikkakunta
#
LOCS
locations
paikkakunnat
#
NAT
nationality
kansallisuus
#
NATS
nationalities
kansallisuudet
#
NICK
nick
lempinimi
#
NICKS
nicks
lempinimet
#
ORG
organizer
j‰rjest‰j‰
#
ORGS
organizers
j‰rjest‰j‰t
#
OUT
photo comment
kuvateksti
#
OUTS
photo comments
kuvatekstit
#
TITLE
title
titteli
#
TITLES
titles
tittelit
#
UMB
umbrella
kattoj‰rjestˆ
#
UMBS
umbrellas
kattoj‰rjestˆt
#
FIND
instant find
pikahaku
#
IDEAS
ideas
ideat
#
ISO
sensitivity
herkkyys
#
ISOS
sensitivities
herkkyydet
#
LENS
lens
objektiivi
#
LENSS
lenses
objektiivit
#
EXCEPTION
500 exception occured
500 poikkeustilanne
#
LISTS
lists
luettelot
#
LICENCE
Creative Commons Attribution 3.0 Unported License
Creative Commons Nime‰ 3.0 Yleisversio -lisenssi
#
LICENCE_URL
http://creativecommons.org/licenses/by/3.0/deed.en
http://creativecommons.org/licenses/by/3.0/deed.fi
#
NEWS
news
uutiset
#
NEWS_LATEST
latest news
tuoreimmat uutiset
#
NOT_FOUND
404 page or resource not found
404 sivua tai resurssia ei lˆydy
#
NUM_GALLERY
photo galleries
valokuvagalleriaa
#
NUM_NAME
identified cats
tunnistettua kissaa
#
NEXT
next
seuraava
#
ORDER_A2Z
alphabetically
aakkosittain
#
ORDER_TOP
most common first
yleisyysj‰rjestyksess‰
#
OTHERLANG
suomeksi
in english
#
PAGE
page
sivu
#
PAGES
pages
sivua
#
PAGE_FIRST
first
alkuun
#
PAGE_PREV
previous
edellinen
#
PAGE_NEXT
next
seuraava
#
PAGE_LAST
last
loppuun
#
PHOTO
photo
kuva
#
PHOTO_FIRST
first
alkuun
#
PHOTO_PREV
previous
edellinen
#
PHOTO_NEXT
next
seuraava
#
PHOTO_LAST
last
loppuun
#
PHOTOS
photos
kuvaa
#
SAMPLES
samples
n‰ytteit‰
#
SEARCH
advanced search
superhaku
#
SEARC
search
haku
#
SEARCH_RESULT
search result
hakutulos
#
SEARCH_AND
AND
JA
#
SEARCH_NOT
NOT
EI
#
SEARCH_OR
OR
TAI
#
SEARCH_BEGIN_EXACT
begins with text
alkaa tekstill‰
# 
SEARCH_CONTAIN_EXACT
contains text
sis‰lt‰‰ tekstin
#
SEARCH_END_EXACT
ends with text
p‰‰ttyy tekstill‰
#
SEARCH_IS_EXACT
is exactly
on t‰sm‰lleen
#
SEARCH_BEGIN_PATTERN
begins with pattern
alkaa merkkijonolla
# 
SEARCH_CONTAIN_PATTERN
contains pattern
sis‰lt‰‰ merkkijonon
#
SEARCH_END_PATTERN
ends with pattern
p‰‰ttyy merkkijonoon
#
SEARCH_IS_PATTERN
is pattern 
on merkkijono
#
SETUP_palette_bright
bright palette
vaalea ulkoasu
#
SETUP_palette_dark
dark palette
tumma ulkoasu
#
SETUP_thumbsperpage_10
10 thumbnails per page
10 pikkukuvaa sivulla
#
SETUP_thumbsperpage_15
15 thumbnails per page
15 pikkukuvaa sivulla
#
SETUP_thumbsperpage_20
20 thumbnails per page
20 pikkukuvaa sivulla
#
SETUP_thumbsperpage_25
25 thumbnails per page
25 pikkukuvaa sivulla
#
SETUP_thumbsperpage_30
30 thumbnails per page
30 pikkukuvaa sivulla
#
SETUP_thumbsperpage_35
35 thumbnails per page
35 pikkukuvaa sivulla
#
SETUP_thumbsperpage_40
40 thumbnails per page
40 pikkukuvaa sivulla
#
SETUP_thumbsperpage_45
45 thumbnails per page
45 pikkukuvaa sivulla
#
SETUP_thumbsperpage_50
50 thumbnails per page
50 pikkukuvaa sivulla
#
SETUP_thumbsize_100
100 pixels thumbnails
100 pikselin pikkukuvat
#
SETUP_thumbsize_120
120 pixels thumbnails
120 pikselin pikkukuvat
#
SETUP_thumbsize_140
140 pixels thumbnails
140 pikselin pikkukuvat
#
SETUP_thumbsize_160
160 pixels thumbnails
160 pikselin pikkukuvat
#
SETUP_thumbsize_180
180 pixels thumbnails
180 pikselin pikkukuvat
#
SETUP_thumbsize_200
200 pixels thumbnails
200 pikselin pikkukuvat
#
SITE
catzz.biz
catzz.biz
#
SLOGAN
the world's most advanced cat show photo service
maailman edistynein kissan‰yttelykuvapalvelu
#
SUGGEST
suggestions
ehdotukset
#
THUMBS
thumbnails
pikkukuvat
#
TITLE_FEED
www.heikkisiltala.com feed
www.heikkisiltala.com virta
#