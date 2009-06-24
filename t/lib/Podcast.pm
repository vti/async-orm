package Podcast;

use Mouse;

extends 'Async::ORM';

__PACKAGE__->schema(
    table          => 'podcast',
    columns        => [qw/ id author_id title /],
    primary_keys   => ['id'],
    auto_increment => 'id',

    relationships => {
        author => {
            type  => 'many to one',
            class => 'Author',
            map   => {author_id => 'id'}
        },
        comments => {
            type  => 'one to many',
            class => 'Comment',
            where => [type => 'podcast'],
            map   => {id => 'master_id'}
        }
    }
);

1;
