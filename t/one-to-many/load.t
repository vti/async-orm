use strict;
use warnings;

use Test::More tests => 3;

use lib 't/lib';

use TestDB;

use Author;
use Article;

my $dbh = TestDB->dbh;

my @authors;

Author->new(name => 'foo', articles => [{title => 'bar'}, {title => 'baz'}])
  ->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        push @authors, $author;

    }
  );

Author->new(id => $authors[0]->column('id'))->load(
    $dbh => {with => 'articles'} => sub {
        my ($dbh, $author) = @_;

        my $articles = $author->related('articles');
        is(@$articles, 2);

        is($articles->[0]->column('title'), 'bar');
        is($articles->[1]->column('title'), 'baz');
    }
);

$authors[0]->delete($dbh => sub {});
