=head1 NAME

AnyEvent::DBI - asynchronous DBI access

=head1 SYNOPSIS

   use AnyEvent::DBI;

   my $cv = AnyEvent->condvar;

   my $dbh = new AnyEvent::DBI "DBI:SQLite:dbname=test.db", "", "";

   $dbh->exec ("select * from test where num=?", 10, sub {
      my ($rows, $rv) = @_;

      print "@$_\n"
         for @$rows;

      $cv->broadcast;
   });

   # asynchronously do sth. else here

   $cv->wait;

=head1 DESCRIPTION

This module is an L<AnyEvent> user, you need to make sure that you use and
run a supported event loop.

This module implements asynchronous DBI access by forking or executing
separate "DBI-Server" processes and sending them requests.

It means that you can run DBI requests in parallel to other tasks.

The overhead for very simple statements ("select 0") is somewhere
around 120% to 200% (dual/single core CPU) compared to an explicit
prepare_cached/execute/fetchrow_arrayref/finish combination.

=cut

package AnyEvent::DBI;

use strict;
no warnings;

use Carp;
use Socket ();
use Scalar::Util ();
use Storable ();

use DBI ();

use AnyEvent ();
use AnyEvent::Util ();

use Errno qw(:POSIX);
use Fcntl qw(F_SETFD);
use POSIX qw(sysconf _SC_OPEN_MAX);

our $VERSION = '1.2';
my  $fd_max  = 1023; # default
eval { $fd_max = sysconf _SC_OPEN_MAX - 1; };

# this is the forked server code

our $DBH;

sub req_open {
   my (undef, $dbi, $user, $pass, %attr) = @{+shift};

   $DBH = DBI->connect ($dbi, $user, $pass, \%attr) or die $DBI::errstr;

   [1]
}

sub req_exec {
   my (undef, $st, @args) = @{+shift};
   my $sth = $DBH->prepare_cached ($st, undef, 1)
      or die [$DBI::errstr];

   my $rv = $sth->execute (@args)
      or die [$sth->errstr];

   [1, $sth->{NUM_OF_FIELDS} ? $sth->fetchall_arrayref : undef, { rv => $rv }]
}

sub req_attr {
   my (undef, $attr_name, $attr_val) = @{+shift};

   if (defined $attr_val) {
      $DBH->{$attr_name} = $attr_val;
   }

   [1, $DBH->{$attr_name}]
}

sub req_begin_work {
   [scalar $DBH->begin_work or die $DBI::errstr]
}

sub req_commit {
   [scalar $DBH->commit or die $DBI::errstr]
}

sub req_rollback {
   [scalar $DBH->rollback or die $DBI::errstr]
}

sub req_func {
   my (undef, $arg_string, $function) = @{+shift};
   my @args = eval $arg_string;

   if ($@) {
      die "Bad func() arg string: $@";
   }

   my $rv = $DBH->func (@args, $function);
   return [1, $rv . $DBH->err];
}

sub serve {
   my ($fileno) = @_;

   open my $fh, ">>&=$fileno"
      or die "Couldn't open service socket: $!";

   no strict;

   eval {
      my $rbuf;

      while () {
         sysread $fh, $rbuf, 16384, length $rbuf
            or last;

         while () {
            my $len = unpack "L", $rbuf;

            # full request available?
            last unless $len && $len + 4 <= length $rbuf;

            my $req = Storable::thaw substr $rbuf, 4;
            substr $rbuf, 0, $len + 4, ""; # remove length + request

            my $wbuf = eval { pack "L/a*", Storable::freeze $req->[0]($req) };
            $wbuf = pack "L/a*", Storable::freeze [undef, ref $@ ? "$@->[0]" : $@ , ref $@ ? $@->[1] : 1]
               if $@;

            for (my $ofs = 0; $ofs < length $wbuf; ) {
               $ofs += (syswrite $fh, substr $wbuf, $ofs
                           or die "unable to write results");
            }
         }
      }
   };

   if (AnyEvent::WIN32) {
      kill 9, $$; # no other way on the broken windows platform
      # and the above doesn't even work on windows, it seems the only
      # way to is to leak memory and kill 9 from the parent. yay.
   }

   require POSIX;
   POSIX::_exit 0;
   # and the above kills the parent process on windows
}

sub start_server {
   serve shift @ARGV;
}

=head2 METHODS

=over 4

=item $dbh = new AnyEvent::DBI $database, $user, $pass, [key => value]...

Returns a database handle for the given database. Each database handle
has an associated server process that executes statements in order. If
you want to run more than one statement in parallel, you need to create
additional database handles.

The advantage of this approach is that transactions work as state is
preserved.

