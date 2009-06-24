package ArticleTagMap;

use Mouse;

extends 'Async::ORM';

__PACKAGE__->schema(
    table        => 'article_tag_map',
    columns      => [qw/ article_id tag_id /],
    primary_keys => [qw/ article_id tag_id /],

    relationships => {
        article => {
            type  => 'many to one',
            class => 'Article',
            map   => {article_id => 'id'}
        },
        tag => {
            type  => 'many to one',
            class => 'Tag',
            map   => {tag_id => 'id'}
        }
    }
);

1;
