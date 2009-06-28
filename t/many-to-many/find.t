use strict;
use warnings;

use Test::More tests => 5;

use lib 't/lib';

use TestDB;

use Article;
use Tag;

my $dbh = TestDB->dbh;

my @articles;

Article->new(name => 'foo', tags => [{name => 'bar'}, {name => 'baz'}])
  ->create(
    $dbh => sub {
        my ($dbh, $article) = @_;

        push @articles, $article;
    }
  );

Article->find(
    $dbh => {where => ['tags.name' => 'foo']} => sub {
        my ($dbh, $articles) = @_;

        is_deeply($articles, []);
    }
);

Article->find(
    $dbh => {with => 'tags'} => sub {
        my ($dbh, $articles) = @_;

        is(@$articles, 1);

        my $tags = $articles->[0]->related('tags');
        is(@$tags,                     2);
        is($tags->[0]->column('name'), 'bar');
        is($tags->[1]->column('name'), 'baz');
    }
);

$articles[0]->delete($dbh => sub { });
Tag->delete($dbh => {where => [name => [qw/bar baz/]]} => sub { });
