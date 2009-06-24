use strict;
use warnings;

use Test::More tests => 9;

use lib 't/lib';

use TestDB;

use Article;
use Tag;

my $dbh = TestDB->dbh;

my @articles;

Article->new(title => 'foo', tags => {name => 'foo'})->create(
    $dbh => sub {
        my ($dbh, $article) = @_;

        push @articles, $article;

        $article->related('tags')->[0]->column(name => 'bar');
        $article->update($dbh => sub { ok($_[1]) });
    }
);

Article->new(id => $articles[0]->column('id'))->load(
    $dbh => sub {
        my ($dbh, $article) = @_;

        $article->load_related(
            $dbh => 'tags' => sub {
                my ($dbh, $tags) = @_;

                is(@$tags, 1);
                is($tags->[0]->column('name'), 'bar');

                $article->column(title => 'bar');
                $tags->[0]->column(name => 'foo');
                $article->update($dbh => sub { });
            }
        );
    }
);

Article->new(id => $articles[0]->column('id'))->load(
    $dbh => sub {
        my ($dbh, $article) = @_;

        is($article->column('title'), 'bar');

        $article->find_related(
            $dbh => 'tags' => sub {
                my ($dbh, $tags) = @_;

                is(@$tags, 1);
                is($tags->[0]->column('name'), 'foo');
            }
        );
    }
);

$articles[0]->delete($dbh => sub { });
Tag->delete($dbh => {where => [name => [qw/foo/]]} => sub { });
