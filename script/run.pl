
use 5.10.0; use strict; use warnings;

use File::Basename 'dirname';
use File::Spec;

use lib join '/', File::Spec->splitdir(dirname(__FILE__)), 'lib';
use lib join '/', File::Spec->splitdir(dirname(__FILE__)), 'libi';
use lib join '/', File::Spec->splitdir(dirname(__FILE__)), '..', 'lib';
use lib join '/', File::Spec->splitdir(dirname(__FILE__)), '..', 'libi';

use Catz::Core::Conf;

eval 'use Mojolicious::Commands';

die <<EOF if $@;
It looks like you don't have the Mojolicious Framework installed.
Please visit http://mojolicio.us for detailed installation instructions.
EOF

$ENV{MOJO_APP} ||= 'Catz::Core::App';

conf ( 'win' ) and do {

 $ENV{MOJO_HOME} = conf ( 'rootd' );
 
 $ENV{MOJO_MODE} = 'production';
 #$ENV{MOJO_MODE} = 'development';
 
 #$ENV{MOJO_USERAGENT_DEBUG} = 1;
  
};

conf ( 'lin' ) and do {

 $ENV{MOJO_MODE} = 'production';

 $ENV{MOJO_HOME} = conf ( 'rootd' ) . '/catz' . conf ( 'env' );

};
 
Mojolicious::Commands->start;
