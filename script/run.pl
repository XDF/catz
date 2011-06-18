
use 5.10.0; use strict; use warnings;

use File::Basename 'dirname';
use File::Spec;

use lib join '/', File::Spec->splitdir(dirname(__FILE__)), 'lib';
use lib join '/', File::Spec->splitdir(dirname(__FILE__)), 'libi';
use lib join '/', File::Spec->splitdir(dirname(__FILE__)), '..', 'lib';
use lib join '/', File::Spec->splitdir(dirname(__FILE__)), '..', 'libi';

eval 'use Mojolicious::Commands';

die <<EOF if $@;
It looks like you don't have the Mojolicious Framework installed.
Please visit http://mojolicio.us for detailed installation instructions.
EOF

$ENV{MOJO_APP} ||= 'Catz::Core::App';

#$ENV{MOJO_HOME} = '/catz';
#$ENV{MOJO_MODE} = 'development';

Mojolicious::Commands->start;
