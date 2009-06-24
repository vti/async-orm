use strict;
use warnings;

use Test::More tests => 4;

use lib 't/lib';

use TestDB;

use Article;
use Tag;

my $dbh = TestDB->dbh;

Article->new(name => 'foo', tags => [{name => 'foo'}, {name => 'bar'}])
  ->create(
    $dbh => sub {
        my ($dbh, $article) = @_;

        ok($article);

        my $tags = $article->related('tags');

        is(@$tags, 2);

        is($tags->[0]->column('name'), 'foo');
        is($tags->[1]->column('name'), 'bar');

        $article->delete($dbh => sub { });

        Tag->delete($dbh => {where => [name => [qw/foo bar/]]} => sub { });
    }
  );
