use Test::More tests => 3;

use Async::ORM::Relationship::OneToMany;

use lib 't/lib';

my $rel = Async::ORM::Relationship::OneToMany->new(
    type       => 'one to many',
    orig_class => 'Author',
    class      => 'Article',
    map        => {id => 'author_id'}
);
ok($rel);

is($rel->related_table, 'article');

is_deeply(
    $rel->to_source,
    {   name       => 'article',
        join       => 'left',
        constraint => ['article.author_id' => 'author.id']
    }
);

