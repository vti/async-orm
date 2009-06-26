use strict;
use warnings;

use Test::More tests => 4;

use lib 't/lib';

use TestDB;

use Author;
use Article;

my $dbh = TestDB->dbh;

Author->new(name => 'foo', articles => [{title => 'foo'}, {title => 'bar'}])->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        ok($author);

        my $articles = $author->related('articles');
        is(@$articles, 2);
        is($articles->[0]->column('author_id'), $author->column('id'));
        is($articles->[0]->column('title'), 'foo');

        $author->delete($dbh => sub {});
    }
);
