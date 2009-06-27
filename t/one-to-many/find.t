use strict;
use warnings;

use Test::More tests => 5;

use lib 't/lib';

use TestDB;

use Author;

my $dbh = TestDB->dbh;

Author->new(name => 'foo', articles => [{title => 'foo'}, {title => 'foo'}])->create(
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
            $dbh => {where => ['articles.title' => 'foo'], with => 'articles'} => sub {
                my ($dbh, $authors) = @_;

                is(@$authors, 1);

                my $articles = $authors->[0]->related('articles');

                is(@$articles, 2);

                is($articles->[0]->column('title'), 'foo');
            }
        );

        $author->delete($dbh => sub { });
    }
);
