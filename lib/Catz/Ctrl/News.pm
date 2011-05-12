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

package Catz::Ctrl::News;

use 5.10.0;
use strict;
use warnings;

use parent 'Catz::Ctrl::Base';

use XML::RSS;

use Catz::Data::Conf;
use Catz::Util::Time qw ( dt );

sub all { # the list of all news

 my $self = shift; my $s = $self->{stash};
 
 $s->{fanpage} = conf ( 'url_fanpage' );
  
 # edit this news is not listed in wiki!!! stash vars...
 $s->{news} = $self->fetch ( 'news#all' );
 
 $self->render( template => 'page/news' );

}

sub feed { # RSS feed of news

 my $self = shift; my $stash = $self->{stash};
 
 my $news = $self->fetch ( 'news' ); # edit this not in wiki stash vars!!!
   
 my $rss = XML::RSS->new( version => '2.0' );

 $rss->channel(
  title => $stash->{t}->{SITE},
  link => 'http://' . $stash->{t}->{SITE} . '/',
  lastBuildDate => dt,
  managingEditor => $stash->{t}->{AUTHOR}
 );
  
 foreach my $item (@$news) {
  $rss->add_item(
   title =>  $item->[2],
   link => 'http://' . $stash->{t}->{SITE} . '/' . $stash->{lang} . '/news/#'.$item->[0],
   description => $item->[3],
   pubDate => $item->[1],
  );
 }
 
 $self->render ( text => $rss->as_string, format => 'xml' )
 
}

1;