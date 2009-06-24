use strict;
use warnings;

use Test::More tests => 9;

use lib 't/lib';

use TestDB;

use Article;

my $dbh = TestDB->dbh;

my @articles;

foreach my $i (1 .. 11) {
    Article->new(title => $i)->create($dbh => sub {push @articles, $_[1]});
}

my @data = (
    {page => 0,    page_size => 10, total => 10},
    {page => 1,    page_size => 10, total => 10},
    {page => 1,    total     => 10},
    {page => 3,    page_size => 10, total => 0},
    {page => 'a',  page_size => 10, total => 10},
    {page => '9a', page_size => 10, total => 10},
    {page => 2,    page_size => 10, total => 1},
    {page => 2,    page_size => 5,  total => 5}
);

foreach my $data (@data) {
    Article->find(
        $dbh => {
            page      => $data->{page},
            page_size => $data->{page_size}
          } => sub {
            my ($dbh, $articles) = @_;

            is(@$articles, $data->{total});
        }
    );
}

Article->find(
    $dbh => {page => 2, page_size => 5, single => 1} => sub {
        my ($dbh, $article) = @_;

        is($article->column('title'), 1);
    }
);

$_->delete($dbh => sub {}) for @articles;
