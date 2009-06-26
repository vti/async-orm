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

Article->new(title => 'foo', category_id => $categories[0]->column('id'))->create(
    $dbh => sub {
        my ($dbh, $article) = @_;

        push @articles, $article;

    }
);

Article->new(id => $articles[0]->column('id'))->load(
    $dbh => sub {
        my ($dbh, $article) = @_;

        $article->load_related(
            $dbh => 'category' => sub {
                my ($dbh, $category) = @_;
                
                $category = $article->related('category');
                ok($category);
                is($category->column('title'), 'bar');
            }
        );
    }
);

$articles[0]->delete($dbh => sub { });
$categories[0]->delete($dbh => sub { });
