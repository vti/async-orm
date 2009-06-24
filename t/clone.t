use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use Author;

use TestDB;

my $dbh = TestDB->dbh;

Author->new(name => 'foo')->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        ok($author->column('id'));

        my $author2 = $author->clone;
        ok(not defined $author2->column('id'));

        $author->delete($dbh => sub { });
    }
);