Example:

   $dbh = new AnyEvent::DBI
             "DBI:mysql:test;mysql_read_default_file=/root/.my.cnf", "", "";

Additional key-value pairs can be used to adjust behaviour:

=over 4

=item on_error => $callback->($dbh, $filename, $line, $fatal)

When an error occurs, then this callback will be invoked. On entry, C<$@>
is set to the error message. C<$filename> and C<$line> is where the
original request was submitted.

If the fatal argument is true then the database connection shuts down and your
database handle becomes invalid.  All of your queued request callbacks are
called without any arguments.

If omitted, then C<die> will be called on any errors, fatal or not.

The C<$dbh> argument is always a weak reference to the AnyEvent::DBI object.

=item on_connect => $callback->($dbh)

If you supply an on_connect callback, then this callback will be invoked after
the database connection is attempted.  If the connection succeeds, C<$dbh>
contains a weak reference to the AnyEvent::DBI object.  If the connection fails
for any reason, no arguments are passed to the callback and C<$@> contains
$DBI::errstr.

Regardless of whether on_connect is supplied, connect errors will result in
on_error being called.  However, if no on_connect callback is supplied, then
connection errors are considered fatal.  The client will die() and the on_error
callback will be called with C<$fatal> true.  When on_connect is supplied,
connect error are not fatal and AnyEvent::DBI will not die().  You still
cannot, however, use the $dbh object you recived from new() to make requests.

=item exec_server => 1

If you supply an exec_server argument, then the DBI server process will call
something like:

  exec "$^X -MAnyEvent::DBI -e AnyEvent::DBI::start_server"

after forking.  This will provide the cleanest possible interpreter for your
database server.  There are special provisions to include C<-Mblib> if the
current interpreter is running with blib.

If you do not supply the exec_server argument (or supply it with a false value)
then the traditional method of starting the server within the same forked
interpreter context is used.  The forked interpreter will try to clean itself
up by calling POSIX::close on all filedescriptors except STDIN, STDOUT, and
STDERR (and the socket it uses to communicate with the cilent, of course).

=item timeout => seconds

If you supply a timeout parameter (floating point number of seconds), then a
timer is started any time the DBI handle expects a response from the server.
This includes connection setup as well as requests made to the backend.  The
timeout spans the duration from the moment the first data is written (or queued
to be written) until all expected responses are returned, but is postponed for
"timeout" seconds each time more data is returned from the server.  If the
timer ever goes off then a fatal error is generated.  If you have an on_error
handler installed, then it will be called, otherwise your program will die().

When altering your databases with timeouts it is wise to use transactions. If
you quit due to timeout while performing insert, update or schema-altering
commands you can end up not knowing if the action was submitted to the
database, complicating recovery.

Timeout errors are always fatal.

=back

Any additional key-value pairs will be rolled into a hash reference and passed
as the final argument to the DBI->connect(...) call.  For example, to supress
errors on STDERR and send them instead to an AnyEvent::Handle you could do:

    $dbh = new AnyEvent::DBI
             "DBI:mysql:test;mysql_read_default_file=/root/.my.cnf", "", "",
               PrintError => 0,
               on_error   => sub { $log_handle->push_write("DBI Error: $@ at $_[1]:$_[2]\n"); }

=cut

# stupid Storable autoloading, total loss-loss situation
Storable::thaw Storable::freeze [];

