use strict;
use warnings;

use Test::More tests => 3;

use lib 't/lib';

use TestDB;

use Author;
use Article;
use Comment;

my $dbh = TestDB->dbh;

my $author_id;
my $article_id;

Author->new(
    name     => 'foo',
    articles => {
        title    => 'foo',
        comments => {content => 'bar'}
    }
  )->create(
    $dbh => sub {
        my ($dbh, $author) = @_;

        $author_id  = $author->column('id');
        $article_id = $author->related('articles')->[0]->column('id');

        $author->delete($dbh => sub { });
    }
  );

Author->new(id => $author_id)->load(
    $dbh => sub {
        my ($dbh, $author) = @_;

        ok(not defined $author);
    }
);

Article->find(
    $dbh => {where => [author_id => $author_id], single => 1} => sub {
        my ($dbh, $article) = @_;

        ok(not defined $article);
    }
);

Comment->find(
    $dbh =>
      {where => [type => 'article', master_id => $article_id], single => 1} =>
      sub {
        my ($dbh, $comment) = @_;

        ok(not defined $comment);
    }
);
