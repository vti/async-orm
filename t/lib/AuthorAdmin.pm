package AuthorAdmin;

use Mouse;

extends 'Async::ORM';

__PACKAGE__->schema(
    table        => 'author_admin',
    columns      => [qw/author_id beard/],
    primary_keys => ['author_id'],
);

1;
