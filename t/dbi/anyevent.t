use strict;
use warnings;

use Test::More tests => 3;

use lib 't/lib';

use File::Spec;

use Async::ORM::DBI;
use AnyEvent;

use Article;

my $db = File::Spec->catfile(File::Spec->tmpdir, 'anyevent-orm.db');

my $dbh = Async::ORM::DBI->new(
    driver => 'Async::ORM::DBI::AnyEvent',
    dbi    => "dbi:SQLite:$db"
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
