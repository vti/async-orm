use strict;
use warnings;

use Test::More tests => 3;

use lib 't/lib';

use TestDB;

use Author;

my $dbh = TestDB->dbh;

Author->new(name => 'foo', articles => [{title => 'foo'}, {title => 'foo'}])->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        ok($author);

        Author->count(
            $dbh => {where => ['articles.title' => 'bar']} => sub {
                my ($dbh, $count) = @_;

                is($count, 0);
            }
        );

        Author->count(
            $dbh => {where => ['articles.title' => 'foo']} => sub {
                my ($dbh, $count) = @_;

                is($count, 1);
            }
        );

        $author->delete($dbh => sub { });
    }
);
