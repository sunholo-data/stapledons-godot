#!/bin/sh
# Bound the rig-only census including input preparation; macOS has no timeout.
# Run an argument vector directly, never through an interpolated shell command.
set -eu
exec perl -MTime::HiRes=time -MPOSIX=setsid -e '
  my $limit = shift @ARGV;
  die "usage: worlds_census_budget.sh SECONDS COMMAND [ARG...]\n"
    unless defined($limit) && $limit =~ /^\d+$/ && $limit > 0 && @ARGV;
  my $start = time;
  my $child = fork();
  die "fork: $!\n" unless defined $child;
  if (!$child) { setsid() >= 0 or die "setsid: $!\n"; exec @ARGV; die "exec: $!\n"; }
  my $stop = sub {
    my ($why, $code) = @_;
    kill "TERM", $child;
    kill "TERM", -$child;
    select undef, undef, undef, 0.5;
    kill "KILL", -$child;
    waitpid($child, 0);
    print STDERR "census-large: FAIL $why\n";
    exit $code;
  };
  local $SIG{ALRM} = sub { $stop->("exceeded ${limit}s budget", 124) };
  local $SIG{TERM} = sub { $stop->("terminated", 143) };
  local $SIG{INT} = sub { $stop->("interrupted", 130) };
  local $SIG{HUP} = sub { $stop->("hangup", 129) };
  alarm($limit);
  waitpid($child, 0);
  my $status = $?;
  alarm(0);
  printf STDERR "census-large budget: %.2fs / %ds\n", time - $start, $limit;
  exit(($status & 127) ? 128 + ($status & 127) : ($status >> 8));
' "$@"
