use strict;
use warnings;

use Test::More tests => 1;

use lib 't/lib';

use Article;
use Tag;

use TestDB;

my $dbh = TestDB->dbh;

ok(1);

#my @articles;

#Article->new(name => 'foo', tags => {name => 'foo'})->create(
    #$dbh => sub {
        #my ($dbh, $article) = @_;

        #push @articles, $article;

        #$article->update_related(
            #$dbh => 'tags' => {set => {name => 'bar'}} =>
              #sub { ok($_[1]) });
    #}
#);

#Article->new(id => $articles[0]->column('id'))->load(
    #$dbh => sub {
        #my ($dbh, $article) = @_;

        #$article->find_related(
            #$dbh => 'tags' => sub {
                #my ($dbh, $tags) = @_;

                #ok($tags);
                #is($tags->column('name'), 'bar');
            #}
        #);
    #}
#);

#$articles[0]->delete($dbh => sub { });
#Tag->delete($dbh => {where => [name => [qw/bar/]]} => sub { });
