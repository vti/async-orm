use Test::More tests => 4;

use lib 't/lib';

use Async::ORM::Relationship::Base;

my $rel = Async::ORM::Relationship::Base->new(
    name       => 'foo',
    type       => 'many to one',
    orig_class => 'Article'
);
ok($rel);

is($rel->name,       'foo');
is($rel->type,       'many to one');
is($rel->orig_class, 'Article');
