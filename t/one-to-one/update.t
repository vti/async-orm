use strict;
use warnings;

use Test::More tests => 9;

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

        $author->related('author_admin')->column(beard => 1);
        $author->update($dbh => sub { ok($_[1]) });
    }
);

Author->new(id => $authors[0]->column('id'))->load(
    $dbh => {with => 'author_admin'} => sub {
        my ($dbh, $author) = @_;

        my $author_admin = $author->related('author_admin');
        ok($author_admin);
        is($author_admin->column('beard'), 1);

        $author->column(name => 'bar');
        $author_admin->column(beard => 0);
        $author->update($dbh => sub {});
    }
);

Author->new(id => $authors[0]->column('id'))->load(
    $dbh => {with => 'author_admin'} => sub {
        my ($dbh, $author) = @_;

        is($author->column('name'), 'bar');

        my $author_admin = $author->related('author_admin');
        ok($author_admin);
        is($author_admin->column('beard'), 0);
    }
);

$authors[0]->delete($dbh => sub { });
