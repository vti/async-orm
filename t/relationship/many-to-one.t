use Test::More tests => 3;

use Async::ORM::Relationship::ManyToOne;

use lib 't/lib';

my $rel = Async::ORM::Relationship::ManyToOne->new(
    type       => 'many to one',
    class      => 'Author',
    orig_class => 'Article',
    map        => {author_id => 'id'}
);
ok($rel);

is($rel->related_table, 'author');

is_deeply(
    $rel->to_source,
    {   name       => 'author',
        join       => 'left',
        constraint => ['author.id' => 'article.author_id']
    }
);

