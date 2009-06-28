use strict;
use warnings;

use Test::More tests => 3;

use lib 't/lib';

use TestDB;

use Article;
use Category;
use Comment;

my $dbh = TestDB->dbh;

my @categories;

Category->new(
    title    => 'bar',
    articles => {
        title    => 'foo',
        comments => {content => 'baz'}
    }
  )->create(
    $dbh => sub {
        my ($dbh, $category) = @_;

        push @categories, $category;

    }
  );

Comment->find(
    $dbh => {where => ['article.category.title' => 'foo']} => sub {
        my ($dbh, $comments) = @_;

        is_deeply($comments, []);
    }
);

Comment->find(
    $dbh => {
        where => ['article.category.title' => 'bar'],
        with => ['article', 'article.category']
      } => sub {
        my ($dbh, $comments) = @_;

        is(@$comments, 1);
        is( $comments->[0]->related('article')->related('category')
              ->column('title'),
            'bar'
        );
    }
);

$categories[0]->delete($dbh => sub { });
