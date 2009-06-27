use strict;
use warnings;

use Test::More tests => 3;

use lib 't/lib';

use File::Spec;

use TestDB;

use Async::ORM::DBI;
use AnyEvent;

use Article;

my $dbh = Async::ORM::DBI->new(
    driver => 'Async::ORM::DBI::AnyEvent',
    dbi    => "dbi:SQLite:" . TestDB->database
);

my $cv = AnyEvent->condvar;

Article->new(title => 'foo')->create(
    $dbh => sub {
        my ($dbh, $article) = @_;

        ok($article);

        $article->delete(
            $dbh => sub {
                my ($dbh, $ok) = @_;

                ok($ok);

                Article->find(
                    $dbh => {where => [title => 'foo']} => sub {
                        my ($dbh, $articles) = @_;

                        is(@$articles, 0);

                        $cv->send;
                    }
                );
            }
        );
    }
);

$cv->recv;
