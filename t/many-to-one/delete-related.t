use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use TestDB;

use Author;
use AuthorAdmin;
use Admin;

my $dbh = TestDB->dbh;

my $id;

Author->new(name => 'foo', author_admin => {beard => 0})->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        $id = $author->column('id');

        $author->delete_related($dbh => 'author_admin' => sub {});
    }
);

AuthorAdmin->find(
    $dbh => {where => [author_id => $id], single => 1} => sub {
        my ($dbh, $author_admin) = @_;

        ok(not defined $author_admin);
    }
);

Author->new(id => $id)->load(
    $dbh => sub {
        my ($dbh, $author) = @_;

        ok($author);

        $author->delete($dbh => sub {});
    }
);

