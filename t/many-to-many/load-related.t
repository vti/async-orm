use strict;
use warnings;

use Test::More tests => 4;

use lib 't/lib';

use TestDB;

use Article;
use ArticleTagMap;
use Tag;

my $dbh = TestDB->dbh;

my @articles;

Article->new(name => 'foo', tags => {name => 0})->create(
    $dbh => sub {
        my ($dbh, $article) = @_;

        push @articles, $article;
    }
);

Article->new(id => $articles[0]->column('id'))->load(
    $dbh => sub {
        my ($dbh, $article) = @_;

        $article->load_related(
            $dbh => 'tags' => sub {
                my ($dbh, $tags) = @_;

                is(@$tags, 1);
                is($tags->[0]->column('name'), 0);

                $tags = $article->related('tags');

                is(@$tags, 1);
                is($tags->[0]->column('name'), 0);
            }
        );
    }
);

$articles[0]->delete($dbh => sub { });
Tag->delete($dbh => {where => [name => [qw/foo/]]} => sub { });
