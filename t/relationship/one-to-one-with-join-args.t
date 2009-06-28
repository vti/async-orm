use Test::More tests => 3;

use Async::ORM::Relationship::OneToOne;

use lib 't/lib';

my $rel = Async::ORM::Relationship::OneToOne->new(
    name       => 'article',
    type       => 'one to one',
    orig_class => 'Author',
    class      => 'Article',
    map        => {id => 'author_id'},
    join_args  => [title => 'foo', content => 'bar']
);
ok($rel);

is($rel->related_table, 'article');

is_deeply(
    $rel->to_source,
    {   name       => 'article',
        join       => 'left',
        as         => 'article',
        constraint => [
            'article.author_id' => 'author.id',
            'article.title'   => 'foo',
            'article.content' => 'bar'
        ]
    }
);

