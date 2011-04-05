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

package Catz::Data::Conf;

use strict;
use warnings;

use feature qw ( switch );

use parent 'Exporter';

our @EXPORT = qw ( conf );

# the base directory of the system, used to define paths
my $base = '/catz';

my $conf = { # config is one hash ref

 # body name resoving sub
 
 cache => {
  driver => 'File',
  namespace => 'catzz.biz',
  root_dir => "$base/cache",
  depth => 3,
  max_key_length => 250
 },
  
 # db arguments for the web system
 dbargs_runtime => { AutoCommit => 1, RaiseError => 1, PrintError => 1 },
 
 # db arguments for the loader
 dbargs_load => { AutoCommit => 0, RaiseError => 1, PrintError => 1 },

 # the database driver name part on the connection string
 dbconn => 'dbi:SQLite:dbname=',
 
 # the file extension of the meta files to be loaded
 ext_meta => 'txt',

 # converts metadata filename to database table name 
 file2table => sub {

  $_[0] =~ /^(.+)meta/;
  
  $1 or die "unable to convert filename '$_[0]' to tablename";
  
  return "m$1";

 },
 
 file_lock => "lock.txt",
 file_meta => "meta.zip", 

 # lenses' techical names and the corresponding visible names 
 lensname => {
  'lbc' => 'Lensbaby Composer',
  'lbc_dg' => 'Lensbaby Composer & Dougle Glass Optic',
  'lbc_sg' => 'Lensbaby Composer & Single Glass Optic',
  'lbc_sf' => 'Lensbaby Composer & Soft Focus Optic',
  'peleng8' => 'Peleng 8mm f/3.5 Fisheye',
  'jupiter85' => 'MC Jupiter-9 85mm f/2.0',
  'jupiter135' => 'Jupiter-37AM 135mm f/3.5',
  'tokina17' => 'Tokina 17mm f/3.5 AT-X Pro',
  'tamron2875' => 'Tamron SP AF 28-75mm f/2.8 XR Di LD',
  'canon50ii' => 'Canon EF 50mm f/1.8 II',
  'canon50usm' => 'Canon EF 50mm f/1.4 USM',
  'canon85usm' => 'Canon EF 85mm f/1.8 USM',
  'sigma70300' => 'Sigma 70-300mm f/4-5.6 APO Macro Super II',
  'rubinar500' => 'MC Rubinar 500mm f/8 Reflex',
  'canon28' => 'Canon EF 28mm f/2.8',
  'canon1855' => 'Canon EF-S 18-55mm f/3.5-5.6',
  'canon70200l' => 'Canon EF 70-200mm f/2.8L IS USM', 
  'canon50ii+2x' => 'Canon EF 50mm f/1.8 II & Tamron 2X MC7 C-AF1 BBAR',
  'canon85usm+2x' => 'Canon EF 85mm f/1.8 USM & Tamron 2X MC7 C-AF1 BBAR',
  'sigma28' => 'Sigma 28mm f/1.8 EX DG',
  'sigma30' => 'Sigma 30mm f/1.4 EX DC HSM',
  'sigma10' => 'Sigma 10mm f/2.8 EX DC HSM Fisheye',
  'sigma50' => 'Sigma 50mm f/1.4 EX DG HSM',
  'sigma85' => 'Sigma 85mm f/1.4 EX DG HSM',
  'canon135l' => 'Canon EF 135mm f/2.0 L USM',
  'canon200l' => 'Canon EF 200mm f/2.8 L II USM',
  'lx3leica' => 'Leica DC Vario-Summicron 5.1-12.8mm f/2.0-2.8',
  'dmwlw64' => 'Leica DC Vario-Summicron 5.1-12.8mm f/2.0-2.8 & DMW-LW46',
  'nytech_nd4020' => 'Nytech ND-4020 Lens'
 },
 
 lensflen => {
  'peleng8' => '8 mm',
  'jupiter85' => '85 mm',
  'jupiter135' => '135 mm',
  'tokina17' => '17 mm',
  'canon50ii' => '50 mm',
  'canon50usm' => '50 mm',
  'canon85usm' => '85 mm',
  'rubinar500' => '500 mm',
  'canon28' => '28 mm', 
  'canon50ii+2x' => '100 mm',
  'canon85usm+2x' => '170 mm',
  'sigma28' => '28 mm',
  'sigma30' => '30 mm',
  'sigma10' => '10 mm',
  'sigma50' => '50 mm',
  'sigma85' => '85 mm',
  'canon135l' => '135 mm',
  'canon200l' => '200 mm'
 },
 
 location => {
  myrskyla => 'myrskylä',
  hyvinkaa => 'hyvinkää',
  jamsa => 'jämsä',
  palkane => 'pälkäne',
  hameenlinna => 'hämeenlinna',
  jyvaskyla => 'jyväskylä',
  seinajoki => 'seinäjoki',
  jarvenpaa => 'järvenpää',
  siilinjarvi => 'siilinjärvi',
  riihimaki => 'riihimäki'
 },
 
 # text macros used in source data
 macro => {
  front => "\"(front)|(edessä)\"",
  back => "\"(back)|(takana)\"",
  bottom => "\"(bottom)|(alimpana)\"",
  top => "\"(top)|(ylimpänä)\"",
  middle => "\"(middle)|(keskellä)\"",
  center => "\"(middle)|(keskellä)\"",
  left => "\"(left)|(vasemmalla)\"",
  right => "\"(right)|(oikealla)\"",
  floor => "\"(floor)|(lattialla)\"",
  bonus => "\"bonus photo|bonuskuva\"",
  view => "\"view over the show site|yleiskuvaa näyttelypaikalta\"",
  panel => "\"the panel|paneeli\""
 },
 
 # metafiles to be loaded and the loading order
 metafiles => [ qw ( exifmeta newsmeta countrymeta breedmeta breedermeta gallerymeta ) ],
  #metafiles => [ qw ( textmeta newsmeta countrymeta breedmeta breedermeta gallerymeta ) ],
  
  
 # the filename ending for thumbnail files
 part_thumb => '_LR.JPG',

 path_log => $base . '/' . 'log',
 path_master => $base . '/data/master',
 #path_meta => $base . '/data/meta',
 path_meta => '/www/galleries/0dat', 
 path_photo => '/www/galleries', 
 
 #results => map { $_ => 1 } qw ( BIS BIV BOB BOX CAC CACE CACIB CACS CAGCIB CAGPIB CAP CAPE CAPIB CAPS CH EC EP EX EX1 EX2 EX3 EX4 EX5 EX6 EX7 EX8 EX9 GIC GIP IC IP KM NOM PR SC SP 1 2 3 4 5 6 7 8 9 1. 2. 3. 4. 5. 6. 7. 8. 9. )
  
};

sub conf { $conf->{$_[0]} } # an unified API sub to read any config
