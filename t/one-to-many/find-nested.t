use strict;
use warnings;

use Test::More tests => 5;

use lib 't/lib';

use TestDB;

use Author;
use Category;

my $dbh = TestDB->dbh;

my $category;

Category->new(title => 'general')->create(
    $dbh => sub {
        my ($dbh, $c) = @_;

        $category = $c;
    }
);

Author->new(
    name     => 'foo',
    articles => [
        {category_id => $category->column('id'), title => 'foo'},
        {title       => 'foo'}
    ]
  )->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        ok($author);

        Author->find(
            $dbh => {where => ['articles.category.title' => 'foo']} => sub {
                my ($dbh, $authors) = @_;

                is_deeply($authors, []);
            }
        );

        Author->find(
            $dbh => {
                where => ['articles.category.title' => 'general'],
                with => ['articles', 'articles.category']
              } => sub {
                my ($dbh, $authors) = @_;

                is(@$authors, 1);

                my $articles = $authors->[0]->related('articles');

                is(@$articles, 1);

                is($articles->[0]->column('title'), 'foo');
            }
        );

        $author->delete($dbh => sub { });
        $category->delete($dbh => sub {});
    }
  );
