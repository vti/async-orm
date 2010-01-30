package Async::ORM::DBI::DBSlayer;

use strict;
use warnings;

use base 'Async::ORM::DBI::Abstract';

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{host} ||= 'localhost';
    $self->{port} ||= 9090;

    $self->{Driver}->{Name} = 'mysql';

    return $self;
}

sub host { @_ > 1 ? $_[0]->{host} = $_[1] : $_[0]->{host} }
sub port { @_ > 1 ? $_[0]->{port} = $_[1] : $_[0]->{port} }

sub http_req_cb {
    @_ > 1 ? $_[0]->{http_req_cb} = $_[1] : $_[0]->{http_req_cb};
}

sub json_encode {
    @_ > 1 ? $_[0]->{json_encode} = $_[1] : $_[0]->{json_encode};
}

sub json_decode {
    @_ > 1 ? $_[0]->{json_decode} = $_[1] : $_[0]->{json_decode};
}

sub build_sql {
    my $self = shift;
    my ($sql, $args) = @_;

    $args ||= [];

    my $expected_count = 0;
    my $passed_count = @$args;

    my $output = '';
    my $double_quote_on = 0;
    my $single_quote_on = 0;
    my $escape_on       = 0;
    for (split //, $sql) {
        if ($escape_on) {
            $escape_on = 0;
            $output .= $_;
            next;
        }

        $escape_on = 1 if (/\\/);

        if ($escape_on) {
            $output .= $_;
            next;
        }

        $double_quote_on = ($double_quote_on ? 0 : 1) if (/\"/);
        $single_quote_on = ($single_quote_on ? 0 : 1) if (/\'/);

        unless ($single_quote_on || $double_quote_on) {
            if (m/\?/g) {
                $expected_count++;

                my $arg = shift @$args;
                die _build_sql_error($passed_count, $expected_count)
                  unless defined $arg;
                $arg =~ s/'/''/g;

                $output .= qq/'$arg'/;
                next;
            }
        }

        $output .= $_;
    }

    die _build_sql_error($passed_count, $expected_count) if @$args;

    return $output;
}

sub _build_sql_error {"Passed $_[0] when $_[1] expected"}

sub exec_and_get_last_insert_id {
    my $self = shift;
    my ($table, $auto_increment, @tail) = @_;

    return $self->exec(@tail);
}

sub exec {
    my $self = shift;
    my ($sql, $args, $cb) = @_;

    ($cb, $args) = ($args, []) unless $cb;

    my $url = 'http://' . $self->host . ':' . $self->port . '/db';

    $sql = $self->build_sql($sql, $args);

    my $database = $self->{database};

    $self->http_req_cb->(
        $url, 'GET',
        {},
        $self->json_encode->({SQL => "use $database;$sql"}) => sub {
            my ($url, $status, $headers, $body) = @_;

            die 'Wrong response status' unless $status && $status == 200;

            my $res = $self->json_decode->($body);
            die 'Wrong response' unless defined $res;

            $res = $res->{RESULT};
            shift @$res;
            $res = $res->[0];

            if (my $rows = $res->{ROWS}) {

                return $cb->($self, $rows, $res->{SUCCESS} ? 1 : 0);
            }
            else {
                if (my $id = $res->{INSERT_ID}) {
                    return $cb->($self, $id, $res->{SUCCESS} ? 1 : 0);
                }

                return $cb->($self, undef, $res->{SUCCESS} ? 1 : 0);
            }
        }
    );
}

sub begin_work {
    my $self = shift;
    my ($cb) = @_;

    $self->dbh->begin_work or die $DBI::errstr;

    $cb->($self);
}

sub commit {
    my $self = shift;
    my ($cb) = @_;

    $self->dbh->commit or die $DBI::errstr;

    $cb->($self);
}

sub rollback {
    my $self = shift;
    my ($cb) = @_;

    $self->dbh->rollback or die $DBI::errstr;

    $cb->($self);
}

sub func {
    my $self = shift;
    my ($name, $args, $cb) = @_;

    ($cb, $args) = ($args, []) unless $cb;

    my $rv = $self->dbh->func(@$args, $name);

    return $cb->($self, $rv);
}

1;
