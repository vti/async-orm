use strict;
use warnings;

use Test::More tests => 4;

use lib 't/lib';

use TestDB;

use Author;
use AuthorAdmin;
use Admin;

my $dbh = TestDB->dbh;

my @authors;

Author->new(name => 'foo', author_admin => {beard => 0})->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        push @authors, $author;

    }
);

Author->new(id => $authors[0]->column('id'))->load(
    $dbh => sub {
        my ($dbh, $author) = @_;

        $author->load_related(
            $dbh => 'author_admin' => sub {
                my ($dbh, $author_admin) = @_;

                ok($author_admin);
                is($author_admin->column('beard'), 0);

                $author_admin = $author->related('author_admin');

                ok($author_admin);
                is($author_admin->column('beard'), 0);
            }
        );
    }
);

$authors[0]->delete($dbh => sub { });
