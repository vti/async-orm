use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use TestDB;

use Author;

my $dbh = TestDB->dbh;

Author->new(name => 'foo', author_admin => {beard => 0})->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        Author->count(
            $dbh => {where => ['author_admin.beard' => 1]} => sub {
                my ($dbh, $authors) = @_;

                is($authors, 0);
            }
        );

        Author->count(
            $dbh => {
                where => ['author_admin.beard' => 0],
                with  => 'author_admin'
              } => sub {
                my ($dbh, $authors) = @_;

                is($authors, 1);
            }
        );

        $author->delete($dbh => sub { });
    }
);
