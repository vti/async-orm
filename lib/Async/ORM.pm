package Async::ORM;

use strict;
use warnings;

use Async::Hooks;
use Async::ORM::SQL;
use Async::ORM::Schema;

use constant DEBUG => $ENV{ASYNC_ORM_DEBUG} || 0;

our $VERSION = '0.990101';

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    $self->_related({});
    $self->_columns({});

    $self->init(@_);
    $self->is_in_db(0);
    $self->is_modified(0);

    return $self;
}

sub is_in_db { @_ > 1 ? $_[0]->{is_in_db} = $_[1] : $_[0]->{is_in_db} }

sub is_modified {
    @_ > 1 ? $_[0]->{is_modified} = $_[1] : $_[0]->{is_modified};
}

sub _related { @_ > 1 ? $_[0]->{_related} = $_[1] : $_[0]->{_related} }
sub _columns { @_ > 1 ? $_[0]->{_columns} = $_[1] : $_[0]->{_columns} }

sub init {
    my $self = shift;

    my %values = ref $_[0] ? %{$_[0]} : @_;
    foreach my $key ($self->schema->columns) {
        if (exists $values{$key}) {
            $self->column($key => $values{$key});
        }
        elsif (
            !defined $self->column($key)
            && defined(
                my $default = $self->schema->columns_map->{$key}->{default}
            )
          )
        {
            $self->_columns->{$key} = $default;
        }
    }

    if ($self->schema->relationships) {
        foreach my $rel (%{$self->schema->relationships}) {
            if (exists $values{$rel}) {
                $self->_related->{$rel} = delete $values{$rel};
            }
        }
    }

    # fake columns
    $self->_columns->{$_} = $values{$_} foreach (keys %values);

    return $self;
}

sub schema {
    my $class = shift;

    my $class_name = ref $class ? ref $class : $class;

    return $Async::ORM::Schema::objects{$class_name}
      ||= Async::ORM::Schema->new($class_name, @_);
}

sub columns {
    my $self = shift;

    my $columns = $self->_columns;

    my @columns;
    foreach my $key ($self->schema->columns) {
        if (exists $columns->{$key}) {
            push @columns, $key;
        }
        elsif (
            defined(
                my $default = $self->schema->columns_map->{$key}->{default}
            )
          )
        {
            $columns->{$key} = $default;
            push @columns, $key;
        }
    }

    return @columns;
}

sub column {
    my $self = shift;

    my $columns = $self->_columns;

    if (@_ == 1) {
        return defined $_[0] ? $columns->{$_[0]} : undef;
    }
    elsif (@_ == 2) {
        if (defined $columns->{$_[0]} && defined $_[1]) {
            $self->is_modified(1) if $columns->{$_[0]} ne $_[1];
        }
        elsif (defined $columns->{$_[0]} || defined $_[1]) {
            $self->is_modified(1);
        }

        $columns->{$_[0]} = $_[1];
    }

    return $self;
}

sub clone {
    my $self = shift;

    my %data;
    foreach my $column ($self->schema->columns) {
        next
          if $self->schema->is_primary_key($column)
              || $self->schema->is_unique_key($column);
        $data{$column} = $self->column($column);
    }

    return (ref $self)->new(%data);
}

sub _create_related {
    my $self = shift;
    my ($dbh, $cb) = @_;

    my $relationships = $self->schema->relationships;

    if ($relationships) {
        my $hooks = Async::Hooks->new;

        foreach my $rel_name (keys %{$relationships}) {
            my $rel_type = $relationships->{$rel_name}->{type};

            $hooks->hook(
                chain => sub {
                    my ($ctl, $args) = @_;

                    if (my $rel_values = $self->_related->{$rel_name}) {
                        if ($rel_type eq 'many to many') {
                            $self->set_related(
                                $dbh => $rel_name => $rel_values => sub {
                                    my ($dbh, $objects) = @_;

                                    $self->related($rel_name => $objects);

                                    return $cb->($dbh, $objects);
                                }
                            );
                        }
                        else {
                            my $data;

                            if (ref $rel_values eq 'ARRAY') {
                                $data = $rel_values;
                            }
                            elsif (ref $rel_values eq 'HASH') {
                                $data = [$rel_values];
                            }
                            elsif (ref $rel_values) {
                                $data = [$rel_values->to_hash];
                            }
                            else {
                                die
                                  "wrong params when setting '$rel_name' relationship: $rel_values";
                            }

                            if ($rel_type eq 'one to many') {
                                my $hooks = Async::Hooks->new;

                                my $objects = [];

                                foreach my $d (@$data) {
                                    $hooks->hook(
                                        chain => sub {
                                            my ($ctl, $args) = @_;

                                            $self->create_related(
                                                $dbh => $rel_name => $d =>
                                                  sub {
                                                    my ($dbh, $object) = @_;

                                                    push @$objects, $object;

                                                    $ctl->next;
                                                }
                                            );

                                        }
                                    );
                                }

                                $hooks->call(
                                    chain => [] => sub {
                                        $self->related($rel_name => $objects);
                                        $ctl->next;
                                    }
                                );
                            }
                            else {
                                $self->create_related(
                                    $dbh => $rel_name => $data->[0] => sub {
                                        my ($dbh, $rel_object) = @_;

                                        $self->related(
                                            $rel_name => $rel_object);

                                        $ctl->next;
                                    }
                                );
                            }
                        }
                    }
                    else {
                        $ctl->next;
                    }
                }
            );
        }

        $hooks->call(
            chain => [] => sub {

                #my ($ctl, $args, $is_done) = @_;

                return $cb->($dbh);
            }
        );
    }
    else {
        return $cb->($dbh);
    }
}

