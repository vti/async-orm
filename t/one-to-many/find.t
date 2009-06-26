use strict;
use warnings;

use Test::More tests => 5;

use lib 't/lib';

use TestDB;

use Author;

my $dbh = TestDB->dbh;

Author->new(name => 'foo', articles => {title => 'foo'})->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        ok($author);

        Author->find(
            $dbh => {where => ['articles.title' => 'bar']} => sub {
                my ($dbh, $authors) = @_;

                is_deeply($authors, []);
            }
        );

        Author->find(
            $dbh => {where => ['articles.title' => 'foo']} => sub {
                my ($dbh, $authors) = @_;

                is(@$authors, 1);

                $authors->[0]->find_related(
                    $dbh => 'articles' => sub {
                        my ($dbh, $articles) = @_;

                        is(@$articles, 1);

                        is($articles->[0]->column('title'), 'foo');
                    }
                );
            }
        );

        $author->delete($dbh => sub { });
    }
);
