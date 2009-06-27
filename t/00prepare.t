use Test::More tests => 1;

use lib 't/lib';

use TestDB;

my $dbh = TestDB->dbh;
ok($dbh);

$dbh->exec(<<"", sub {});
DROP TABLE IF EXISTS `category`;

$dbh->exec(<<"", sub {});
CREATE TABLE `category` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `author_id` INTEGER,
 `title` varchar(40) default ''
);

$dbh->exec(<<"", sub {});
DROP TABLE IF EXISTS `article`;

$dbh->exec(<<"", sub {});
CREATE TABLE `article` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `category_id` INTEGER,
 `author_id` INTEGER,
 `title` varchar(40) default ''
);

$dbh->exec(<<"", sub {});
DROP TABLE IF EXISTS `comment`;

$dbh->exec(<<"", sub {});
CREATE TABLE `comment` (
 `master_id` INTEGER,
 `type` varchar(40) default '',
 `content` varchar(40) default '',
 PRIMARY KEY(`master_id`, `type`)
);

$dbh->exec(<<"", sub {});
DROP TABLE IF EXISTS `podcast`;

$dbh->exec(<<"", sub {});
CREATE TABLE `podcast` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `author_id` INTEGER,
 `title` varchar(40) default ''
);

$dbh->exec(<<"", sub {});
DROP TABLE IF EXISTS `tag`;

$dbh->exec(<<"", sub {});
CREATE TABLE `tag` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `name` varchar(40) default ''
);


$dbh->exec(<<"", sub {});
DROP TABLE IF EXISTS `article_tag_map`;

$dbh->exec(<<"", sub {});
CREATE TABLE `article_tag_map` (
 `article_id` INTEGER,
 `tag_id` INTEGER,
 PRIMARY KEY(`article_id`, `tag_id`)
);

$dbh->exec(<<"", sub {});
DROP TABLE IF EXISTS `author`;

$dbh->exec(<<"", sub {});
CREATE TABLE `author` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `name` varchar(40) default '',
 `password` varchar(40) default '',
 UNIQUE(`name`)
);


$dbh->exec(<<"", sub {});
DROP TABLE IF EXISTS `author_admin`;

$dbh->exec(<<"", sub {});
CREATE TABLE `author_admin` (
 `author_id` INTEGER PRIMARY KEY,
 `beard` varchar(40) default ''
);

$dbh->exec(<<"", sub {});
DROP TABLE IF EXISTS `nested_comment`;

$dbh->exec(<<"", sub {});
CREATE TABLE `nested_comment` (
 `id`          INTEGER PRIMARY KEY,
 `parent_id`   INTEGER,
 `master_id`   INTEGER NOT NULL,
 `master_type` VARCHAR(20) NOT NULL ,
 `path`        VARCHAR(255),
 `level`       INTEGER NOT NULL ,
 `content`     VARCHAR(1024) NOT NULL,
 `addtime`     INTEGER NOT NULL,
 `lft`         INTEGER NOT NULL,
 `rgt`         INTEGER NOT NULL
);

