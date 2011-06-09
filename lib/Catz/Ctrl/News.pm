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

use 5.10.0; use strict; use warnings;

use parent 'Catz::Core::Ctrl';

use XML::RSS;

use Catz::Core::Conf;
use Catz::Util::String qw ( limit );
use Catz::Util::Time qw ( dt2epoch epoch2rfc822 );

sub all { # the list of all news

 my $self = shift; my $s = $self->{stash};
 
 $s->{fanpage} = conf ( 'url_fanpage' );
 
 $s->{urlother} = '/' . $s->{langother} . '/news/';
  
 # edit this news is not listed in wiki!!! stash vars...
 $s->{news} = $self->fetch ( 'news#all' );
 
 $self->render( template => 'page/news' );

}


sub feed { # RSS feed of news

 my $self = shift; my $s = $self->{stash};
 
 my $news = $self->fetch ( 'news#latest', 10 ); # max 10 news
    
 my $rss = XML::RSS->new( version => '2.0' );

 $rss->channel(
  title => $s->{t}->{SITE},
  link => 'http://' . $s->{t}->{SITE} . '/',
  language => $s->{lang},
  lastBuildDate => epoch2rfc822 dt2epoch $s->{version},
 );
  
 foreach my $item (@$news) {
  $rss->add_item(
   title =>  $item->[1],
   link => 'http://' . $s->{t}->{SITE} . '/' . $s->{lang} . '/news/#'.$item->[0],
   description => limit ( $item->[2], 160 ),
   pubDate => epoch2rfc822 dt2epoch $item->[0],
  );
 }
 
 $self->render ( text => $rss->as_string, format => 'xml' )
 
}

1;