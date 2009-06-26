use strict;
use warnings;

use Test::More tests => 9;

use lib 't/lib';

use TestDB;

use Category;
use Article;

my $dbh = TestDB->dbh;

my @articles;
my @categories;

Category->new(title => 'bar')->create(
    $dbh => sub {
        my ($dbh, $category) = @_;

        push @categories, $category;

    }
);

Article->new(title => 'foo', category_id => $categories[0]->column('id'))->create(
    $dbh => sub {
        my ($dbh, $article) = @_;

        push @articles, $article;

        $article->load_related(
            $dbh => category => sub {
                my ($dbh, $category) = @_;
                $article->related('category')->column(title => 'foo');
                $article->update($dbh => sub { ok($_[1]) });
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

        $article->column(title => 'bar');
        $category->column(title => 'bar');
        $article->update($dbh => sub {});
    }
);

Article->new(id => $articles[0]->column('id'))->load(
    $dbh => {with => 'category'} => sub {
        my ($dbh, $article) = @_;

        is($article->column('title'), 'bar');

        my $category = $article->related('category');
        ok($category);
        is($category->column('title'), 'bar');
    }
);

$articles[0]->delete($dbh => sub { });
$categories[0]->delete($dbh => sub { });
