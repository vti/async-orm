use strict;
use warnings;

use Test::More tests => 3;

use lib 't/lib';

use TestDB;

use Author;
use Article;

my $dbh = TestDB->dbh;

my @authors;

Author->new(name => 'foo', articles => {title => 'foo'})->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        push @authors, $author;

        $author->update_related(
            $dbh => 'articles' => {set => {title => 'bar'}} =>
              sub { ok($_[1]) });
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
