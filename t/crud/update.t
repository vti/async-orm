use strict;
use warnings;

use Test::More tests => 6;

use lib 't/lib';

use TestDB;

use Author;

my $dbh = TestDB->dbh;

my $id;

Author->new(name => 'foo', password => 'bar')->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        $id = $author->column('id');

        $author->column(name     => 'fuu');
        $author->column(password => 'boo');

        $author->update(
            $dbh => sub {
                my ($dbh, $author) = @_;

                is($author->column('name'),     'fuu');
                is($author->column('password'), 'boo');
            }
        );
    }
);

Author->new(id => $id)->load(
    $dbh => sub {
        my ($dbh, $author) = @_;

        is($author->column('name'),     'fuu');
        is($author->column('password'), 'boo');
    }
);

Author->update($dbh => {set => {name => 'haha'}} => sub { });

Author->new(id => $id)->load(
    $dbh => sub {
        my ($dbh, $author) = @_;

        is($author->column('name'),     'haha');
        is($author->column('password'), 'boo');

        $author->delete($dbh => sub {});
    }
);
