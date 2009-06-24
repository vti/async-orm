package Async::ORM::SQL::Select;

use Any::Moose;

extends 'Async::ORM::SQL';

has group_by => (is => 'rw');

has having => (is => 'rw');

has order_by => (is => 'rw');

has limit => (is => 'rw');

has offset => (is => 'rw');

has _sources => (
    isa     => 'ArrayRef',
    is      => 'rw',
    default => sub { [] }
);

has _columns => (
    isa     => 'ArrayRef',
    is      => 'rw',
    default => sub { [] }
);

has where_logic => (is => 'rw');

has where => (is => 'rw');

sub source {
    my $self = shift;
    my ($source) = @_;

    $source = {name => $source} unless ref $source eq 'HASH';

    $source->{columns} ||= [];
    push @{$self->_sources}, $source
      unless grep { $_->{name} eq $source->{name} } @{$self->_sources};

    return $self;
}

sub columns {
    my $self = shift;

    if (@_) {
        die 'first define source' unless @{$self->_sources};

        $self->_sources->[-1]->{columns} =
          ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

        return $self;
    }

    my @column_names = ();

    foreach my $col (@{$self->_sources->[0]->{columns}}) {
        if (ref $col eq 'SCALAR') {
            $col = $$col;
        }
        elsif (ref $col eq 'HASH') {
            ($col) = $col->{as};
        }

        push @column_names, $col;
    }

    return @column_names;
}

sub to_string {
    my $self = shift;

    my $query = "";

    $query .= 'SELECT ';

    my $need_prefix = @{$self->_sources} > 1;
    my $first       = 1;
    foreach my $source (@{$self->_sources}) {
        if (@{$source->{columns}}) {
            $query .= ', ' unless $first;

            my @columns;
            foreach my $col (@{$source->{columns}}) {
                if (ref $col eq 'SCALAR') {
                    push @columns, $$col;
                }
                else {
                    my $col_full = $col;

                    my $as;
                    if (ref $col_full eq 'HASH') {
                        $as       = $col_full->{as};
                        $col_full = $col_full->{name};
                    }

                    if (ref $col_full eq 'SCALAR') {
                        $col_full = $$col_full;
                    }
                    else {
                        if ($col_full =~ s/^(\w+)\.//) {
                            $col_full = "`$1`.`$col_full`";
                        }
                        elsif ($need_prefix) {
                            $col_full =
                              '`' . $source->{name} . "`.`$col_full`";
                        }
                        else {
                            $col_full = "`$col_full`";
                        }
                    }

                    push @columns, $as ? "$col_full AS $as" : $col_full;
                }
            }

            $query .= join(', ', @columns);

            $first = 0;
        }
    }

    $query .= ' FROM ';

    $query .= $self->_sources_to_string;

    my $default_prefix;
    if ($need_prefix) {
        $default_prefix = $self->_sources->[0]->{name};
    }

    if (my $where = $self->where) {
        if (ref $where eq 'ARRAY' && @$where || ref $where ne 'ARRAY') {
            $query .= ' WHERE ';
            $query .= $self->_where_to_string($self->where, $default_prefix);
        }
    }

    if (my $group_by = $self->group_by) {
        if ($default_prefix) {
            if ($group_by =~ s/^(\w+)\.//) {
                $group_by = "`$1`.`$group_by`";
            }
            else {
                $group_by = "`$default_prefix`.`$group_by`";
            }
        }
        else {
            $group_by = "`$group_by`";
        }

        $query .= ' GROUP BY ' . $group_by;
    }

    $query .= ' HAVING `' . $self->having . '`' if $self->having;

    if (my $order_by = $self->order_by) {
        my @cols = split(/\s*,\s*/, $order_by);

        $query .= ' ORDER BY ';

        my $first = 1;
        foreach my $col (@cols) {
            my $order;
            if ($col =~ s/\s+(ASC|DESC)\s*//i) {
                $order = $1;
            }

            if ($col =~ s/^(\w+)\.//) {
                $col = "`$1`.`$col`";
            }
            elsif ($default_prefix) {
                $col = "`$default_prefix`.`$col`";
            }
            else {
                $col = "`$col`";
            }

            $query .= ', ' unless $first;

            $query .= $col;
            $query .= ' ' . $order if $order;

            $first = 0;
        }
    }

    $query .= ' LIMIT ' . $self->limit if $self->limit;

    $query .= ' OFFSET ' . $self->offset if $self->offset;

    return $query;
}

sub _sources_to_string {
    my $self = shift;

    my $string = "";

    my $first = 1;
    foreach my $source (@{$self->_sources}) {
        $string .= ', ' unless $first || $source->{join};

        $string .= ' ' . uc $source->{join} . ' JOIN ' if $source->{join};
        $string .= '`' . $source->{name} . '`';

        $string .= ' AS ' . '`' . $source->{as} . '`' if $source->{as};

        if ($source->{constraint}) {
            $string .= ' ON ';

            my $count = 0;
            while (my ($key, $value) =
                @{$source->{constraint}}[$count, $count + 1])
            {
                last unless $key;

                $string .= ' AND ' unless $count == 0;

                my $from = $key;
                my $to   = $value;

                if ($from =~ s/^(\w+)\.//) {
                    $from = "`$1`.`$from`";
                }
                else {
                    $from = "`$from`";
                }

                if ($to =~ s/^(\w+)\.//) {
                    $to = "`$1`.`$to`";
                }
                else {
                    $to = "'$to'";
                }

                $string .= $from . ' = ' . $to;

                $count += 2;
            }
        }

        $first = 0;
    }

    return $string;
}

1;
