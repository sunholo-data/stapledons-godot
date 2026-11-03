#!/bin/sh
deadline() { # deadline SECONDS CMD...: CMD's rc; 124 on expiry (TERM to its process group, KILL 5 s later)
  perl -e '
    my $s = shift; my $pid = fork; exit 125 unless defined $pid;
    if ($pid == 0) { setpgrp(0, 0); exec @ARGV; exit 127 }
    setpgrp($pid, $pid); my $hit = 0;
    $SIG{$_} = sub { kill "KILL", -$pid; exit 124 } for qw(TERM INT HUP);
    $SIG{ALRM} = sub { kill(($hit++ ? "KILL" : "TERM"), -$pid); alarm 5 };
    alarm $s; waitpid($pid, 0); my $rc = $?; alarm 0;
    exit($rc & 127 ? 128 + ($rc & 127) : $rc >> 8) unless $hit;
    my $t = time + 5; select(undef, undef, undef, 0.2) while kill(0, -$pid) && time < $t;
    kill "KILL", -$pid; exit 124;' "$@" < /dev/null
}
deadline "$@"
