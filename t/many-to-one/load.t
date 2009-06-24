use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use TestDB;

use Article;
use Category;

my $dbh = TestDB->dbh;

my @categories;
my @articles;

Category->new(title => 'foo')->create(
    $dbh => sub {
        my ($dbh, $category) = @_;

        push @categories, $category;

        Article->new(title => 'bar', category_id => $category->column('id'))->create(
            $dbh => sub {
                my ($dbh, $article) = @_;

                push @articles, $article;
            }
        );
    }
);

Article->new(id => $articles[0]->column('id'))->load(
    $dbh => {with => 'category'} => sub {
        my ($dbh, $article) = @_;

        my $category = $article->related('category');
        ok($category);
        is($category->column('title'), 'foo');
    }
);

$articles[0]->delete($dbh => sub {});
$categories[0]->delete($dbh => sub {});
