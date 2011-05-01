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

 ( $lines[0] and $lines[1] and $lines[2] ) or die "text definition error: '$lines[0]' '$lines[1]' '$lines[2]'";
 
 #print "storing $lines[0] = $lines[1]\n";
 #print "storing $lines[0] = $lines[2]\n";
 
 $en->{$lines[0]} = $lines[1];  
 $fi->{$lines[0]} = $lines[2];
        
}

close DATA;

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
ALBUMA
albums
albumia
#
ALBUMS_ALL
all albums
kaikki albumit
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
CATA
cats
kissaa
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
BODYA
bodies
runkoa
#
BREEDER
breeder
kasvattaja
#
BREEDERS
breeders
kasvattajat
#
BREEDERA
breeders
kasvattajaa
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
DT
timestamp
aikaleima
#
DATE
date
p‰iv‰m‰‰r‰
#
DATES
dates
p‰iv‰m‰‰r‰t
#
DATEA
dates
p‰iv‰m‰‰r‰‰
#
ETIME
exposure time
valotusaika
#
ETIMES
exposure times
valotusajat
#
ETIMEA
exposure times
valotusaikaa
#
FLEN
focal length
polttov‰li
#
FLENS
focal lengths
polttov‰lit
#
FLENA
focal lengths
polttov‰li‰
#
FNUM
aperture
aukko
#
FNUMS
apertures
aukot
#
FNUMA
apertures
aukkoa
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
BREEDA
breeds
rotua
#
EMS1
attribute
ominaisuus
#
EMS1S
attributes
ominaisuudet
#
EMS1A
attributes
ominaisuutta
#
EMS3
breed code
rotukoodi
#
EMS3S
breed codes
rotukoodit
#
EMS3A
breed codes
rotukoodia
#
EMS4
color
v‰ri
#
EMS4S
colors
v‰rit
# 
EMS4A
colors
v‰ri‰ 
#
EMS5
code
koodi
#
EMS5S
codes
koodit
#
EMS5A
codes
koodia
#
LOC
location
paikka
#
LOCS
locations
paikat
#
LOCA
locations
paikkaa
#
NAME
album
albumi
#
NAMES
albums
albumit
#
NAMEA
albums
albumia
#
NAT
country
maa
#
NATS
countries
maat
#
NATA
countries
maata
#
NICK
nickname
lempinimi
#
NICKS
nicknames
lempinimet
#
NICKA
nicknames
lempinime‰
#
ORG
organizer
j‰rjest‰j‰
#
ORGS
organizers
j‰rjest‰j‰t
#
ORGA
organizers
j‰rjest‰j‰‰
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
TITLEA
titles
titteli‰
#
UMB
umbrella
kattoj‰rjestˆ
#
UMBS
umbrellas
kattoj‰rjestˆt
#
UMBA
umbrellas
kattoj‰rjestˆ‰
#
FIND
instant find
pikahaku
#
FIND_NOTHING
nothing found
ei tuloksia
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
ISOA
sensitivities
herkkyytt‰
#
LENS
lens
objektiivi
#
LENSS
lenses
objektiivit
#
LENSA
lenses
objektiivia
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
NEWS_ALL
all news
kaikki uutiset
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
MODE_A2Z
alphabetically
aakkosittain
#
MODE_TOP
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
<< first page
<< ensimm‰inen sivu
#
PAGE_PREV
< previous page
< edellinen sivu
#
PAGE_NEXT
next page >
seuraava sivu >
#
PAGE_LAST
last page >>
viimeinen sivu >>
#
PHOTO
photo
kuva
#
PHOTO_FIRST
<< first photo
<< ensimm‰inen kuva
#
PHOTO_PREV
< previous photo
< edellinen kuva
#
PHOTO_NEXT
next photo >
seuraava kuva >
#
PHOTO_LAST
last photo >>
viimeinen kuva >>
#
PHOTOS
photos
kuvat
#
PHOTOA
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
SETUP_display_full
full data
t‰ydet tiedot
#
SETUP_display_brief
brief data
tiivit tiedot
#
SETUP_display_none
no data
ei tietoja
#
SETUP_palette_bright
bright palette
vaaleat s‰vyt
#
SETUP_palette_neutral
neutral palette
neutraalit s‰vyt
#
SETUP_palette_dark
dark palette
tummat s‰vyt
#
SETUP_perpage_10
10 photos
10 kuvaa
#
SETUP_perpage_15
15 photos
15 kuvaa
#
SETUP_perpage_20
20 photos
20 kuvaa
#
SETUP_perpage_25
25 photos
25 kuvaa
#
SETUP_perpage_30
30 photos
30 kuvaa
#
SETUP_perpage_35
35 photos
35 kuvaa
#
SETUP_perpage_40
40 photos
40 kuvaa
#
SETUP_perpage_45
45 photos
45 kuvaa
#
SETUP_perpage_50
50 photos
50 kuvaa
#
SETUP_photosize_fit
fit to screen
sovita ruutuun
#
SETUP_photosize_original
original size
aito koko
#
SETUP_thumbsize_100
tiny size
pienin koko
#
SETUP_thumbsize_125
small size
pieni koko
#
SETUP_thumbsize_150
default size
oletuskoko
#
SETUP_thumbsize_175
large size
suuri koko
#
SETUP_thumbsize_200
x-large size
suurin koko
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
VIEW_PHOTO
view photo
katso kuva
#
BROWSE
browse thumbnails
selaa pikkukuvia
#
INSPECT
more information
tarkemmat tiedot
#
VIEW
view photos
katso kuvat
#