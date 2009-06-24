use Test::More tests => 3;

use lib 't/lib';

use Async::ORM::Relationship::Base;

my $rel = Async::ORM::Relationship::Base->new(
    type       => 'many to one',
    orig_class => 'Article'
);
ok($rel);

is($rel->type,       'many to one');
is($rel->orig_class, 'Article');
