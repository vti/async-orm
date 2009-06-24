use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use TestDB;

use Article;
use Tag;

my $dbh = TestDB->dbh;

my @articles;

Article->new(name => 'foo')->create(
    $dbh => sub {
        my ($dbh, $article) = @_;

        push @articles, $article;

        $article->create_related(
            $dbh => 'tags' => {name => 'foo'} => sub {
                my ($dbh, $tag) = @_;

                ok($tag);
                is($tag->column('name'), 'foo');
            }
        );
    }
);

$articles[0]->delete($dbh => sub { });
Tag->delete($dbh => {where => [name => [qw/foo/]]} => sub { });
