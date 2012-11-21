#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2012 Heikki Siltala
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


use 5.14.2;
use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec;

use lib join '/', File::Spec->splitdir ( dirname ( __FILE__ ) ), 'lib';
use lib join '/', File::Spec->splitdir ( dirname ( __FILE__ ) ), '..', 'lib';

use Catz::Data::Conf;

eval { use Mojolicious::Commands };

die <<EOF if $@;
It looks like you don't have the Mojolicious Framework installed.
Please visit http://mojolicio.us for detailed installation instructions.
EOF

$ENV{ MOJO_APP } = conf ( 'app' );

# added 2012-22-11 to prevent "Maximum message size exceeded"
# seen when running tests on dev with Mojolicious 3.59
$ENV{ MOJO_MAX_MESSAGE_SIZE } = conf ( 'msglimit' );

# added 2011-10-15 to prevent responses to go
# to file and issues with page caching
$ENV{ MOJO_MAX_MEMORY_SIZE } = conf ( 'msgmemlimit' );

conf ( 'win' ) and do {

 $ENV{ MOJO_HOME } = conf ( 'rootd' );

 $ENV{ MOJO_MODE } = 'production';

 ### $ENV{MOJO_MODE} = 'development';

 ### $ENV{MOJO_USERAGENT_DEBUG} = 1;

};

conf ( 'lin' ) and do {

 $ENV{ MOJO_MODE } = 'production';

 $ENV{ MOJO_HOME } = conf ( 'rootd' ) . '/catz' . conf ( 'env' );

};

Mojolicious::Commands->start;
