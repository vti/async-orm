package Default;

use Mouse;

extends 'Async::ORM';

__PACKAGE__->schema(
    table   => 'default',
    columns => [
        'id',
        title   => {default => 'abc'}
    ],
    primary_keys => 'id'
);

package main;

use strict;
use warnings;

use Test::More tests => 2;

my $d = Default->new;
is($d->column('title'), 'abc');

$d = Default->new(title => 'foo');
is($d->column('title'), 'foo');
