use strict;
use warnings;

use Test::More tests => 1;

use lib 't/lib';

use TestDB;

use Article;
use ArticleTagMap;
use Tag;

my $dbh = TestDB->dbh;

my @articles;

Article->new(name => 'foo', tags => {name => 'foo'})->create(
    $dbh => sub {
        my ($dbh, $article) = @_;

        push @articles, $article;
    }
);

Article->new(id => $articles[0]->column('id'))->load(
    $dbh => sub {
        my ($dbh, $article) = @_;

        $article->count_related(
            $dbh => 'tags' => sub {
                my ($dbh, $count) = @_;

                is($count, 1);
            }
        );
    }
);

$articles[0]->delete($dbh => sub { });
Tag->delete($dbh => {where => [name => [qw/foo/]]} => sub { });
