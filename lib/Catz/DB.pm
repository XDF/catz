#
# The MIT License
# 
# Copyright (c) 1994-2011 Heikki Siltala
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

package Catz::DB;

#
# the database access module - all database access should use this module
# provides result set caching using Catz::Cache
#

use strict;
use warnings;

use feature qw( switch );

use parent 'Exporter';

our @EXPORT = qw ( db_one db_row db_col db_all );

use Apache::DBI;

use Catz::Cache;

use constant DBDRIVER => 'dbi:SQLite'; 

# a hardcoded value for initial development
use constant DBFILE => '/catz/db/data.db';

use constant DBARGS => { PrintError => 1, RaiseError => 1, AutoCommit => 0 };

# a static database connection
my $db = DBI->connect( DBDRIVER.':dbname='.DBFILE, undef, undef, DBARGS ) 
 || die ( $DBI::errstr );
  
Apache::DBI->setPingTimeOut($db, 5);
  
sub fetch {

 my $res;
    
 # attempt to get the result from the cache    
 if( $res = cache_get( @_ ) ) { return $res } 
    
 my ( $mode, $sql, @params ) = @_;
  
 given ( $mode ) {
 
  when ( 'one' ) { $res = $db->selectrow_array( $sql, undef, @params ) } 

  when ( 'row' ) { $res = $db->selectrow_arrayref( $sql, undef, @params ) } 

  when ( 'col' ) { $res = $db->selectcol_arrayref( $sql, undef, @params ) } 

  when ( 'all' ) { $res = $db->selectall_arrayref( $sql, undef, @params ) } 

  default { die "unknow database access mode '$mode'" } 
 
 }
 
 # if a result was fetched from the db then put it to cache
 cache_set( @_, $res );
 
 return $res;
 
}
 
# the exported subs are simple pass-thrus to internal fetch  
sub db_one { fetch ( 'one', @_ ) }
sub db_row { fetch ( 'row', @_ ) }
sub db_col { fetch ( 'col', @_ ) }
sub db_all { fetch ( 'all', @_ ) }

1; 