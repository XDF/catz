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

use 5.12.0; use strict; use warnings;

# unbuffered outputs
# from http://perldoc.perl.org/functions/open.html
select STDERR; $| = 1; 
select STDOUT; $| = 1; 

use Test::More;
use Test::Mojo;

use Catz::Data::Conf;
use Catz::Data::Text;

my $t = Test::Mojo->new( conf ( 'app' ) );

my @oksetups = qw ( en fi );

my @okintents = qw ( contrib margin missing );

my @okpalettes = qw ( dark neutral bright );
 
foreach my $intent ( @okintents ) {
 
 foreach my $palette ( @okpalettes ) {

  my $setup = $oksetups [ rand @oksetups ];
 
  $t->get_ok("/$setup/widget/contact/$intent/$palette/")
    ->status_is(200)
    ->content_type_like(qr/png/);  

  # no ending slash
  $t->get_ok("/$setup/widget/contact/$intent/$palette")->status_is(301); 
 
 } 
 
 
}

# illegal intents

$t->get_ok("/en/widget/contact/noxious/dark/")
  ->status_is(404);

$t->get_ok("/fi/widget/contact/undef/bright/")
  ->status_is(404);

# with setup

$t->get_ok("/en211211/widget/contact/contrib/neutral/")
  ->status_is(404);

$t->get_ok("/fi171212/widget/contact/missing/bright/")
  ->status_is(404);
 
done_testing;