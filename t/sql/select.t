use Test::More tests => 21;

use Async::ORM::SQLBuilder;

my $sql = Async::ORM::SQLBuilder->build('select');
$sql->source('foo');
$sql->columns('foo');
$sql->where([id => 2]);
is("$sql", "SELECT `foo` FROM `foo` WHERE (`id` = ?)");

$sql = Async::ORM::SQLBuilder->build('select');
$sql->source('foo');
$sql->columns({name => 'foo', as => 'bar'});
$sql->where([id => 2]);
is("$sql", "SELECT `foo` AS bar FROM `foo` WHERE (`id` = ?)");

$sql = Async::ORM::SQLBuilder->build('select');
$sql->source('foo');
$sql->columns({name => \'foo', as => 'bar'});
$sql->where([id => 2]);
is("$sql", "SELECT foo AS bar FROM `foo` WHERE (`id` = ?)");

$sql = Async::ORM::SQLBuilder->build('select');
$sql->source('foo');
$sql->columns('foo');
$sql->where([id => 2]);
$sql->source('foo');
is("$sql", "SELECT `foo` FROM `foo` WHERE (`id` = ?)");

$sql = Async::ORM::SQLBuilder->build('select');
$sql->source('foo');
$sql->columns('hello');
$sql->where([id => 2]);
is("$sql", "SELECT `hello` FROM `foo` WHERE (`id` = ?)");

$sql = Async::ORM::SQLBuilder->build('select');
$sql->source('foo');
$sql->columns(qw/ hello boo /);
$sql->where([id => 2]);
is("$sql", "SELECT `hello`, `boo` FROM `foo` WHERE (`id` = ?)");

$sql = Async::ORM::SQLBuilder->build('select');
$sql->source('foo');
$sql->columns('foo.hello');
$sql->where([id => 2]);
is("$sql", "SELECT `foo`.`hello` FROM `foo` WHERE (`id` = ?)");

$sql = Async::ORM::SQLBuilder->build('select');
$sql->source('foo');
$sql->columns('foo.hello');
$sql->order_by('foo, bar DESC');
is("$sql", "SELECT `foo`.`hello` FROM `foo` ORDER BY `foo`, `bar` DESC");

$sql = Async::ORM::SQLBuilder->build('select');
$sql->source('foo');
$sql->columns('foo.hello');
$sql->order_by('foo    ASC   , bar');
is("$sql", "SELECT `foo`.`hello` FROM `foo` ORDER BY `foo` ASC, `bar`");

$sql = Async::ORM::SQLBuilder->build('select');
$sql->source('foo');
$sql->columns(qw/ hello boo /);
$sql->where([id => 2]);
$sql->group_by('foo');
$sql->having('foo');
$sql->order_by('hello DESC');
$sql->limit(2);
$sql->offset(1);
is("$sql",
    "SELECT `hello`, `boo` FROM `foo` WHERE (`id` = ?) GROUP BY `foo` HAVING `foo` ORDER BY `hello` DESC LIMIT 2 OFFSET 1"
);

$sql = Async::ORM::SQLBuilder->build('select');
$sql->source('foo');
$sql->columns('foo');
$sql->where("1 > 2");
is("$sql", 'SELECT `foo` FROM `foo` WHERE (1 > 2)');

#$sql->command('select')->source('foo')->where({id => {like => '123%'}});
#is("$sql", 'SELECT * FROM foo WHERE id LIKE 123%');

$sql = Async::ORM::SQLBuilder->build('select');
$sql->source({name => 'foo', as => 'boo'});
$sql->columns(qw/ foo bar /);
is("$sql", 'SELECT `foo`, `bar` FROM `foo` AS `boo`');

$sql = Async::ORM::SQLBuilder->build('select');
$sql->source('table1');
$sql->columns('bar_2.foo');
$sql->source(
    {   join       => 'inner',
        name       => 'table2',
        constraint => ['table1.foo' => 'table2.bar']
    }
);
$sql->columns(qw/ bar baz/);

is("$sql",
    "SELECT `bar_2`.`foo`, `table2`.`bar`, `table2`.`baz` FROM `table1` INNER JOIN `table2` ON `table1`.`foo` = `table2`.`bar`"
);
is("$sql",
    "SELECT `bar_2`.`foo`, `table2`.`bar`, `table2`.`baz` FROM `table1` INNER JOIN `table2` ON `table1`.`foo` = `table2`.`bar`"
);