sub _update_related {
    my $self = shift;
    my ($dbh, $cb) = @_;

    my $relationships = $self->schema->relationships;

    if ($relationships) {
        foreach my $rel_name (keys %$relationships) {
            if (my $rel = $self->_related->{$rel_name}) {
                my $type = $relationships->{$rel_name}->{type};

                my $hooks = Async::Hooks->new;

                foreach my $object (ref $rel eq 'ARRAY' ? @$rel : ($rel)) {
                    $hooks->hook(
                        chain => sub {
                            my ($ctl, $args) = @_;

                            if ($object->is_modified) {
                                $object->update(
                                    $dbh => sub {
                                        $ctl->next;
                                    }
                                );
                            }
                            else {
                                $ctl->next;
                            }
                        }
                    );
                }

                $hooks->call(
                    chain => [] => sub {
                        return $cb->($dbh);
                    }
                );
            }
        }
    }

    return $cb->($dbh);
}

sub _delete_related {
    my $self = shift;
    my ($dbh, $cb) = @_;

    return $cb->($dbh) unless ref $self;

    my $relationships = $self->schema->relationships;

    if ($relationships) {
        my $hooks = Async::Hooks->new;

        my @rel_names = grep {
                 $relationships->{$_}->{type} eq 'many to many'
              || $relationships->{$_}->{type} eq 'one to one'
              || $relationships->{$_}->{type} eq 'one to many'
        } (keys %{$relationships});

        foreach my $rel_name (@rel_names) {
            $hooks->hook(
                chain => sub {
                    my ($ctl, $args) = @_;

                    $self->delete_related(
                        $dbh => $rel_name => sub {
                            my ($dbh, $ok) = @_;

                            $ctl->next;
                        }
                    );
                }
            );
        }

        $hooks->call(
            chain => [] => sub {

                #my ($ctl, $args, $is_done) = @_;

                return $cb->($dbh);
            }
        );
    }
    else {
        return $cb->($dbh);
    }
}

sub begin_work {
    my $self = shift;
    my ($dbh, $cb) = @_;

    $dbh->begin_work(
        sub {
            my ($dbh) = @_;
            return $cb->($dbh);
        }
    );
}

sub rollback {
    my $self = shift;
    my ($dbh, $cb) = @_;

    $dbh->rollback(
        sub {
            my ($dbh) = @_;
            return $cb->($dbh);
        }
    );
}

sub commit {
    my $self = shift;
    my ($dbh, $cb) = @_;

    $dbh->commit(
        sub {
            my ($dbh) = @_;
            return $cb->($dbh);
        }
    );
}

sub create {
    my $self = shift;
    my ($dbh, $cb) = @_;

    return $cb->($dbh, $self) if $self->is_in_db;

    my $sql = Async::ORM::SQL->build('insert');
    $sql->table($self->schema->table);
    $sql->columns([$self->columns]);
    $sql->driver($dbh->{Driver}->{Name});
    $sql->to_string;

    my @values = map { $self->column($_) } $self->columns;

    warn "$sql" if DEBUG;

    if (my $auto_increment = $self->schema->auto_increment) {
        my $table = $self->schema->table;

        $dbh->exec_and_get_last_insert_id(
            $table,
            $auto_increment,
            "$sql" => [@values] => sub {
                my ($dbh, $id, $rv) = @_;

                return $cb->($dbh) unless $rv;

                $self->column($auto_increment => $id);

                $self->is_in_db(1);
                $self->is_modified(0);

                $self->_create_related(
                    $dbh => sub {
                        my ($dbh) = @_;

                        return $cb->($dbh, $self);
                    }
                );
            }
        );
    }
    else {
        $dbh->exec(
            "$sql" => [@values] => sub {
                my ($dbh, $rows, $rv) = @_;

                return $cb->($dbh) unless $rv;

                $self->is_in_db(1);
                $self->is_modified(0);

                $self->_create_related(
                    $dbh => sub {
                        my ($dbh) = @_;

                        return $cb->($dbh, $self);
                    }
                );
            }
        );
    }
}

sub load {
    my $self = shift;
    my ($dbh, $args, $cb) = @_;

    ($cb, $args) = ($args, {}) unless $cb;

    my @columns;
    foreach my $name ($self->columns) {
        push @columns, $name
          if $self->schema->is_primary_key($name)
              || $self->schema->is_unique_key($name);
    }

    die ref($self) . ": no primary or unique keys specified" unless @columns;

    my $sql = Async::ORM::SQL->build('select');

    $sql->source($self->schema->table);
    $sql->columns($self->schema->columns);
    $sql->where([map { $_ => $self->column($_) } @columns]);

    my $with;
    if ($with = delete $args->{with}) {
        $with = [$with] unless ref $with eq 'ARRAY';
        $self->_resolve_with($sql, $with);
    }

    $sql->to_string;
    warn "$sql" if DEBUG;

    $dbh->exec(
        "$sql" => $sql->bind => sub {
            my ($dbh, $rows, $rv) = @_;

            return $cb->($dbh) unless $rows && @$rows;

            my $object;
            foreach my $row (@$rows) {
                $object = $self->_map_row_to_object(
                    row     => $row,
                    columns => [$sql->columns],
                    with    => $with,
                    object  => $self,
                    prev    => $object
                );
            }

            $object->is_in_db(1);
            $object->is_modified(0);

            return $cb->($dbh, $object);
        }
    );
}

