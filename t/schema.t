package Model::Simple;

use base 'Async::ORM';

__PACKAGE__->schema(
    table => 'simple',
    columns => 'foo',
    primary_keys => 'foo'
);

package Model::Base;

use base 'Async::ORM';

__PACKAGE__->schema(
    table => 'base',
    columns => [qw/ foo bar baz /],
    primary_keys => [qw/ foo /]
);

package Model;
use base 'Model::Base';

__PACKAGE__->schema->add_column('gaz');
__PACKAGE__->schema->del_column('bar');

package Model::Options;
use base 'Async::ORM';

__PACKAGE__->schema(
    table => 'options',
    columns => 'foo',
    primary_keys => 'foo',
    auto_increment => 'foo',
    unique_keys => 'foo'
);

package Artist;
use base 'Async::ORM';

__PACKAGE__->schema(
    table => 'artist',
    columns => 'id',
    primary_keys => 'id',

    relationships => {
        albums => {
            type => 'many to one',
            class => 'Album',
            map => {id => 'artist_id'}
        }
    }
);

package Album;
use base 'Async::ORM';

__PACKAGE__->schema(
    table => 'album',
    columns => ['id', 'artist_id'],
    primary_keys => 'id',

    relationships => {
        artist => {
            type => 'many to one',
            class => 'Artist',
            map => {artist_id => 'id'}
        }
    }
);

package Advanced;
use base 'Album';

__PACKAGE__->schema->add_columns(qw/year month/, 'time' => {default => 'now'});
__PACKAGE__->schema->add_relationships(
    foo => {type => 'one to one'},
    bar => {type => 'one to many'}
);

package ColumnsWithOptions;
use base 'Async::ORM';

__PACKAGE__->schema(
    table        => 'table',
    columns      => ['id', title => {length => 1}],
    primary_keys => 'id'
);

package main;

use Test::More tests => 32;

use lib 't/lib';

is(Model::Simple->schema->table, 'simple');
is_deeply([Model::Simple->schema->columns], [qw/ foo /]);
is_deeply([Model::Simple->schema->primary_keys], [qw/ foo /]);
is(Model::Simple->schema->is_primary_key('foo'), 1);

is_deeply([sort Model::Base->schema->columns], [sort qw/ foo bar baz /]);
is_deeply([Model::Base->schema->primary_keys], [qw/ foo /]);

ok(Model::Base->schema->is_column('foo'));
ok(!Model::Base->schema->is_column('fooo'));

is_deeply([sort Model->schema->columns], [sort qw/ foo baz gaz /]);
is_deeply([Model->schema->primary_keys], [qw/ foo /]);

ok(Model->schema->is_column('foo'));
ok(!Model->schema->is_column('fooo'));

ok(Model->schema->is_column('gaz'));
ok(!Model->schema->is_column('bar'));

ok(Model::Options->schema->is_column('foo'));
is_deeply([Model::Options->schema->primary_keys], [qw/ foo /]);
is_deeply(Model::Options->schema->auto_increment, 'foo');
is_deeply([sort Model::Options->schema->columns], [sort qw/ foo /]);
is_deeply([Model::Options->schema->unique_keys], [qw/ foo /]);
is(Model::Options->schema->is_unique_key('foo'), 1);
is(Model::Options->schema->is_auto_increment('foo'), 1);

my $relationships = Artist->schema->relationships;
is(keys %$relationships, 1);
is($relationships->{albums}->class, 'Album');
is($relationships->{albums}->name, 'albums');

$relationships = Advanced->schema->relationships;
is(Advanced->schema->is_column('year'), 1);
is(Advanced->schema->is_column('month'), 1);
is(Advanced->schema->is_column('time'), 1);
is(keys %$relationships, 3);
is($relationships->{foo}->orig_class, 'Advanced');
is_deeply($relationships->{foo}->type, 'one to one');

is_deeply([ColumnsWithOptions->schema->columns], [qw/ id title /]);
is_deeply(ColumnsWithOptions->schema->columns_map,
    {id => {}, title => {length => 1}});

1;
