#!/usr/bin/perl

use strict;
use warnings;

use lib '/home/vti/dev/mojo/lib';

BEGIN {
    use Test::More;

    plan skip_all => 'set TEST_AUTHOR to enable this test (developer only!)'
      unless $ENV{TEST_AUTHOR};
}

use Async::ORM::DBI::DBSlayer;
use Mojo::Client;
use Mojo::JSON;

use lib 't/lib';

use Article;

plan tests => 5;

my $client = Mojo::Client->new;
my $json   = Mojo::JSON->new;

my $dbh = Async::ORM::DBI::DBSlayer->new(
    database    => 'async_orm',
    json_encode => sub { $json->encode(@_) },
    json_decode => sub { $json->decode(@_) },
    http_req_cb => sub {
        my ($url, $method, $headers, $body, $cb) = @_;

        $url = Mojo::URL->new($url);
        $url->query($body);

        $client->get(
            $url->to_string => sub {
                my ($self, $tx) = @_;

                $cb->(
                    $url, $tx->res->code, $tx->res->headers->to_hash,
                    $tx->res->body
                );
            }
        )->process;
    }
);

my $article;

Article->new(title => 'foo')->create(
    $dbh => sub {
        my ($dbh, $article_) = @_;

        ok($article_);
        ok($article_->columns('id'));

        $article = $article_;
    }
);

Article->find(
    $dbh => {where => [title => 'foo']} => sub {
        my ($dbh, $articles) = @_;

        is(@$articles, 1);
    }
);

$article->delete(
    $dbh => sub {
        my ($dbh, $ok) = @_;

        ok($ok);

    }
);

Article->find(
    $dbh => {where => [title => 'foo']} => sub {
        my ($dbh, $articles) = @_;

        is(@$articles, 0);
    }
);
