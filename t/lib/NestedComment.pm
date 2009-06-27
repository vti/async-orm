package NestedComment;

use Any::Moose;

extends 'Async::ORM';

use Async::Hooks;

__PACKAGE__->schema(
    table   => 'nested_comment',
    columns => [
        qw/id addtime master_id master_type parent_id level rgt lft content/,
    ],
    primary_keys   => 'id',
    auto_increment => 'id',
    relationships  => {
        parent => {
            type  => 'many to one',
            class => 'NestedComment',
            map   => {parent_id => 'id'}
        },
        ansestors => {
            type  => 'one to many',
            class => 'NestedComment',
            map   => {id => 'parent_id'}
        },
        master => {
            type      => 'proxy',
            proxy_key => 'master_type',
        },
        article => {
            type  => 'many to one',
            class => 'Article',
            map   => {master_id => 'id'}
        },
        podcast => {
            type  => 'many to one',
            class => 'Podcast',
            map   => {master_id => 'id'}
        }
    }
);

sub create {
    my $self = shift;
    my ($dbh, $cb) = @_;

    my $rgt = 1;
    my $level = 0;
    my $comment_count = 0;

    my $hooks = Async::Hooks->new;

    $hooks->hook(
        chain => sub {
            my ($ctl, $args) = @_;

            if ($self->column('parent_id')) {
                $self->find_related(
                    $dbh => 'parent' => sub {
                        my ($dbh, $parent) = @_;

                        if ($parent) {
                            $self->column(
                                master_id => $parent->column('master_id'));
                            $self->column(
                                master_type => $parent->column('master_type')
                            );

                            $level = $parent->column('level') + 1;

                            $rgt = $parent->column('lft');
                        }

                        $ctl->next;
                    }
                );
            }
            else {
                $ctl->next;
            }
        }
    );

    $hooks->hook(
        chain => sub {
            my ($ctl, $args) = @_;

            $self->count(
                $dbh => {
                    where => [
                        master_type => $self->column('master_type'),
                        master_id   => $self->column('master_id')
                    ]
                  } => sub {
                    my ($dbh, $count) = @_;

                    $comment_count = $count;

                    $ctl->next;
                }
            );
        }
    );

    $hooks->hook(
        chain => sub {
            my ($ctl, $args) = @_;

            if ($comment_count) {
                $self->find(
                    $dbh => {
                        where => [
                            master_id   => $self->column('master_id'),
                            master_type => $self->column('master_type'),
                            parent_id   => $self->column('parent_id')
                        ],
                        order_by => 'addtime DESC, id DESC',
                        single   => 1
                      } => sub {
                        my ($dbh, $left) = @_;

                        $rgt = $left->column('rgt') if $left;

                        $self->update(
                            $dbh => {
                                set   => {'rgt' => \'rgt + 2'},
                                where => [rgt   => {'>' => $rgt}]
                              } => sub {
                                my ($dbh) = @_;

                                $self->update(
                                    $dbh => {
                                        set   => {'lft' => \'lft + 2'},
                                        where => [lft   => {'>' => $rgt}]
                                      } => sub {
                                        $ctl->next;
                                    }
                                );
                            }
                        );
                    }
                );
            }
            else {
                $ctl->next;
            }
        }
    );

    $hooks->hook(
        chain => sub {
            my ($ctl, $args) = @_;

            $self->column(lft   => $rgt + 1);
            $self->column(rgt   => $rgt + 2);
            $self->column(level => $level);

            $self->column(addtime => time) unless $self->column('addtime');

            $self->SUPER::create(
                $dbh => sub {
                    my ($dbh) = @_;

                    $ctl->next;
                }
            );
        }
    );

    $hooks->call(
        chain => [] => sub {
            $cb->($dbh, $self);
        }
    );
}

1;