sub new {
   my ($class, $dbi, $user, $pass, %arg) = @_;

   socketpair my $client, my $server, &Socket::AF_UNIX, &Socket::SOCK_STREAM, &Socket::PF_UNSPEC
      or croak "unable to create dbi communicaiton pipe: $!";

   my %dbi_args =  ( %arg ) ;
   delete @dbi_args{qw( on_connect on_error timeout exec_server )};

   my $self = bless \%arg, $class;
   $self->{fh} = $client;

   Scalar::Util::weaken (my $wself = $self);

   AnyEvent::Util::fh_nonblocking $client, 1;

   my $rbuf;
   my @caller = (caller)[1,2]; # the "default" caller

   $self->{rw} = AnyEvent->io (fh => $client, poll => "r", cb => sub {
      return unless $wself;
      my $len = sysread $client, $rbuf, 65536, length $rbuf;
      my $err = $!;

      if ($len > 0) {
         # we received data, so reset the timer
         delete $wself->{timer};
         if ($wself->{timeout}) {
            $wself->{timer} = AnyEvent->timer (
               after => $wself->{timeout},
               cb    => sub { $wself && $wself->_timedout },
            );
         }

         while () {
            my $len = unpack "L", $rbuf;

            # full response available?
            last unless $len && $len + 4 <= length $rbuf;

            my $res = Storable::thaw substr $rbuf, 4;
            substr $rbuf, 0, $len + 4, ""; # remove length + request

            last unless $wself;
            my $req = shift @{ $wself->{queue} };

            if (defined $res->[0]) {
               $res->[0] = $wself;
               $req->[0](@$res);
            } else {
               my $cb = shift @$req;
               $@=$res->[1];
               $cb->();
               if ($wself) { # cb() could have deleted it
                  $wself->_error ($res->[1], @$req, $res->[2]); # error, request record, is_fatal
               }
            }

            # no more queued requests, so cancel timeout
            if ($wself) {
               delete $wself->{timer}
                  unless @{ $wself->{queue} };
            }
         }

      } elsif (defined $len) {
         $wself->_error ("unexpected eof", @caller, 1);
      } else {
         return if $err == EAGAIN;
         $wself->_error ("read error: $err", @caller, 1);
      }
   });

   $self->{ww_cb} = sub {
      return unless $wself;
      my $len = syswrite $client, $wself->{wbuf}
         or return delete $wself->{ww};

      substr $wself->{wbuf}, 0, $len, "";
   };

   my $pid = fork;

   if ($pid) {
      # parent
      close $server;
   } elsif (defined $pid) {
      # child
      my $serv_fno = fileno $server;

      if ($self->{exec_server}) {
         fcntl $server, F_SETFD, 0; # don't close the server side
         exec "$^X -MAnyEvent::DBI -e AnyEvent::DBI::start_server $serv_fno";
         POSIX::_exit 124;
      } else {
         ($_ != $serv_fno) && POSIX::close $_
            for $^F+1..$fd_max;
         serve $serv_fno;
         POSIX::_exit 0; # not reachable
      }
   } else {
      croak "fork: $!";
   }

   $self->{child_pid} = $pid;
   # set a connect timeout
   if ($self->{timeout}) {
      $self->{timer} = AnyEvent->timer (
         after => $self->{timeout},
         cb    => sub { $wself && $wself->_timedout },
      );
   }
   $self->_req (
      ($self->{on_connect} ? $self->{on_connect} : sub { }),
      (caller)[1,2],
      req_open => $dbi, $user, $pass, %dbi_args
   );

   $self
}

sub _server_pid {
   shift->{child_pid}
}

sub kill_child {
   my $self      = shift;
   my $child_pid = delete $self->{child_pid};
   if ($child_pid) {
      # send SIGKILL in two seconds
      my $murder_timer = AnyEvent->timer (
         after => 2,
         cb    => sub {
            kill 9, $child_pid;
         },
      );

      # reap process
      my $kid_watcher;
      $kid_watcher = AnyEvent->child (
         pid => $child_pid ,
         cb  => sub {
            # just hold on to this so it won't go away
            undef $kid_watcher;
            # cancel SIGKILL
            undef $murder_timer;
         },
      );

      # SIGTERM = the beginning of the end
      kill TERM => $child_pid;
   }
}

sub DESTROY {
   shift->kill_child;
}

sub _error {
   my ($self, $error, $filename, $line, $fatal) = @_;

   if ($fatal) {
      delete $self->{rw};
      delete $self->{ww};
      delete $self->{fh};
      delete $self->{timer};

      # for fatal errors call all enqueued callbacks with error
      while (my $req = shift @{$self->{queue}}) {
         $@ = $error;
         $req->[0]->();
      }
      $self->kill_child;
   }

   $@ = $error;

   if ($self->{on_error}) {
      $self->{on_error}($self, $filename, $line, $fatal)
   } else {
      die "$error at $filename, line $line\n";
   }
}

=item $dbh->on_error ($cb->($dbh, $filename, $line, $fatal))

Sets (or clears, with C<undef>) the on_error handler.

=cut

sub on_error {
   $_[0]{on_error} = $_[1];
}

=item $dbh->on_connect ($cb->($dbh))

Sets (or clears, with C<undef>) the on_connect handler.

=cut

sub on_connect {
   $_[0]{on_connect} = $_[1];
}

=item $dbh->timeout ($seconds)

Sets (or clears, with C<undef>) the database timeout. Useful to extend the
timeout when you are about to make a really long query.

=cut

sub timeout {
   my ($self, $timeout) = @_;

   if ($timeout) {
      $self->{timeout} = $timeout;
      # reschedule timer if one was running
      if ($self->{timer}) {
         Scalar::Util::weaken (my $wself = $self);
         $self->{timer} = AnyEvent->timer (
            after => $self->{timeout},
            cb    => sub { $wself && $wself->_timedout },
         );
      }
   } else {
      delete @{%$self}[qw(timer timeout)];
   }
}

