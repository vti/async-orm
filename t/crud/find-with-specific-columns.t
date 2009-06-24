use strict;
use warnings;

use Test::More tests => 11;

use lib 't/lib';

use TestDB;

use Author;

my $dbh = TestDB->dbh;

my @authors;

Author->new(name => 'foo', password => 'bar')
  ->create($dbh => sub { push @authors, $_[1] });

Author->find(
    $dbh => {columns => 'name'} => sub {
        my ($dbh, $authors) = @_;

        is(@$authors, 1);
        ok($authors->[0]->column('id'));
        is($authors->[0]->column('name'), 'foo');
        ok(not defined $authors->[0]->column('password'));
    }
);

Author->find(
    $dbh => {columns => [qw/ password name /]} => sub {
        my ($dbh, $authors) = @_;

        is(@$authors, 1);
        ok($authors->[0]->column('id'));
        is($authors->[0]->column('name'),     'foo');
        is($authors->[0]->column('password'), 'bar');
    }
);

Author->find(
    $dbh => {columns => [{name => \'COUNT(*)', as => 'count'}]} => sub {
        my ($dbh, $authors) = @_;

        is(@$authors, 1);
        ok($authors->[0]->column('id'));
        is($authors->[0]->column('count'), 1);
    }
);

$_->delete($dbh => sub {}) for (@authors);
