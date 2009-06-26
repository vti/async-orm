package Async::ORM;

use Any::Moose;

use Async::Hooks;
use Async::ORM::SQL;
use Async::ORM::Schema;

our $VERSION = '20090624';

has is_in_db => (
    isa     => 'Bool',
    is      => 'rw',
    default => 1
);

has is_modified => (
    isa     => 'Bool',
    is      => 'rw',
    default => 0
);

has _related => (
    isa     => 'HashRef',
    is      => 'rw',
    default => sub { {} }
);

has _columns => (
    isa     => 'HashRef',
    is      => 'rw',
    default => sub { {} }
);

sub debug { $ENV{ASYNC_ORM_DEBUG} || 0 }

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();

    $self->init(@_);
    $self->is_in_db(0);
    $self->is_modified(0);

    return $self;
}

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
                my $default = $self->schema->_columns_map->{$key}->{default}
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
            defined(my $default = $self->schema->_columns_map->{$key}->{default}))
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
                                        $self->related( $rel_name => $objects);
                                        $ctl->next;
                                    }
                                );
                            }
                            else {
                                $self->create_related(
                                    $dbh => $rel_name => $data->[0] => sub {
                                        my ($dbh, $rel_object) = @_;

                                        $self->related($rel_name => $rel_object);

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
            $relationships->{$_}->{type}      eq 'many to many'
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

    warn "$sql" if $self->debug;

    $dbh->exec(
        "$sql" => [@values] => sub {
            my ($dbh, $rows, $metadata) = @_;

            return $cb->($dbh) unless $metadata->{rv};

            $self->is_in_db(1);
            $self->is_modified(0);

            if (my $auto_increment = $self->schema->auto_increment) {
                my $table = $self->schema->table;
                $dbh->func(
                    last_insert_id =>
                      [undef, undef, $table, $auto_increment] => sub {
                        my ($dbh, $id, $handle_error) = @_;

                        $self->column($auto_increment => $id);
                        $self->is_modified(0);

                        #return $cb->($dbh, $self);
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
                $self->_create_related(
                    $dbh => sub {
                        my ($dbh) = @_;

                        return $cb->($dbh, $self);
                    }
                );
            }
        }
    );
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
    warn "$sql" if $self->debug;

    $dbh->exec(
        "$sql" => $sql->bind => sub {
            my ($dbh, $rows, $metadata) = @_;

            return $cb->($dbh) unless $rows && @$rows;

            $self->_map_row_to_object(
                row     => $rows->[0],
                columns => [$sql->columns],
                with    => $with,
                object  => $self
            );

            $self->is_modified(0);
            $self->is_in_db(1);

            return $cb->($dbh, $self);
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

        $args->{where} = [map { $_ => $self->column($_) } $self->schema->primary_keys];

        @columns =
          grep { !$self->schema->is_primary_key($_) } $self->schema->columns;
        @values = map { $self->column($_) } @columns;
    }
    else {
        die 'set is required' unless $args->{set};

        while (my ($key, $value) = each %{$args->{set}}) {
            push @columns, $key;
            push @values, $value;
        }
    }

    my $sql = Async::ORM::SQL->build('update');
    $sql->table($self->schema->table);
    $sql->columns(\@columns);
    $sql->bind(\@values);
    $sql->where([@{$args->{where}}]) if $args->{where};
    $sql->to_string;

    warn "$sql" if $self->debug;

    $dbh->exec(
        "$sql" => $sql->bind => sub {
            my ($dbh, $rows, $metadata) = @_;

            return $cb->($dbh) if $metadata->{rv} eq '0E0';

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
        $args->{where} = [map { $_ => $self->column($_) } $self->schema->primary_keys];

        my %map = @{$args->{where}};

        my @names = keys %map;

        die "specify primary keys or at least one unique key"
          unless grep { defined $map{$_} } @names;

        foreach my $name (@names) {
            die "$name is not primary key or unique column"
              unless $self->schema->is_primary_key($name)
                  || $self->schema->is_unique_key($name);
        }
    }

    my $sql = Async::ORM::SQL->build('delete');
    $sql->table($self->schema->table);
    $sql->where([@{$args->{where}}]) if $args->{where};
    $sql->to_string;

    $self->_delete_related(
        $dbh => sub {
            my ($dbh) = @_;

            $dbh->exec(
                "$sql" => $sql->bind => sub {
                    my ($dbh, $rows, $metadata) = @_;

                    return $cb->($dbh, 0) if $metadata->{rv} eq '0E0';

                    return $cb->($dbh, 1);
                }
            );
        }
    );
}

sub find {
    my $class = shift;
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

    warn $sql if $class->debug;

    $dbh->exec(
        "$sql" => $sql->bind => sub {
            my ($dbh, $rows, $metadata) = @_;

            return $cb->($dbh, $single ? undef : []) unless $rows && @$rows;

            my $objects;
            foreach my $row (@$rows) {
                my $object = $class->_map_row_to_object(
                    row     => $row,
                    columns => [$sql->columns],
                    with    => $with
                );
                $object->is_in_db(1);
                $object->is_modified(0);

                push @$objects, $object;
            }

            return $cb->($dbh, $single ? $objects->[0] : $objects);
        }
    );
}

sub count {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    ($cb, $args) = ($args, {}) unless $cb;

    my $sql = Async::ORM::SQL->build('select');
    $sql->source($class->schema->table);
    $sql->columns(\'COUNT(*) AS count');
    $sql->to_string;

    if (my $sources = delete $args->{source}) {
        $sql->source($_) foreach @$sources;
    }

    $sql->merge(%$args);

    $class->_resolve_columns($sql);

    warn $sql if $class->debug;

    $dbh->exec(
        "$sql" => $sql->bind => sub {
            my ($dbh, $rows, $metadata) = @_;

            return $cb->($dbh, $rows->[0]->[0]);
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

    if ($relationship->{type} eq 'proxy') {
        my $proxy_key = $relationship->{proxy_key};

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
                    return  $cb->($dbh, $object);
                }
                else {
                    my $map_from = $relationship->map_from;
                    my $map_to   = $relationship->map_to;

                    my ($from_foreign_pk, $from_pk) =
                      %{$relationship->map_class->schema->relationships->{$map_from}
                          ->{map}};

                    my ($to_foreign_pk, $to_pk) =
                      %{$relationship->map_class->schema->relationships->{$map_to}->{map}};

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

        ($from, $to) =
          %{$relationship->map_class->schema->relationships->{$map_to}->{map}};

        my $table     = $relationship->class->schema->table;
        my $map_table = $relationship->map_class->schema->table;
        $args->{source} = [
            {   name       => $map_table,
                join       => 'left',
                constraint => ["$table.$to" => "$map_table.$from"]
            }
        ];
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
            my ($dbh , $objects) = @_;

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
        die 'WTF?';
        #my $map_from = $relationship->{map_from};
        #my $map_to   = $relationship->{map_to};

        #my ($to, $from) =
          #%{$relationship->{map_class}->schema->relationships->{$map_from}
              #->{map}};

        #push @{$params{where}},
          #(     $relationship->map_class->schema->table . '.'
              #. $to => $self->column($from));

        #($from, $to) =
          #%{$relationship->{map_class}->schema->relationships->{$map_to}
              #->{map}};

        #my $table     = $relationship->class->schema->table;
        #my $map_table = $relationship->{map_class}->schema->table;
        #$params{source} = [
            #{   name       => $map_table,
                #join       => 'left',
                #constraint => ["$table.$to" => "$map_table.$from"]
            #}
        #];
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

    my ($from, $to) = %{$relationship->{map}};

    my $where = delete $args->{where} || [];

    if ($relationship->where) {
        push @$where, @{$relationship->where};
    }

    $relationship->class->update(
        $dbh => {
            where => [$to => $self->column($from), @$where],
            %$args
          } => sub {
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
    my $class  = shift;
    my %params = @_;

    my $row     = $params{row};
    my $with    = $params{with};
    my $columns = $params{columns};
    my $o       = $params{object};

    my %values = map { $_ => shift @$row } @$columns;

    my $object = $o ? $o->init(%values) : $class->new(%values);

    if ($with) {
        foreach my $rel_info (@$with) {
            my $parent_object = $object;

            if ($rel_info->{subwith}) {
                foreach my $subwith (@{$rel_info->{subwith}}) {
                    $parent_object =
                      $parent_object->_related->{$subwith};
                    die "load $subwith first" unless $parent_object;
                }
            }

            my $relationship =
              $parent_object->schema->relationships->{$rel_info->{name}};

            if (   $relationship->{type} eq 'many to one'
                || $relationship->{type} eq 'one to one')
            {
                %values = map { $_ => shift @$row } @{$rel_info->{columns}};

                if (grep { defined $values{$_} } keys %values) {
                    my $rel_object = $relationship->class->new(%values);
                    $parent_object->_related->{$rel_info->{name}} =
                      $rel_object;
                }
            }
            else {
                die $relationship->{type} . ' not supported';
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

            if (   $relationship->type eq 'many to one'
                || $relationship->type eq 'one to one')
            {
                $sql->source($relationship->to_source);
            }
            else {
                die $relationship->type . ' is not supported';
            }

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
                while ($key =~ s/^(\w+)\.//) {
                    my $prefix = $1;

                    if (my $relationship = $relationships->{$prefix}) {
                        if ($relationship->type eq 'many to many') {
                            $sql->source($relationship->to_map_source);
                        }

                        $sql->source($relationship->to_source);

                        my $rel_table = $relationship->related_table;
                        $where->[$count] = "$rel_table.$key";

                        $relationships =
                          $relationship->class->schema->relationships;
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


=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 C<attr>

=head1 METHODS

=head2 C<new>

    my $article = Article->new;

Returns a new L<Async::ORM> object.

=head2 C<debug>

=head2 C<init>

=head2 C<schema>

=head2 C<columns>

=head2 C<column>

=head2 C<clone>

=head2 C<begin_work>

=head2 C<rollback>

=head2 C<commit>

=head2 C<create>

=head2 C<load>

=head2 C<update>

=head2 C<delete>

=head2 C<find>

=head2 C<count>

=head2 C<related>

=head2 C<create_related>

=head2 C<load_related>

=head2 C<find_related>

=head2 C<count_related>

=head2 C<update_related>

=head2 C<delete_related>

=head2 C<set_related>

=head2 C<to_hash>

=head1 SUPPORT

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/vti/async-orm/commits/master

=head1 SEE ALSO

=head1 AUTHOR

Viacheslav Tikhanovskii, C<vti@cpan.org>.

=head1 CREDITS

In alphabetical order:

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tikhanovskii.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
