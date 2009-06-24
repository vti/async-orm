use strict;
use warnings;

use Test::More tests => 3;

use lib 't/lib';

use TestDB;

use Article;
use ArticleTagMap;
use Tag;

my $dbh = TestDB->dbh;

my $id;

Article->new(name => 'foo', tags => {name => 'foo'})->create(
    $dbh => sub {
        my ($dbh, $article) = @_;

        $id = $article->column('id');

        $article->delete_related($dbh => 'tags' => sub {});
    }
);

ArticleTagMap->find(
    $dbh => {where => [article_id => $id], single => 1} => sub {
        my ($dbh, $tags) = @_;

        ok(not defined $tags);
    }
);

Article->new(id => $id)->load(
    $dbh => sub {
        my ($dbh, $article) = @_;

        ok($article);

        $article->delete($dbh => sub {});
    }
);

Tag->new(name => 'foo')->load(
    $dbh => sub {
        my ($dbh, $tag) = @_;

        ok($tag);

        $tag->delete($dbh => sub {});
    }
);