sub update {
    my $self = shift;
    my ($dbh, $args, $cb) = @_;

    ($cb, $args) = ($args, {}) unless $cb;

    my @columns;
    my @values;

    if (ref $self && !%$args) {
        unless ($self->is_modified) {
            $self->_update_related(
                $dbh => sub {
                    my ($dbh) = @_;

                    return $cb->($dbh, $self);
                }
            );
        }

        $args->{where} =
          [map { $_ => $self->column($_) } $self->schema->primary_keys];

        @columns =
          grep { !$self->schema->is_primary_key($_) } $self->columns;
        @values = map { $self->column($_) } @columns;
    }
    else {
        die 'set is required' unless $args->{set};

        while (my ($key, $value) = each %{$args->{set}}) {
            push @columns, $key;
            push @values,  $value;
        }
    }

    my $sql = Async::ORM::SQL->build('update');
    $sql->table($self->schema->table);
    $sql->columns(\@columns);
    $sql->bind(\@values);
    $sql->where([@{$args->{where}}]) if $args->{where};
    $sql->to_string;

    warn "$sql" if DEBUG;

    $dbh->exec(
        "$sql" => $sql->bind => sub {
            my ($dbh, $rows, $rv) = @_;

            return $cb->($dbh) if $rv eq '0E0';

            if (ref $self) {
                $self->_update_related(
                    $dbh => sub {
                        my ($dbh) = @_;

                        return $cb->($dbh, ref $self ? $self : 1);
                    }
                );
            }
            else {
                return $cb->($dbh, ref $self ? $self : 1);
            }
        }
    );
}

sub delete {
    my $self = shift;
    my ($dbh, $args, $cb) = @_;

    ($cb, $args) = ($args, {}) unless $cb;

    if (ref $self && !%$args) {
        $args->{where} =
          [map { $_ => $self->column($_) } $self->schema->primary_keys];

        my %map = @{$args->{where}};

        my @names = keys %map;

        die "specify primary keys or at least one unique key"
          unless grep { defined $map{$_} } @names;

        foreach my $name (@names) {
            die "$name is not primary key or unique column"
              unless $self->schema->is_primary_key($name)
                  || $self->schema->is_unique_key($name);
        }

        my $sql = Async::ORM::SQL->build('delete');
        $sql->table($self->schema->table);
        $sql->where([@{$args->{where}}]) if $args->{where};
        $sql->to_string;

        warn "$sql" if DEBUG;

        $self->_delete_related(
            $dbh => sub {
                my ($dbh) = @_;

                $dbh->exec(
                    "$sql" => $sql->bind => sub {
                        my ($dbh, $rows, $rv) = @_;

                        return $cb->($dbh, 0) if $rv eq '0E0';

                        return $cb->($dbh, 1);
                    }
                );
            }
        );
    }
    else {
        $self->find(
            $dbh => $args => sub {
                my ($dbh, $objects) = @_;

                my $hooks = Async::Hooks->new;

                foreach my $object (@$objects) {
                    $hooks->hook(
                        chain => sub {
                            my ($ctl, $args) = @_;

                            $object->delete($dbh => sub { $ctl->next; });
                        }
                    );
                }

                $hooks->call(
                    chain => [] => sub {
                        return $cb->($dbh, 1);
                    }
                );
            }
        );
    }
}

sub find {
    my $class = shift;
    $class = ref($class) if ref($class);
    my ($dbh, $args, $cb) = @_;

    ($cb, $args) = ($args, {}) unless $cb;

    my $single = delete $args->{single};

    my @columns;
    if (my $cols = delete $args->{columns}) {
        @columns = ref $cols ? @$cols : ($cols);

        unshift @columns, $class->schema->primary_keys;
    }
    else {
        @columns = $class->schema->columns;
    }

    my $sql = Async::ORM::SQL->build('select');
    $sql->source($class->schema->table);
    $sql->columns(@columns);

    my $page = delete $args->{page};
    my $page_size = delete $args->{page_size} || 10;

    unless ($single) {
        if (defined $page) {
            $page = 1 unless $page && $page =~ m/^[0-9]+$/o;
            $sql->offset(($page - 1) * $page_size);
            $sql->limit($page_size);
        }
    }

    if (my $sources = delete $args->{source}) {
        foreach my $source (@$sources) {
            $sql->source($source);
        }
    }

    my $with;
    if ($with = delete $args->{with}) {
        $with = [$with] unless ref $with eq 'ARRAY';
        $class->_resolve_with($sql, $with);
    }

    $sql->merge(%$args);

    $class->_resolve_columns($sql);
    $class->_resolve_order_by($sql);

    $sql->limit(1) if $single;
    $sql->to_string;

    warn "$sql" if DEBUG;

    $dbh->exec(
        "$sql" => $sql->bind => sub {
            my ($dbh, $rows, $rv) = @_;

            return $cb->($dbh, $single ? undef : []) unless $rows && @$rows;

            my $objects;
            my $prev;
            foreach my $row (@$rows) {
                my $object = $class->_map_row_to_object(
                    row     => $row,
                    columns => [$sql->columns],
                    with    => $with,
                    prev    => $prev
                );
                $object->is_in_db(1);
                $object->is_modified(0);

                push @$objects, $object if !$prev || $object ne $prev;

                $prev = $object;
            }

            return $cb->($dbh, $single ? $objects->[0] : $objects);
        }
    );
}