$sql = Async::ORM::SQLBuilder->build('select');
$sql->source('table1');
$sql->columns('bar_2.foo');
$sql->source(
    {   join       => 'inner',
        name       => 'table2',
        constraint => ['table1.foo' => 'table2.bar', 'table1.bar' => 'hello']
    }
);
$sql->columns(qw/ bar baz/);

is("$sql",
    "SELECT `bar_2`.`foo`, `table2`.`bar`, `table2`.`baz` FROM `table1` INNER JOIN `table2` ON `table1`.`foo` = `table2`.`bar` AND `table1`.`bar` = 'hello'"
);

$sql = Async::ORM::SQLBuilder->build('select');
$sql->source('table1');
$sql->columns('foo');
$sql->source(
    {   join       => 'inner',
        name       => 'table2',
        constraint => ['table1.foo' => 'table2.bar']
    }
);
$sql->columns(qw/ bar baz/);

is("$sql",
    "SELECT `table1`.`foo`, `table2`.`bar`, `table2`.`baz` FROM `table1` INNER JOIN `table2` ON `table1`.`foo` = `table2`.`bar`"
);

$sql = Async::ORM::SQLBuilder->build('select');
$sql->source('table1');
$sql->source('table2');
$sql->source(
    {   join       => 'inner',
        name       => 'table3',
        constraint => ['table1.foo' => 'table2.bar']
    }
);
$sql->columns(qw/ foo bar /);
is("$sql",
    "SELECT `table3`.`foo`, `table3`.`bar` FROM `table1`, `table2` INNER JOIN `table3` ON `table1`.`foo` = `table2`.`bar`"
);

$sql = Async::ORM::SQLBuilder->build('select');
$sql->source('table1');
$sql->source('table2');
$sql->source(
    {   join       => 'inner',
        name       => 'table3',
        constraint => ['table1.foo' => 'table2.bar']
    }
);
$sql->columns(qw/ foo bar /);
$sql->where(['table3.foo' => 1]);
is("$sql",
    "SELECT `table3`.`foo`, `table3`.`bar` FROM `table1`, `table2` INNER JOIN `table3` ON `table1`.`foo` = `table2`.`bar` WHERE (`table3`.`foo` = ?)"
);

$sql = Async::ORM::SQLBuilder->build('select');
$sql->source('table1');
$sql->source('table2');
$sql->source(
    {   join       => 'inner',
        name       => 'table3',
        constraint => ['table1.foo' => 'table2.bar']
    }
);
$sql->columns(qw/ foo bar /);
$sql->where(['foo' => 1]);
is("$sql",
    "SELECT `table3`.`foo`, `table3`.`bar` FROM `table1`, `table2` INNER JOIN `table3` ON `table1`.`foo` = `table2`.`bar` WHERE (`table1`.`foo` = ?)"
);

$sql = Async::ORM::SQLBuilder->build('select');
$sql->source('table1');
$sql->source('table2');
$sql->source(
    {   join       => 'inner',
        name       => 'table3',
        constraint => ['table1.foo' => 'table2.bar']
    }
);
$sql->columns(qw/ foo bar /);
$sql->order_by('addtime');
$sql->group_by('foo');
is("$sql",
    "SELECT `table3`.`foo`, `table3`.`bar` FROM `table1`, `table2` INNER JOIN `table3` ON `table1`.`foo` = `table2`.`bar` GROUP BY `table1`.`foo` ORDER BY `table1`.`addtime`"
);

$sql = Async::ORM::SQLBuilder->build('select');
$sql->source('table1');
$sql->source('table2');
$sql->source(
    {   join       => 'inner',
        name       => 'table3',
        constraint => ['table1.foo' => 'table2.bar']
    }
);
$sql->columns(qw/ foo bar /);
$sql->order_by('table2.addtime');
$sql->group_by('table2.foo');
is("$sql",
    "SELECT `table3`.`foo`, `table3`.`bar` FROM `table1`, `table2` INNER JOIN `table3` ON `table1`.`foo` = `table2`.`bar` GROUP BY `table2`.`foo` ORDER BY `table2`.`addtime`"
);

