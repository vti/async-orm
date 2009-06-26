use strict;
use warnings;

use Test::More tests => 4;

use lib 't/lib';

use TestDB;

use Author;
use Article;

my $dbh = TestDB->dbh;

Author->new(
    name     => 'foo',
    articles => [
        {   title => 'foo',
            tags  => {name => 'people'}
        },
        {   title => 'bar',
            tags  => [{name => 'unix'}, {name => 'perl'}]
        }
    ]
  )->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        ok($author);

        $author->related('articles')->[0]->create_related(
            $dbh => 'comments' => {content => 'foo'} => sub {
                my ($dbh, $comment) = @_;

                ok($comment);

                Article->find(
                    $dbh => {where => ['tags.name' => 'unix']} => sub {
                        my ($dbh, $articles) = @_;

                        is(@$articles, 1);

                        $author->delete(
                            $dbh => sub {
                                my ($dbh, $ok) = @_;

                                ok($ok);
                            }
                        );
                    }
                );
            }
        );
    }
  );
