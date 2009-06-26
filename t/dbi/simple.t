use strict;
use warnings;

use Test::More tests => 3;

use lib 't/lib';

use File::Spec;

use Async::ORM::DBI;

use Article;

my $db = File::Spec->catfile(File::Spec->tmpdir, 'anyevent-orm.db');

my $dbh = Async::ORM::DBI->new(dbi => "dbi:SQLite:$db");

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
                    }
                );
            }
        );
    }
);
