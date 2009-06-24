use Test::More tests => 1;

use lib 't/lib';

use TestDB;

ok(TestDB->cleanup);
