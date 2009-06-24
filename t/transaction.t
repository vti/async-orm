use strict;
use warnings;

use Test::More tests => 4;

use lib 't/lib';

use Author;

use TestDB;

my $dbh = TestDB->dbh;

my $a;

Author->begin_work($dbh => sub { });
Author->new(name => 'foo')
  ->create($dbh => sub { my ($dbh, $author) = @_; $a = $author; });
Author->count($dbh => sub { my ($dbh, $count) = @_; is($count, 1); });
Author->rollback($dbh => sub { });
Author->count($dbh => sub { my ($dbh, $count) = @_; is($count, 0); });

Author->begin_work($dbh => sub { });
Author->new(name => 'foo')
  ->create($dbh => sub { my ($dbh, $author) = @_; $a = $author; });
Author->count($dbh => sub { my ($dbh, $count) = @_; is($count, 1); });
Author->commit($dbh => sub { });
Author->count($dbh => sub { my ($dbh, $count) = @_; is($count, 1); });

$a->delete($dbh => sub { });
