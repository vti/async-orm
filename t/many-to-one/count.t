use strict;
use warnings;

use Test::More tests => 2;

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

Article->count(
    $dbh => {where => ['category.title' => 'foo']} => sub {
        my ($dbh, $count) = @_;

        is($count, 0);
    }
);

Article->count(
    $dbh => {where => ['category.title' => 'bar'], with => 'category'} => sub {
        my ($dbh, $count) = @_;

        is($count, 1);
    }
);

$articles[0]->delete($dbh => sub { });
$categories[0]->delete($dbh => sub { });