sub count {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    ($cb, $args) = ($args, {}) unless $cb;

    my $pk =
      $class->schema->table . '.' . join(', ', $class->schema->primary_keys);

    my $sql = Async::ORM::SQL->build('select');
    $sql->source($class->schema->table);
    $sql->columns(\"COUNT(DISTINCT $pk)");
    $sql->to_string;

    if (my $sources = delete $args->{source}) {
        $sql->source($_) foreach @$sources;
    }

    $sql->merge(%$args);

    $class->_resolve_columns($sql);

    $sql->to_string;

    warn "$sql" if DEBUG;

    $dbh->exec(
        "$sql" => $sql->bind => sub {
            my ($dbh, $rows, $rv) = @_;

            return $cb->($dbh, $rows->[0]->[0] || 0);
        }
    );
}

sub _load_relationship {
    my $self = shift;
    my ($name) = @_;

    die "unknown relationship $name"
      unless $self->schema->relationships
          && exists $self->schema->relationships->{$name};

    my $relationship = $self->schema->relationships->{$name};

    if ($relationship->type eq 'proxy') {
        my $proxy_key = $relationship->proxy_key;

        die "proxy_key is required for $name" unless $proxy_key;

        $name = $self->column($proxy_key);

        die "proxy_key '$proxy_key' is empty" unless $name;

        $relationship = $self->schema->relationships->{$name};

        die "unknown relatioship $name" unless $relationship;
    }

    return $relationship;
}

sub create_related {
    my $self = shift;
    my ($dbh, $name, $args, $cb) = @_;

    ($cb, $args) = ($args, {}) unless $cb;

    unless ($self->is_in_db) {
        die "can't create related objects when object is not in db";
    }

    my $relationship = $self->_load_relationship($name);

    unless ($relationship->{type} eq 'one to many'
        || $relationship->{type} eq 'many to many'
        || $relationship->{type} eq 'one to one')
    {
        die
          "can be called only on 'one to many', 'one to one' or 'many to many' relationships";
    }

    if ($relationship->{type} eq 'many to many') {
        $self->find_related(
            $dbh => $name => {single => 1, where => [%$args]} => sub {
                my ($dbh, $object) = @_;

                if ($object) {
                    return $cb->($dbh, $object);
                }
                else {
                    my $map_from = $relationship->map_from;
                    my $map_to   = $relationship->map_to;

                    my ($from_foreign_pk, $from_pk) =
                      %{$relationship->map_class->schema->relationships
                          ->{$map_from}->{map}};

                    my ($to_foreign_pk, $to_pk) =
                      %{$relationship->map_class->schema->relationships
                          ->{$map_to}->{map}};

                    $relationship->class->new(%$args)->load(
                        $dbh => sub {
                            my ($dbh, $object) = @_;

                            if ($object) {
                                $relationship->map_class->new(
                                    $from_foreign_pk =>
                                      $self->column($from_pk),
                                    $to_foreign_pk => $object->column($to_pk)
                                  )->create(
                                    $dbh => sub {
                                        my ($dbh, $object) = @_;

                                        return $cb->($dbh, $object);
                                    }
                                  );
                            }
                            else {
                                $relationship->class->new(%$args)->create(
                                    $dbh => sub {
                                        my ($dbh, $object) = @_;

                                        $relationship->map_class->new(
                                            $from_foreign_pk =>
                                              $self->column($from_pk),
                                            $to_foreign_pk =>
                                              $object->column($to_pk)
                                          )->create(
                                            $dbh => sub {
                                                my ($dbh, $map) = @_;

                                                return $cb->($dbh, $object);
                                            }
                                          );
                                    }
                                );
                            }
                        }
                    );
                }
            }
        );
    }
    else {
        my ($from, $to) = %{$relationship->map};

        my @params = ($to => $self->column($from));

        if ($relationship->where) {
            push @params, @{$relationship->where};
        }

        my $object = $relationship->class->new(@params, %$args);

        return $object->create(
            $dbh => sub {
                my ($dbh, $object) = @_;

                return $cb->($dbh, $object);
            }
        );
    }
}

sub related {
    my $self = shift;
    my $name = shift;

    if ($_[0]) {
        $self->_related->{$name} = $_[0];
        return $self;
    }

    return $self->_related->{$name};
}

sub load_related {
    my $self = shift;
    my ($dbh, $name, $args, $cb) = @_;

    ($cb, $args) = ($args, {}) unless $cb;

    $self->find_related(
        $dbh, $name, $args,
        sub {
            my ($dbh, $objects) = @_;

            $self->related($name => $objects);

            return $cb->($dbh, $objects);
        }
    );
}

