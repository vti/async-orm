package Async::ORM::Relationship::Proxy;

use Any::Moose;

extends 'Async::ORM::Relationship';

has proxy_key => (
    is => 'rw'
);

1;
