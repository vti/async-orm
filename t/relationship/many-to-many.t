use Test::More tests => 4;

use Async::ORM::Relationship::ManyToMany;

use lib 't/lib';

my $rel = Async::ORM::Relationship::ManyToMany->new(
    orig_class => 'Article',
    type       => 'many to many',
    map_class  => 'ArticleTagMap',
    map_from   => 'article',
    map_to     => 'tag'
);
ok($rel);

is($rel->related_table, 'tag');

is_deeply($rel->to_map_source,
    {
        name       => 'article_tag_map',
        join       => 'left',
        constraint => ['article.id' => 'article_tag_map.article_id']
    }
);

is_deeply($rel->to_source,
    {
        name       => 'tag',
        join       => 'left',
        constraint => ['tag.id' => 'article_tag_map.tag_id']
    }
);

