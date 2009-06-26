use strict;
use warnings;

use Test::More tests => 4;

use lib 't/lib';

use TestDB;

use Author;

my $dbh = TestDB->dbh;

Author->new(name => 'foo', author_admin => {beard => 0})->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        ok($author);

        Author->find(
            $dbh => {where => ['author_admin.beard' => 1]} => sub {
                my ($dbh, $authors) = @_;

                is_deeply($authors, []);
            }
        );

        Author->find(
            $dbh => {where => ['author_admin.beard' => 0],
                with => 'author_admin'} => sub {
                my ($dbh, $authors) = @_;

                is(@$authors, 1);
                is($authors->[0]->related('author_admin')->column('beard'),
                    0);
            }
        );

        $author->delete($dbh => sub { });
    }
);
