use strict;
use warnings;

use Test::More tests => 5;

use lib 't/lib';

use TestDB;

use Author;

my $dbh = TestDB->dbh;

my @authors;

Author->new(name => 'foo', password => 'bar')
  ->create($dbh, sub { push @authors, $_[1] });
Author->count(
    $dbh => sub {
        my ($dbh, $count) = @_;

        is($count, 1);
    }
);

Author->new(name => 'oof', password => 'bar')
  ->create($dbh, sub { push @authors, $_[1] });
Author->count(
    $dbh => sub {
        my ($dbh, $count) = @_;

        is($count, 2);
    }
);

Author->count(
    $dbh => {where => [name => 'vti']} => sub {
        my ($dbh, $count) = @_;

        is($count, 0);
    }
);
Author->count(
    $dbh => {where => [name => 'foo']} => sub {
        my ($dbh, $count) = @_;

        is($count, 1);
    }
);
Author->count(
    $dbh => {where => [password => 'bar']} => sub {
        my ($dbh, $count) = @_;

        is($count, 2);
    }
);

$_->delete($dbh => sub {}) for @authors;
