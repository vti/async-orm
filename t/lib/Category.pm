package Category;

use Mouse;

extends 'Async::ORM';

__PACKAGE__->schema(
    table          => 'category',
    columns        => [qw/id title/],
    primary_keys   => ['id'],
    auto_increment => 'id',

    relationships => {
        articles => {
            type  => 'one to many',
            class => 'Article',
            map   => {id => 'category_id'}
        }
    }
);

1;
