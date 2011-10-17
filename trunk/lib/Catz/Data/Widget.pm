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
 
package Catz::Data::Widget;

use 5.10.0; use strict; use warnings;

use parent 'Exporter';

our @EXPORT = qw ( widget_get );

my $widget = {}; # widget config

$widget->{width_min} = 100;
$widget->{width_default} = 468;
$widget->{width_max} = 2000;
$widget->{widths} = [ qw ( 125 234 240 250 300 336 468 720 728 800 1000 1024 ) ];

$widget->{height_min} = 50;
$widget->{height_default} = 60;
$widget->{height_max} = 200;
$widget->{heights} = [ qw ( 50 60 90 100 125 150 200 ) ];

$widget->{background} = '000000';

$widget->{strip}->{mode_default} = 'rand';
$widget->{strip}->{modes} = [ qw ( rand cron ) ];

sub widget_get { $widget }

1;