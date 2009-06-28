use Test::More tests => 3;

use Async::ORM::Relationship::OneToOne;

use lib 't/lib';

my $rel = Async::ORM::Relationship::OneToOne->new(
    name       => 'article',
    type       => 'one to one',
    orig_class => 'Author',
    class      => 'Article',
    map        => {id => 'author_id'}
);
ok($rel);

is($rel->related_table, 'article');

is_deeply(
    $rel->to_source,
    {   name       => 'article',
        as         => 'article',
        join       => 'left',
        constraint => ['article.author_id' => 'author.id']
    }
);

