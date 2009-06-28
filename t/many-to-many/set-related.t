use strict;
use warnings;

use Test::More tests => 8;

use lib 't/lib';

use TestDB;

use Article;
use Tag;

my $dbh = TestDB->dbh;

my @articles;

Article->new(name => 'foo')->create(
    $dbh => sub {
        my ($dbh, $article) = @_;

        push @articles, $article;

        $article->set_related(
            $dbh => 'tags' => {name => 'foo'} => sub {
                my ($dbh, $tags) = @_;

                is(@$tags, 1);
                is($tags->[0]->column('name'), 'foo');
            }
        );
    }
);

Article->new(id => $articles[0]->column('id'))->load(
    $dbh => {with => 'tags'} => sub {
        my ($dbh, $article) = @_;

        my $tags = $article->related('tags');
        is(@$tags, 1);
        is($tags->[0]->column('name'), 'foo');
    }
);

$articles[0]->set_related(
    $dbh => 'tags' => {name => 'bar'} => sub {
        my ($dbh, $tags) = @_;

        is(@$tags, 1);
        is($tags->[0]->column('name'), 'bar');
    }
);

Article->new(id => $articles[0]->column('id'))->load(
    $dbh => {with => 'tags'} => sub {
        my ($dbh, $article) = @_;

        my $tags = $article->related('tags');
        is(@$tags, 1);
        is($tags->[0]->column('name'), 'bar');
    }
);

$articles[0]->delete($dbh => sub { });
Tag->delete($dbh => {where => [name => [qw/foo bar/]]} => sub {});