sub find_related {
    my $self = shift;
    my ($dbh, $name, $args, $cb) = @_;

    ($cb, $args) = ($args, {}) unless $cb;

    my $relationship = $self->_load_relationship($name);

    $args->{where} ||= [];

    if ($relationship->{type} eq 'many to many') {
        my $map_from = $relationship->{map_from};
        my $map_to   = $relationship->{map_to};

        my ($to, $from) =
          %{$relationship->map_class->schema->relationships->{$map_from}
              ->{map}};

        push @{$args->{where}},
          (     $relationship->map_class->schema->table . '.'
              . $to => $self->column($from));

        $args->{source} =
          [$relationship->to_self_map_source, $relationship->to_self_source];
    }
    else {
        my ($from, $to) = %{$relationship->{map}};

        if (   $relationship->{type} eq 'many to one'
            || $relationship->{type} eq 'one to one')
        {
            $args->{single} = 1;

            return $cb->($dbh) unless defined $self->column($from);
        }

        push @{$args->{where}}, ($to => $self->column($from));
    }

    if ($relationship->where) {
        push @{$args->{where}}, @{$relationship->where};
    }

    if ($relationship->with) {
        $args->{with} = $relationship->with;
    }

    $relationship->class->find(
        $dbh => $args => sub {
            my ($dbh, $objects) = @_;

            return $cb->($dbh, $objects);
        }
    );
}

sub count_related {
    my $self = shift;
    my ($dbh, $name, $args, $cb) = @_;

    ($cb, $args) = ($args, {}) unless $cb;

    my $relationship = $self->_load_relationship($name);

    $args->{where} ||= [];

    if ($relationship->{type} eq 'many to many') {
        my $map_from = $relationship->{map_from};
        my $map_to   = $relationship->{map_to};

        my ($to, $from) =
          %{$relationship->map_class->schema->relationships->{$map_from}
              ->{map}};

        push @{$args->{where}},
          (     $relationship->map_class->schema->table . '.'
              . $to => $self->column($from));

        $args->{source} =
          [$relationship->to_self_map_source, $relationship->to_self_source];
    }
    else {
        my ($from, $to) = %{$relationship->map};

        push @{$args->{where}}, ($to => $self->column($from)),;
    }

    if ($relationship->where) {
        push @{$args->{where}}, @{$relationship->where};
    }

    $relationship->class->count(
        $dbh => $args => sub {
            my ($dbh, $count) = @_;

            return $cb->($dbh, $count);
        }
    );
}

sub update_related {
    my $self = shift;
    my ($dbh, $name, $args, $cb) = @_;

    ($cb, $args) = ($args, {}) unless $cb;

    my $relationship = $self->_load_relationship($name);

    if ($relationship->type eq 'many to many') {
        die 'many to many is not supported';
    }
    else {
        my ($from, $to) = %{$relationship->{map}};

        my $where = delete $args->{where} || [];

        if ($relationship->where) {
            push @{$args->{where}}, @{$relationship->where};
        }

        push @{$args->{where}}, ($to => $self->column($from));
    }

    $relationship->class->update(
        $dbh => $args => sub {
            my ($dbh, $ok) = @_;

            return $cb->($dbh, $self, $ok);
        }
    );
}

sub delete_related {
    my $self = shift;
    my ($dbh, $name, $args, $cb) = @_;

    ($cb, $args) = ($args, {}) unless $cb;

    my $relationship = $self->_load_relationship($name);

    $args->{where} ||= [];

    my $class_param = 'class';
    if ($relationship->{type} eq 'many to many') {
        my $map_from = $relationship->{map_from};
        my $map_to   = $relationship->{map_to};

        my ($to, $from) =
          %{$relationship->map_class->schema->relationships->{$map_from}
              ->{map}};

        push @{$args->{where}}, ($to => $self->column($from));

        $class_param = 'map_class';
    }
    else {
        my ($from, $to) = %{$relationship->{map}};

        push @{$args->{where}}, ($to => $self->column($from));
    }

    if ($relationship->where) {
        push @{$args->{where}}, @{$relationship->where};
    }

    return $relationship->$class_param->delete(
        $dbh => $args => sub {
            return $cb->(@_);
        }
    );
}

sub set_related {
    my $self = shift;
    my ($dbh, $name, $args, $cb) = @_;

    my $relationship = $self->_load_relationship($name);

    die "only 'many to many and one to one' are supported"
      unless $relationship->{type} eq 'many to many'
          || $relationship->{type} eq 'one to one';

    my @data;

    if (ref $args eq 'ARRAY') {
        @data = @$args;
    }
    elsif (ref $args eq 'HASH') {
        @data = ($args);
    }
    else {
        die 'wrong set_related params';
    }

    my $hooks = Async::Hooks->new;

    $hooks->hook(
        'chain' => sub {
            my ($ctl, $args) = @_;

            $self->delete_related(
                $dbh => $name => sub {
                    my ($dbh, $ok) = @_;

                    $ctl->next;
                }
            );
        }
    );

    my $objects;
    foreach my $data (@data) {
        $hooks->hook(
            'chain' => sub {
                my ($ctl, $args) = @_;

                $self->create_related(
                    $dbh => $name => $data,
                    sub {
                        my ($dbh, $object) = @_;

                        push @$objects, $object;

                        $ctl->next;
                    }
                );
            }
        );
    }

    $hooks->call(
        'chain' => [] => sub {
            my ($ctl, $args, $is_done) = @_;

            return $cb->(
                $dbh,
                $relationship->{type} eq 'one to one'
                ? $objects->[0]
                : $objects
            );
        }
    );
}

