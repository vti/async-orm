use strict;
use warnings;

use Test::More tests => 4;

use lib 't/lib';

use TestDB;

use Author;
use AuthorAdmin;
use Admin;

my $dbh = TestDB->dbh;

Author->new(name => 'foo', author_admin => {beard => 0})->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        ok($author);

        my $author_admin = $author->related('author_admin');
        ok($author_admin);
        is($author_admin->column('author_id'), $author->column('id'));
        is($author_admin->column('beard'), 0);

        $author->delete($dbh => sub {});
    }
);
