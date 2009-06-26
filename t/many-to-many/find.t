use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use TestDB;

use Article;
use Tag;

my $dbh = TestDB->dbh;

my @articles;

Article->new(name => 'foo', tags => {name => 'bar'})->create(
    $dbh => sub {
        my ($dbh, $article) = @_;

        push @articles, $article;
    }
);

Article->find(
    $dbh => {where => ['tags.name' => 'foo']} => sub {
        my ($dbh, $articles) = @_;

        is_deeply($articles, []);
    }
);

Article->find(
    $dbh => {where => ['tags.name' => 'bar']} => sub {
        my ($dbh, $articles) = @_;

        is(@$articles, 1);
    }
);

$articles[0]->delete($dbh => sub { });
Tag->delete($dbh => {where => [name => [qw/foo/]]} => sub { });