sub _map_row_to_object {
    my $class = shift;
    $class = ref($class) if ref($class);
    my %params = @_;

    my $row     = $params{row};
    my $with    = $params{with};
    my $columns = $params{columns};
    my $o       = $params{object};
    my $prev    = $params{prev};

    my %values = map { $_ => shift @$row } @$columns;

    my $object = $o ? $o->init(%values) : $class->new(%values);

    if ($prev) {
        my $prev_keys = join(',',
            map { "$_=" . $prev->column($_) } $prev->schema->primary_keys);
        my $object_keys = join(',',
            map { "$_=" . $object->column($_) }
              $object->schema->primary_keys);

        if ($prev_keys eq $object_keys) {
            $object = $prev;
        }
    }

    if ($with) {
        foreach my $rel_info (@$with) {
            my $parent_object = $object;

            if ($rel_info->{subwith}) {
                foreach my $subwith (@{$rel_info->{subwith}}) {
                    $parent_object = $parent_object->_related->{$subwith};
               # do not check , for compatible when whole 'null' columns of a subwith
               #     die "load $subwith first" unless $parent_object;
                      last unless $parent_object;
                }
                splice @$row, 0, scalar @{$rel_info->{columns}} and next unless $parent_object;
            }

            foreach my $parent_object_ (
                ref $parent_object eq 'ARRAY'
                ? @$parent_object
                : ($parent_object)
              )
            {
                my $relationship =
                  $parent_object_->schema->relationships->{$rel_info->{name}};

                %values = map { $_ => shift @$row } @{$rel_info->{columns}};

                if (grep { defined $values{$_} } keys %values) {
                    my $rel_object = $relationship->class->new(%values);

                    if (   $relationship->{type} eq 'many to one'
                        || $relationship->{type} eq 'one to one')
                    {
                        $parent_object_->_related->{$rel_info->{name}} =
                          $rel_object;
                    }
                    else {
                        $parent_object_->_related->{$rel_info->{name}} ||= [];
                        push
                          @{$parent_object_->_related->{$rel_info->{name}}},
                          $rel_object;
                    }
                }
            }
        }
    }

    return $object;
}

sub _resolve_with {
    my $class = shift;
    return unless @_;

    my ($sql, $with) = @_;

    foreach my $rel_info (@$with) {
        unless (ref $rel_info eq 'HASH') {
            $rel_info = {name => $rel_info};
        }

        my $relationship;
        my $relationships = $class->schema->relationships;
        my $last          = 0;
        my $name;
        my $rel_as;
        while (1) {
            if ($rel_info->{name} =~ s/^(\w+)\.//) {
                $name = $1;

                $rel_info->{subwith} ||= [];
                push @{$rel_info->{subwith}}, $name;
            }
            else {
                $name = $rel_info->{name};
                $last = 1;
            }

            unless ($relationship = $relationships->{$name}) {
                die $class . ": unknown relationship '$name'";
            }

            if ($relationship->type eq 'many to many') {
                $sql->source($relationship->to_map_source);
            }

            $sql->source($relationship->to_source(rel_as => $rel_as));

            if ($last) {
                my @columns;
                if ($rel_info->{columns}) {
                    $rel_info->{columns} = [$rel_info->{columns}]
                      unless ref $rel_info->{columns} eq 'ARRAY';

                    unshift @{$rel_info->{columns}},
                      $relationship->class->schema->primary_keys;
                }
                else {
                    $rel_info->{columns} =
                      [$relationship->class->schema->columns];
                }

                $sql->columns(@{$rel_info->{columns}});

                last;
            }
            else {
                $relationships = $relationship->class->schema->relationships;
            }

            $rel_as = $name;
        }
    }
}

sub _resolve_columns {
    my $self = shift;
    return unless @_;

    my ($sql) = @_;

    my $where = $sql->where;
    return unless $where;

    if (ref $where eq 'ARRAY') {
        my $count = 0;
        while (my ($key, $value) = @{$where}[$count, $count + 1]) {
            last unless $key;

            if (ref $key eq 'SCALAR') {
                $count++;
            }
            else {
                my $relationships = $self->schema->relationships;
                my $parent_prefix;
                while ($key =~ s/^(\w+)\.//) {
                    my $prefix = $1;

                    if (my $relationship = $relationships->{$prefix}) {
                        if ($relationship->type eq 'many to many') {
                            $sql->source($relationship->to_map_source);
                        }

                        $sql->source(
                            $relationship->to_source(
                                rel_as => $parent_prefix
                            )
                        );

                        my $rel_name = $relationship->name;
                        $where->[$count] = "$rel_name.$key";

                        $relationships =
                          $relationship->class->schema->relationships;

                        $parent_prefix = $prefix;
                    }
                }

                $count += 2;
            }
        }
    }

    return $self;
}

