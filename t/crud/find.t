use strict;
use warnings;

use Test::More tests => 8;

use lib 't/lib';

use TestDB;

use Author;

my $dbh = TestDB->dbh;

my @authors;

Author->new(name => 'foo', password => 'bar')
  ->create($dbh => sub { push @authors, $_[1] });

Author->find(
    $dbh => sub {
        my ($dbh, $authors) = @_;

        is(@$authors,                     1);
        is($authors->[0]->column('name'), 'foo');
    }
);

Author->new(name => 'root', password => 'boo')
  ->create($dbh => sub { push @authors, $_[1]; });
Author->new(name => 'boot', password => 'booo')
  ->create($dbh => sub { push @authors, $_[1]; });

Author->find(
    $dbh => {where => [name => 'root'], single => 1} => sub {
        my ($dbh, $author) = @_;

        is($author->column('name'), 'root');
    }
);

Author->find(
    $dbh => {where => [name => 'root']} => sub {
        my ($dbh, $authors) = @_;

        is(@$authors,                    1);
        is($authors->[0]->column('name'), 'root');
    }
);

Author->find(
    $dbh => {where => [password => 'boo']} => sub {
        my ($dbh, $authors) = @_;

        is(@$authors,                    1);
        is($authors->[0]->column('name'), 'root');
    }
);

Author->find(
    $dbh => {where => [password => 'boooo']} => sub {
        my ($dbh, $authors) = @_;

        is(@$authors, 0);
    }
);

$_->delete($dbh => sub {}) for (@authors);
