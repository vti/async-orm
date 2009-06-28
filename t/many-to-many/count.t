use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use TestDB;

use Article;
use Tag;

my $dbh = TestDB->dbh;

my @articles;

Article->new(name => 'foo', tags => [{name => 'bar'}, {name => 'baz'}])
  ->create(
    $dbh => sub {
        my ($dbh, $article) = @_;

        push @articles, $article;
    }
  );

Article->count(
    $dbh => {where => ['tags.name' => 'foo']} => sub {
        my ($dbh, $count) = @_;

        is($count, 0);
    }
);

Article->count(
    $dbh => {with => 'tags'} => sub {
        my ($dbh, $count) = @_;

        is($count, 1);
    }
);

$articles[0]->delete($dbh => sub { });
Tag->delete($dbh => {where => [name => [qw/bar baz/]]} => sub { });
