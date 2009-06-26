use strict;
use warnings;

use Test::More tests => 3;

use lib 't/lib';

use TestDB;

use Article;
use Category;

my $dbh = TestDB->dbh;

my @articles;
my @categories;

Category->new(title => 'bar')->create(
    $dbh => sub {
        my ($dbh, $category) = @_;

        push @categories, $category;

    }
);

Article->new(title => 'foo', category_id => $categories[0]->column('id'))
  ->create(
    $dbh => sub {
        my ($dbh, $article) = @_;

        push @articles, $article;

    }
  );

Article->find(
    $dbh => {where => ['category.title' => 'foo']} => sub {
        my ($dbh, $articles) = @_;

        is_deeply($articles, []);
    }
);

Article->find(
    $dbh => {where => ['category.title' => 'bar'], with => 'category'} => sub {
        my ($dbh, $articles) = @_;

        is(@$articles, 1);
        is($articles->[0]->related('category')->column('title'), 'bar');
    }
);

$articles[0]->delete($dbh => sub { });
$categories[0]->delete($dbh => sub { });
