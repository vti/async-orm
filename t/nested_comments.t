use Test::More tests => 36;

use lib 't/lib';

use TestDB;

use Article;
use NestedComment;

my $dbh = TestDB->dbh;

my $master;
my ($c1, $c2, $c3, $c4, $c5, $c6, $c7, $c8, $c9);

Article->new(category_id => 1, user_id => 1, title => 'bar')
  ->create($dbh => sub { my ($dbh, $article) = @_; $master = $article });

NestedComment->new(
    master_id   => $master->column('id'),
    master_type => 'article',
    content     => 1
  )->create(
    $dbh => sub {
        my ($dbh, $comment) = @_;

        $c1 = $comment;

        is($c1->column('lft'),   2);
        is($c1->column('rgt'),   3);
        is($c1->column('level'), 0);
    }
  );

NestedComment->new(
    master_id   => $master->column('id'),
    master_type => 'article',
    content     => 2
  )->create(
    $dbh => sub {
        my ($dbh, $comment) = @_;

        $c2 = $comment;

        is($c2->column('lft'),   4);
        is($c2->column('rgt'),   5);
        is($c2->column('level'), 0);

    }
  );

NestedComment->new(
    master_id   => $master->column('id'),
    master_type => 'article',
    content     => 3
  )->create(
    $dbh => sub {
        my ($dbh, $comment) = @_;

        $c3 = $comment;

        is($c3->column('lft'),   6);
        is($c3->column('rgt'),   7);
        is($c3->column('level'), 0);
    }
  );

$c1->create_related(
    $dbh => 'ansestors' => {content => 4} => sub {
        my ($dbh, $comment) = @_;

        $c4 = $comment;

        is($c4->column('lft'),   3);
        is($c4->column('rgt'),   4);
        is($c4->column('level'), 1);
    }
);

$c2->create_related(
    $dbh => 'ansestors' => {content => 5} => sub {
        my ($dbh, $comment) = @_;

        $c5 = $comment;

        is($c5->column('lft'),   7);
        is($c5->column('rgt'),   8);
        is($c5->column('level'), 1);
    }
);

$c3->create_related(
    $dbh => 'ansestors' => {content => 6} => sub {
        my ($dbh, $comment) = @_;

        $c6 = $comment;

        is($c6->column('lft'),   11);
        is($c6->column('rgt'),   12);
        is($c6->column('level'), 1);
    }
);

$c5->create_related(
    $dbh => 'ansestors' => {content => 7} => sub {
        my ($dbh, $comment) = @_;

        $c7 = $comment;

        is($c7->column('lft'),   8);
        is($c7->column('rgt'),   9);
        is($c7->column('level'), 2);
    }
);

$c6->create_related(
    $dbh => 'ansestors' => {content => 8} => sub {
        my ($dbh, $comment) = @_;

        $c8 = $comment;

        is($c8->column('lft'),   14);
        is($c8->column('rgt'),   15);
        is($c8->column('level'), 2);
    }
);

$c6->create_related(
    $dbh => 'ansestors' => {content => 9} => sub {
        my ($dbh, $comment) = @_;

        $c9 = $comment;

        is($c9->column('lft'),   16);
        is($c9->column('rgt'),   17);
        is($c9->column('level'), 2);
    }
);

NestedComment->find(
    $dbh => {
        where => [
            master_type => 'article',
            master_id   => $master->column('id')
        ],
        order_by => 'lft ASC'
      } => sub {
        my ($dbh, $comments) = @_;

        foreach my $content (qw/1 4 2 5 7 3 6 8 9/) {
            my $comment = shift @$comments;
            is($comment->column('content'), $content);
        }
    }
);
