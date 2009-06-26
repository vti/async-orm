use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use TestDB;

use Article;
use Comment;

my $dbh = TestDB->dbh;

my $id;

Article->new(name => 'foo', comments => {title => 'foo'})->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        $id = $author->column('id');

        $author->delete_related($dbh => 'comments' => sub {});
    }
);

Comment->find(
    $dbh => {where => [type => 'article', master_id => $id], single => 1} => sub {
        my ($dbh, $comments) = @_;

        ok(not defined $comments);
    }
);

Article->new(id => $id)->load(
    $dbh => sub {
        my ($dbh, $article) = @_;

        ok($article);

        $article->delete($dbh => sub {});
    }
);

