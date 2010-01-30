#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

use Async::ORM::DBI::DBSlayer;

# Placeholders handling
is(Async::ORM::DBI::DBSlayer->build_sql(q/foo/), q/foo/);
is(Async::ORM::DBI::DBSlayer->build_sql(q/foo ?/, [1]), q/foo '1'/);
is(Async::ORM::DBI::DBSlayer->build_sql(q/foo '?'/), q/foo '?'/);
is(Async::ORM::DBI::DBSlayer->build_sql(q/foo \\'?/, [1]), q/foo \\''1'/);
is(Async::ORM::DBI::DBSlayer->build_sql(q/foo "?"/), q/foo "?"/);
is(Async::ORM::DBI::DBSlayer->build_sql(q/foo \\"?/, [1]), q/foo \\"'1'/);
eval { Async::ORM::DBI::DBSlayer->build_sql(q/foo/, [1]) };
like($@, qr/Passed 1 when 0 expected/);
eval { Async::ORM::DBI::DBSlayer->build_sql(q/foo ?/) };
like($@, qr/Passed 0 when 1 expected/);
