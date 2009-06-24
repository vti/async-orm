package Article;

use Mouse;

extends 'Async::ORM';

__PACKAGE__->schema(
    table          => 'article',
    columns        => [qw/ id category_id author_id title /],
    primary_keys   => ['id'],
    auto_increment => 'id',

    relationships => {
        author => {
            type  => 'many to one',
            class => 'Author',
            map   => {author_id => 'id'}
        },
        category => {
            type  => 'many to one',
            class => 'Category',
            map   => {category_id => 'id'}
        },
        tags => {
            type      => 'many to many',
            map_class => 'ArticleTagMap',
            map_from  => 'article',
            map_to    => 'tag'
        },
        comments => {
            type  => 'one to many',
            class => 'Comment',
            where => [type => 'article'],
            map   => {id => 'master_id'}
        }
    }
);

1;
