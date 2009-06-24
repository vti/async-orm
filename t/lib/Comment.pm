package Comment;

use Mouse;

extends 'Async::ORM';

__PACKAGE__->schema(
    table        => 'comment',
    columns      => [qw/master_id type content/],
    primary_keys => [qw/master_id type/],

    relationships => {
        master => {
            type      => 'proxy',
            proxy_key => 'type',
        },
        article => {
            type  => 'many to one',
            class => 'Article',
            map   => {master_id => 'id'}
        },
        podcast => {
            type  => 'many to one',
            class => 'Podcast',
            map   => {master_id => 'id'}
        }
    }
);

1;