sub _timedout {
   my ($self) = @_;

   my $req = shift @{ $self->{queue} };

   if ($req) {
      my $cb = shift @$req;
      $@ = 'TIMEOUT';
      $cb->();
      $self->_error ('TIMEOUT', @$req, 1); # timeouts are always fatal
   } else {
      # shouldn't be possible to timeout without a pending request
      $self->_error ('TIMEOUT', 'NO_PENDING_WTF', 0, 1);
   }
}

sub _req {
   my ($self, $cb, $filename, $line) = splice @_, 0, 4, ();

   if (!$self->{fh}) {
      my $err = $@ = 'NO DATABASE CONNECTION';
      $cb->();
      $self->_error ($err, $filename, $line, 1);
      return;
   }

   push @{ $self->{queue} }, [$cb, $filename, $line ];

   if ($self->{timeout} && !$self->{timer}) {
      Scalar::Util::weaken (my $wself = $self);
      $self->{timer} = AnyEvent->timer (
         after => $self->{timeout},
         cb    => sub { $wself && $wself->_timedout },
      );
   }

   $self->{wbuf} .= pack "L/a*", Storable::freeze \@_;

   unless ($self->{ww}) {
      my $len = syswrite $self->{fh}, $self->{wbuf};
      substr $self->{wbuf}, 0, $len, "";

      # still any left? then install a write watcher
      $self->{ww} = AnyEvent->io (fh => $self->{fh}, poll => "w", cb => $self->{ww_cb})
         if length $self->{wbuf};
   }
}

=item $dbh->exec ("statement", @args, $cb->($dbh, \@rows, \%metadata))

Executes the given SQL statement with placeholders replaced by
C<@args>. The statement will be prepared and cached on the server side, so
using placeholders is compulsory.

The callback will be called with a weakened AnyEvent::DBI object as the first
argument and the result of C<fetchall_arrayref> as (or C<undef> if the
statement wasn't a select statement) as the second argument.  Third argument is
a hash reference holding metadata about the request.  Currently, the only key
defined is C<$metadata->{rv}> holding the return value of
C<execute>. Additional metadata might be added.

If an error occurs and the C<on_error> callback returns, then no arguments
will be passed and C<$@> contains the error message.

=item $dbh->attr (attr_name, [ $attr_value ], $cb->($dbh, $new_value))

An accessor for the handle attributes, such as AutoCommit, RaiseError,
PrintError, etc.  If you provide an $attr_value, then the given attribute will
be set to that value.

The callback will be passed the database handle and the
attribute's value if successful.  If accessing the attribute fails, then no
arguments are passed to your callback, and $@ contains a description of the
problem instead.

=item $dbh->begin_work ($cb->($dbh))

=item $dbh->commit ($cb->($dbh))

=item $dbh->rollback ($cb->($dbh))

The begin_work, commit, and rollback methods exopose the equivelant transaction
control methods of the DBI.  If something goes wrong, you will get no $dbh in
your callaback, and will instead have an error to examine in $@.

=item $dbh->func ('string_which_yields_args_when_evaled', $func_name, $cb->($dbh, $result, $handle_error))

This gives access to database driver private methods.  Because they are not
standard you cannot always depend on the value of $result or $handle_error.
Check the documentation for your specific driver/function combination to see
what it returns.

Note that the first argument will be eval'ed to produce the argument list to
the func() method.  This must be done because the searialization protocol
between the AnyEvent::DBI server process and your program does not support the
passage of closures.

Here's an example to extend the query language in SQLite so it supports an
intstr() function:

    $cv = AnyEvent->condvar;
    $dbh->func(
       q{
          'instr',
          2,
          sub {
             my ($string, $search) = @_;
             return index $string, $search;
          },
       },
       'create_function',
       sub {return $cv->send($@) unless $_[0];$cv->send(undef,@_[1,2]);}
    );
    my ($err,$result,$handle_err) = $cv->recv();
    die "EVAL failed: $err" if $err;
    # otherwise, we can ignore $result and $handle_err for this particular func

=cut

for my $cmd_name (qw(exec attr begin_work commit rollback func)) {
   eval 'sub ' . $cmd_name . '{
      my $cb = pop;
      splice @_, 1, 0, $cb, (caller)[1,2], "req_' . $cmd_name . '";
      goto &_req;
   }';
}

=back

=head1 SEE ALSO

L<AnyEvent>, L<DBI>.

=head1 AUTHOR

   Marc Lehmann <schmorp@schmorp.de>
   http://home.schmorp.de/

   Adam Rosenstein <adam@redcondor.com>
   http://www.redcondor.com/

=cut

1;

