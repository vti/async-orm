use strict;
use warnings;

use Test::More tests => 3;

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

        $author->update_related(
            $dbh => 'author_admin' => {set => {beard => 1}} =>
              sub { ok($_[1]) });
    }
);

Author->new(id => $authors[0]->column('id'))->load(
    $dbh => {with => 'author_admin'} => sub {
        my ($dbh, $author) = @_;

        my $author_admin = $author->related('author_admin');
        ok($author_admin);
        is($author_admin->column('beard'), 1);
    }
);

$authors[0]->delete($dbh => sub { });
