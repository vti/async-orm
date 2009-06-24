use strict;
use warnings;

use Test::More tests => 4;

use lib 't/lib';

use TestDB;

use Author;

my $dbh = TestDB->dbh;

Author->new(id => 345345)->delete(
    $dbh => sub {
        my ($dbh, $count) = @_;

        is($count, 0);
    }
);

Author->new(name => 'foo', password => 'boo')->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        $author->delete(
            $dbh => sub {
                my ($dbh, $count) = @_;

                is($count, 1);
            }
        );
    }
);

Author->new(name => 'root')->create($dbh => sub {});

Author->delete(
    $dbh => {where => [name => 'root']} => sub {
        my ($dbh, $count) = @_;

        is($count, 1);
    }
);

eval { Author->new->delete($dbh => sub {}); };
ok($@);