sub _resolve_order_by {
    my $self = shift;
    return unless @_;

    my ($sql) = @_;

    my $order_by = $sql->order_by;
    return unless $order_by;

    my @parts = split(',', $order_by);

    foreach my $part (@parts) {
        my $relationships = $self->schema->relationships;
        while ($part =~ s/^(\w+)\.//) {
            my $prefix = $1;

            if (my $relationship = $relationships->{$prefix}) {
                my $rel_table = $relationship->related_table;
                $part = "$rel_table.$part";

                $relationships = $relationship->class->schema->relationships;
            }
        }
    }

    $sql->order_by(join(', ', @parts));

    return $self;
}

sub to_hash {
    my $self = shift;

    my @columns = keys %{$self->{_columns}};

    my $hash = {};
    foreach my $key (@columns) {
        $hash->{$key} = $self->column($key);
    }

    foreach my $name (keys %{$self->_related}) {
        my $rel = $self->_related->{$name};

        die "unknown '$name' relationship" unless $rel;

        if (ref $rel eq 'ARRAY') {
        }
        elsif ($rel->isa('Async::ORM::Iterator')) {
        }
        else {
            $hash->{$name} = $rel->to_hash;
        }
    }

    return $hash;
}

1;
__END__

=head1 NAME

Async::ORM - Asynchronous Object-relational mapping

