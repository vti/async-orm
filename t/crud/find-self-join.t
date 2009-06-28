use strict;
use warnings;

use Test::More tests => 7;

use lib 't/lib';

use TestDB;

use Family;

my $dbh = TestDB->dbh;

my $father;

Family->new(name => 'father')->create(
    $dbh => sub {
        my ($dbh, $f) = @_;

        $father = $f;

        $father->create_related(
            $dbh => ansestors => {name => 'child'} => sub {
                my ($dbh, $children) = @_;
            }
        );
    }
);

Family->find(
    $dbh => {with => ['parent', 'ansestors']} => sub {
        my ($dbh, $people) = @_;

        is(@$people, 2);

        my ($father, $child) = @$people;

        is($father->column('name'), 'father');
        ok(not defined $father->related('parent'));
        is($father->related('ansestors')->[0]->column('name'), 'child');

        is($child->column('name'), 'child');
        is($child->related('parent')->column('name'), 'father');
        ok(not defined $child->related('ansestors'));
    }
);

$father->delete($dbh => sub { });
