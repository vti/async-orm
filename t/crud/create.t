use strict;
use warnings;

use Test::More tests => 13;

use lib 't/lib';

use TestDB;

use Author;

my $dbh = TestDB->dbh;

Author->new->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        ok($author);
        ok($author->column('id'));
        ok(not defined $author->column('name'));
        ok(not defined $author->column('password'));

        $author->delete($dbh => sub { });
    }
);

Author->new(name => 'foo')->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        ok($author);
        ok($author->column('id'));
        is($author->column('name'), 'foo');
        ok(not defined $author->column('password'));

        $author->delete($dbh => sub { });
    }
);

Author->new(name => 'boo', password => 'bar')->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        ok($author);
        ok($author->column('id'));
        is($author->column('name'),     'boo');
        is($author->column('password'), 'bar');

        $author->create(
            $dbh => sub {
                my ($dbh, $author) = @_;

                is($author->is_modified, 0);
            }
        );

        $author->delete($dbh => sub { });
    }
);
