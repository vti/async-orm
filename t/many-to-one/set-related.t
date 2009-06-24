use strict;
use warnings;

use Test::More tests => 8;

use lib 't/lib';

use TestDB;

use Author;
use AuthorAdmin;
use Admin;

my $dbh = TestDB->dbh;

my @authors;

Author->new(name => 'foo')->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        push @authors, $author;

        $author->set_related(
            $dbh => 'author_admin' => {beard => 1} => sub {
                my ($dbh, $author_admin) = @_;

                ok($author_admin);
                is($author_admin->column('beard'), 1);
            }
        );
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

$authors[0]->set_related(
    $dbh => 'author_admin' => {beard => 0} => sub {
        my ($dbh, $author_admin) = @_;

        ok($author_admin);
        is($author_admin->column('beard'), 0);
    }
);

Author->new(id => $authors[0]->column('id'))->load(
    $dbh => {with => 'author_admin'} => sub {
        my ($dbh, $author) = @_;

        my $author_admin = $author->related('author_admin');
        ok($author_admin);
        is($author_admin->column('beard'), 0);
    }
);

$authors[0]->delete($dbh => sub { });
