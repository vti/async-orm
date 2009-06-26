use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use TestDB;

use Author;
use Article;

my $dbh = TestDB->dbh;

my $id;

Author->new(name => 'foo', articles => {title => 'foo'})->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        $id = $author->column('id');

        $author->delete($dbh => sub {});
    }
);

Author->new(id => $id)->load(
    $dbh => sub {
        my ($dbh, $author) = @_;

        ok(not defined $author);
    }
);

Article->find(
    $dbh => {where => [author_id => $id], single => 1} => sub {
        my ($dbh, $article) = @_;

        ok(not defined $article);
    }
);
