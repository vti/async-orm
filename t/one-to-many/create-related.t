use strict;
use warnings;

use Test::More tests => 4;

use lib 't/lib';

use TestDB;

use Author;
use Article;

my $dbh = TestDB->dbh;

my @authors;

Author->new(name => 'foo')->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        push @authors, $author;

        $author->create_related(
            $dbh => 'articles' => {title => 'bar'} => sub {
                my ($dbh, $articles) = @_;

                ok($articles);
                is($articles->column('title'), 'bar');
            }
        );
    }
);

Author->new(id => $authors[0]->column('id'))->load(
    $dbh => sub {
        my ($dbh, $author) = @_;

        $author->find_related(
            $dbh => 'articles' => sub {
                my ($dbh, $articles) = @_;

                is(@$articles, 1);
                is($articles->[0]->column('title'), 'bar');
            }
        );
    }
);

$authors[0]->delete($dbh => sub { });
