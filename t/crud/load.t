use strict;
use warnings;

use Test::More tests => 5;

use lib 't/lib';

use TestDB;

use Author;

my $dbh = TestDB->dbh;

eval {
    Author->new->load($dbh => sub { });
};
ok($@);

my $author;

Author->new(name => 'foo', password => 'boo')->create(
    $dbh => sub {
        $author = $_[1];
    }
);

Author->new(id => $author->column('id'))->load(
    $dbh => sub {
        my ($dbh, $a) = @_;

        is($a->column('id'),       $author->column('id'));
        is($a->column('name'),     'foo');
        is($a->column('password'), 'boo');

        $a->delete($dbh => sub { });
    }
);

Author->new(id => 999)->load(
    $dbh => sub {
        my ($dbh, $author) = @_;

        ok(not defined $author);
    }
);