=head1 SYNOPSIS

    package Article;

    use strict;
    use warnings;

    use base 'Async::ORM';

    __PACKAGE__->schema(
        table          => 'article',
        columns        => [qw/ id category_id author_id title /],
        primary_keys   => ['id'],
        auto_increment => 'id',

        relationships => {
            author => {
                type  => 'many to one',
                class => 'Author',
                map   => {author_id => 'id'}
            },
            category => {
                type  => 'many to one',
                class => 'Category',
                map   => {category_id => 'id'}
            },
            tags => {
                type      => 'many to many',
                map_class => 'ArticleTagMap',
                map_from  => 'article',
                map_to    => 'tag'
            },
            comments => {
                type  => 'one to many',
                class => 'Comment',
                where => [type => 'article'],
                map   => {id => 'master_id'}
            }
        }
    );

    package ArticleTagMap;

    use strict;
    use warnings;

    use base 'Async::ORM';

    __PACKAGE__->schema(
        table        => 'article_tag_map',
        columns      => [qw/ article_id tag_id /],
        primary_keys => [qw/ article_id tag_id /],

        relationships => {
            article => {
                type  => 'many to one',
                class => 'Article',
                map   => {article_id => 'id'}
            },
            tag => {
                type  => 'many to one',
                class => 'Tag',
                map   => {tag_id => 'id'}
            }
        }
    );

    package Tag;

    use strict;
    use warnings;

    use base 'Async::ORM';

    __PACKAGE__->schema(
        table          => 'tag',
        columns        => [qw/id name/],
        primary_keys   => ['id'],
        auto_increment => 'id',
        unique_keys    => ['name'],

        relationships => {
            articles => {
                type      => 'many to many',
                map_class => 'ArticleTagMap',
                map_from  => 'tag',
                map_to    => 'article'
            }
        }
    );

    package Author;

    use strict;
    use warnings;

    use base 'Async::ORM';

    __PACKAGE__->schema(
        table          => 'author',
        columns        => [qw/id name password/],
        primary_keys   => ['id'],
        auto_increment => 'id',
        unique_keys    => 'name',

        relationships => {
            author_admin => {
                type  => 'one to one',
                class => 'AuthorAdmin',
                map   => {id => 'author_id'}
            },
            articles => {
                type  => 'one to many',
                class => 'Article',
                map   => {id => 'author_id'}
            }
        }
    );

    package Comment;

    use strict;
    use warnings;

    use base 'Async::ORM';

    __PACKAGE__->schema(
        table        => 'comment',
        columns      => [qw/master_id type content/],
        primary_keys => [qw/master_id type/],

        relationships => {
            master => {
                type      => 'proxy',
                proxy_key => 'type',
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

    package main;

    my $dbh = Async::ORM::DBI->new(dbi => 'dbi:SQLite:table.db');

    Author->new(
        name     => 'foo',
        articles => [
            {   title => 'foo',
                tags  => {name => 'people'}
            },
            {   title => 'bar',
                tags  => [{name => 'unix'}, {name => 'perl'}]
            }
        ]
      )->create(
        $dbh => sub {
            my ($dbh, $author) = @_;

            ok($author);

            $author->related('articles')->[0]->create_related(
                $dbh => 'comments' => {content => 'foo'} => sub {
                    my ($dbh, $comment) = @_;

                    ok($comment);

                    Article->find(
                        $dbh => {where => ['tags.name' => 'unix']} => sub {
                            my ($dbh, $articles) = @_;

                            is(@$articles, 1);

                            $author->delete(
                                $dbh => sub {
                                    my ($dbh, $ok) = @_;

                                    ok($ok);
                                }
                            );
                        }
                    );
                }
            );
        }
      );

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 is_in_db

    my $article = Article->new;
    print $article->is_in_db; # 0

    $article->create;
    print $article->is_in_db; # 1

Returns true when object was created or loaded. Otherwise false.

=head2 is_modified

    my $article = Article->new;
    print $article->is_modified; # 0

    $article->set(title => 'foo');
    print $article->is_modified; # 1

Returns true when object was modified (setting columns). Otherwise false.

=head1 METHODS

=head2 C<new>

    my $article = Article->new;

Returns a new L<Async::ORM> object.

=head2 C<debug>

You can turn on debugging by setting ASYNC_ORM_DEBUG environmental variable.

=head2 C<init>

    my $article = Article->new;
    $article->init(title => 'foo', content => 'bar');

Sets objects columns.

=head2 C<schema>

Used to define class schema. For more information see L<Async::ORM::Schema>.

=head2 C<columns>

    my @columns = $article->columns;

Returns object columns that are set or have a default value.

=head2 C<column>

    my $title = $article->column('title');
    $article->column(title => 'foo');

Gets and sets column value.

=head2 C<clone>

    my $clone = $article->clone;

Object cloning. Everything is copied except primary key and unique key values.

=head2 C<begin_work>

    Async::ORM->begin_work($dbh => sub {
        my ($dbh) = @_;

            ...
    });

Begins transaction.

=head2 C<rollback>

Rolls back transaction.

=head2 C<commit>

Commits transaction.

=head2 C<create>

    Article->new(title => 'foo')->create($dbh => sub {
        my ($dbh, $article) = @_;

            ...
    });

Creates a new object. Sets auto increment field to the last inserted id.

=head2 C<load>

    Article->new(id => 1)->load($dbh => sub {
        my ($dbh, $article) = @_;

            ...
    });

Loads object using primary key or unique key that was provided when creating a
new instance. Dies if there was no primary or unique key.

=head2 C<update>

    $article->update($dbh => sub {
        my ($dbh, $article) = @_;

            ...
    });

    or

    Article->update(
        $dbh => {where => [title => 'foo'], set => {title => 'bar'}} => sub {
            my ($dbh, $article) = @_;

            ...
        }
    );

Updates object.

=head2 C<delete>

    $article->delete($dbh => sub {
        my ($dbh, $rows_delete) = @_;

            ...
    });

Deletes object.

=head2 C<find>

    Article->find($dbh => {where => [title => 'foo']} => sub {
        my ($dbh, $articles) = @_;

            ...
    });

Find objects. The second argument is a hashref that is translated into sql. Keys
that can be used:

=head3 C<where>

Build SQL. For more information see L<Async::ORM::SQL>.

=head3 C<with>

Prefetch related objects.

=head3 C<single>

By default C<find> returns array reference, by setting C<single> to 1 undef or
one object is returned (the first one).

=head3 C<order_by>

ORDER BY

=head3 C<having>

HAVING

=head3 C<limit>

LIMIT

=head3 C<offset>

OFFSET

=head3 C<page>

With C<page_size> you can select specific pages without calculation limit and
offset by yourself.

=head3 C<page_size>

The size of the C<page>. It is 20 items by default.

=head3 C<columns>

Select only specific columns.

=head2 C<count>

    Article->cound($dbh => {where => [title => 'foo']} => sub {
        my ($dbh, $articles) = @_;

            ...
    });

Count objects.

=head2 C<related>

    my $author = $article->related('author');

Gets prefetched related object(s).

=head2 C<create_related>

    $article->create_related($dbh => 'comments' => {content => 'bar'} => sub {
        my ($dbh, $comments) = @_;

            ...
    });

Creates related objects.

=head2 C<find_related>

    $article->find_related(
        $dbh => 'comments' => {where => [content => 'bar']} => sub {
            my ($dbh, $comments) = @_;

            ...
        }
    );

Finds related objects.

=head2 C<load_related>

    $article->load_related(
        $dbh => 'comments' => {where => [content => 'bar']} => sub {
            my ($dbh, $comments) = @_;

            $article->related('comments');
            ...
        }
    );

Same as C<find_objects> but sets C<related> method.

=head2 C<count_related>

    $article->count_related(
        $dbh => 'comments' => {where => [content => 'bar']} => sub {
            my ($dbh, $comments) = @_;

            ...
        }
    );

Counts related objects.

=head2 C<update_related>

    $article->update_related(
        $dbh => 'comments' => {
            where => [content => 'bar'],
            set   => {content => 'foo'}
          } => sub {
            my ($dbh, $comments) = @_;

            ...
        }
    );

Updates related objects. Use set key for setting new values.

=head2 C<delete_related>

    $article->delete_related(
        $dbh => 'comments' => {where => [content => 'bar']} => sub {
            my ($dbh, $rows_deleted) = @_;

            ...
        }
    );

Deletes related objects.

=head2 C<set_related>

    $article->set_related(
        $dbh => 'tags' => [{name => 'foo'}, {name => 'bar'}] => sub {
            my ($dbh, $tags) = @_;

            ...
        }
    );

Creates and deletes related objects to satisfy the set. Usefull when setting
many to many relationships.

=head2 C<to_hash>

Serializes object to hash. All prefetched objects are serialized also.

=head1 SUPPORT

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/vti/async-orm/commits/master

=head1 SEE ALSO

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 CREDITS

In alphabetical order:

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
