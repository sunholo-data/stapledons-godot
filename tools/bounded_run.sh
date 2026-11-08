#!/bin/sh
# Portable polling supervisor; ownership is PID + actual ps birth token.
# This cannot contain an unobserved double fork between snapshots.
exec perl - "$0" "$@" 3<&0 <<'BOUNDED_PERL'

use strict;
use warnings;
use POSIX qw(:sys_wait_h);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC sleep);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use Errno qw(EAGAIN EWOULDBLOCK EINTR);
my $SCRIPT=shift @ARGV;
open STDIN,'<&',3 or die "stdin: $!"; POSIX::close(3);
my $entry=clock_gettime(CLOCK_MONOTONIC);
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub nap { sleep(0.01) }
sub nb { my ($h)=@_; fcntl($h,F_SETFL,fcntl($h,F_GETFL,0)|O_NONBLOCK) or die "nonblocking pipe: $!\n" }
my ($cancel,$cancel_at);
# Assignment replaces SIG_IGN inherited from a background shell, including INT.
for my $s (qw(HUP INT TERM)) { my $name=$s; $SIG{$s}=sub { if (!defined $cancel) {$cancel=$name; $cancel_at=now()} } }
sub write_file { my ($p,$s)=@_; open my $f,'>',$p or die "$p: $!\n"; print {$f} $s; close $f or die "$p: $!\n" }
my %helpers;
sub snapshot_once {
    my ($phase_end)=@_; my $end=now()+0.2; $end=$phase_end if defined($phase_end) && $phase_end<$end;
    die "inspection budget exhausted\n" if $end<=now()+0.04;
    # Reserve 40ms INSIDE this acquisition for KILL + WNOHANG collection.
    my $read_end=$end-0.04;
    for my $q (keys %helpers) {
        kill 'KILL',$q;
        while(now()<$end) { my $w=waitpid($q,WNOHANG); if ($w!=0) { delete $helpers{$q}; last } sleep(0.001) }
    }
    die "ps helper collection budget exhausted\n" if keys %helpers;
    pipe(my $r,my $w) or die "ps pipe: $!\n";
    pipe(my $er,my $ew) or die "ps stderr pipe: $!\n";
    my $p=fork(); die "ps fork: $!\n" unless defined $p;
    if (!$p) { setpgrp(0,0) or POSIX::_exit(126); $SIG{$_}='DEFAULT' for qw(HUP INT TERM); close $r; close $er; open STDOUT,'>&',$w; open STDERR,'>&',$ew; close $w; close $ew;
        $ENV{LC_ALL}='C'; exec 'ps','-axo','pid=,ppid=,pgid=,lstart=,stat=' or POSIX::_exit(127) }
    $helpers{$p}=1; close $w; close $ew; nb($r); nb($er); my ($buf,$st,$eof)=('',undef,0); my ($errbuf,$erreof)=('',0);
    my $read_error;
    while(now()<$read_end) {
        if (!defined($st) && waitpid($p,WNOHANG)==$p) { $st=$?; delete $helpers{$p} }
        my $positive=0;
        for my $stream ([$r,\$buf,\$eof],[$er,\$errbuf,\$erreof]) {
            next if ${$stream->[2]};
            my $n=sysread($stream->[0],my $b,65536);
            if (defined($n)) { if ($n>0) { ${$stream->[1]}.=$b; $positive=1 } else { ${$stream->[2]}=1 } }
            elsif (!$!{EAGAIN} && !$!{EWOULDBLOCK} && !$!{EINTR}) { $read_error="$!"; last }
        }
        last if $read_error;
        next if $positive; # bounded loop condition; drain available bytes now
        last if defined($st) && $eof && $erreof;
        my $left=$read_end-now(); last if $left<=0; $left=0.005 if $left>0.005;
        my $bits=''; vec($bits,fileno($r),1)=1 unless $eof; vec($bits,fileno($er),1)=1 unless $erreof;
        select($bits,undef,undef,$left);
    }
    close $r; close $er;
    if (!defined($st) && waitpid($p,WNOHANG)==$p) { $st=$?; delete $helpers{$p} }
    my $timedout=!$read_error && (!defined($st) || ($st==0 && (!$eof || !$erreof)));
    kill 'KILL',$p unless defined($st); # only this unreaped direct helper
    while (!defined($st) && now()<$end) {
        my $q=waitpid($p,WNOHANG);
        if ($q==$p) { $st=$?; delete $helpers{$p}; last } sleep(0.001);
    }
    # One final nonblocking probe: a scheduler delay may cross the loop end
    # after the direct child has exited. No sleep, retry loop or budget extension.
    if (!defined($st) && waitpid($p,WNOHANG)==$p) { $st=$?; delete $helpers{$p} }
    die "ps helper collection budget exhausted\n" unless defined($st);
    die "ps read error: $read_error\n" if $read_error;
    die "ps transient read/exit budget exceeded 200ms\n" if $timedout;
    die "ps execution failed rc=".($st & 127 ? 128+($st & 127) : $st>>8)." stderr=$errbuf\n" if defined($st) && $st!=0;
    die "ps read/exit budget exceeded 200ms (bytes=".length($buf).", eof=$eof, status=".(defined($st)?$st:'unreaped').")\n" unless defined($st) && $eof && $erreof;
    my %t;
    for my $l (split /\n/,$buf) {
        next unless $l=~/\S/; $l=~s/^\s+//; my @v=split /\s+/,$l;
        die "malformed ps identity row [$l]\n" unless @v==9 && $v[0]=~/^\d+$/ && $v[1]=~/^\d+$/ && $v[2]=~/^\d+$/ && $v[3]=~/^(Mon|Tue|Wed|Thu|Fri|Sat|Sun)$/ && $v[4]=~/^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)$/ && $v[5]=~/^\d+$/ && $v[6]=~/^\d\d:\d\d:\d\d$/ && $v[7]=~/^\d{4}$/ && $v[8]=~/^[A-Za-z?][A-Za-z0-9<>+\-]*$/;
        $t{$v[0]}={pid=>0+$v[0],ppid=>0+$v[1],pgid=>0+$v[2],birth=>join(' ',@v[3..7]),stat=>$v[8]};
    }
    die "ps self positive control absent\n" unless $t{$$};
    return \%t;
}
# Three attempts maximum; default600ms is shortened by every explicit phase.
sub snapshot {
    my ($end)=@_; my $limit=now()+0.6; $end=$limit if !defined($end) || $end>$limit;
    my $error="inspection budget exhausted\n";
    for my $attempt (1..3) {
        last if now()+0.045>=$end;
        my $t=eval { snapshot_once($end) }; return $t if $t;
        $error=$@; die $error unless $error=~/^ps transient read\/exit budget exceeded 200ms/;
    }
    die $error;
}
sub canceled_probe_timeout {
    my ($failure,$cancellation,$pending)=@_;
    return defined($cancellation) && !$pending && defined($failure) &&
        $failure=~/\Aps transient read\/exit budget exceeded 200ms\n?\z/;
}
sub equal { my ($a,$b)=@_; return $a && $b && $a->{pid}==$b->{pid} && $a->{birth} eq $b->{birth} }
sub alive { my ($a,$t)=@_; return equal($a,$t->{$a->{pid}}) && $t->{$a->{pid}}{stat}!~/Z/ }
sub normalized { my ($s)=@_; return $s & 127 ? 128+($s & 127) : $s>>8 }
sub usage { print STDERR "bounded-run: usage: bounded_run.sh N -- command [args ...]\n"; exit 2 }
# Internal shell relay: one held worker and an absolute independent deadline.
# Calling shells keep traps before spawn and collect only after the done marker.
if (@ARGV && $ARGV[0] eq '--signal') {
    shift; my ($file,$sig)=@ARGV; usage() unless defined($sig) && $sig=~/^(HUP|INT|TERM|KILL)$/;
    my $ok=eval { open my $f,'<',$file or die $!; my $s=<$f>//''; close $f;
        my ($pid,$birth)=split /\t/,$s,2; chomp $birth; my $t=snapshot();
        my $id={pid=>$pid,birth=>$birth}; kill($sig,$pid) if alive($id,$t); 1 };
    exit($ok?0:125);
}
if (@ARGV && $ARGV[0] eq '--barrier') {
    shift; my ($dir,$phase,$pid,$child)=@ARGV; usage() unless defined($pid) && -d $dir;
    write_file("$dir/$phase", "$pid".(defined($child)?"\t$child":"")."\n"); my $end=now()+3;
    while(now()<$end && !-f "$dir/$phase.release") { nap() }
    exit(-f "$dir/$phase.release"?0:125);
}
my $relay;
if (@ARGV && $ARGV[0] eq '--relay') { shift; $relay=shift; usage() unless defined($relay) && -d $relay }
my $secs=shift @ARGV; usage() unless defined($secs) && $secs=~/^[0-9]+$/ && $secs>0 && $secs<2147483647 && @ARGV>=2 && shift(@ARGV) eq '--' && length($ARGV[0]);
my $deadline=$entry+$secs;
if ($relay) {
    my ($pid,$id,$status); my $limit=$deadline+4; my $sent=0; my $reaped=0;
    eval {
        if (!defined($cancel)) {
            $pid=fork(); die "relay fork: $!" unless defined $pid;
            if (!$pid) {
                $ENV{BR_INNER_READY}="$relay/inner-ready";
                $ENV{BR_INNER_RELEASE}="$relay/inner-release";
                exec 'sh',$SCRIPT,$secs,'--',@ARGV or POSIX::_exit(127);
            }
        }
        while(defined($pid) && now()<$limit-0.2) {
            $limit=$cancel_at+4 if defined($cancel_at) && $cancel_at+4<$limit;
            if (!$id && -f "$relay/inner-ready") {
                open my $f,'<',"$relay/inner-ready" or die $!;
                my $line=<$f>//''; close $f; chomp $line;
                my ($inner,$birth,$command,$command_birth)=split /\t/,$line;
                my $t=snapshot($limit);
                $id={pid=>$inner,birth=>$birth};
                die "inner supervisor identity mismatch\n" unless $inner==$pid && alive($id,$t) && $t->{$pid}{ppid}==$$;
                die "inner held command identity mismatch\n" unless alive({pid=>$command,birth=>$command_birth},$t) && $t->{$command}{ppid}==$pid;
                # Publish readiness only after handlers AND actual inner worker
                # and held-command identities have been positively confirmed.
                write_file("$relay/ready.tmp","$$\t$t->{$$}{birth}\n");
                rename "$relay/ready.tmp","$relay/ready" or die "relay readiness: $!";
                write_file("$relay/inner-release",'G');
            }
            if (defined($cancel) && !$sent && $id) {
                # Before shell confirmation it safely terminates its unreaped
                # direct child. The private record preserves the requested
                # signal for the actual inner production supervisor.
                if (-f "$relay/pending-signal") {
                    open my $f,'<',"$relay/pending-signal" or die $!;
                    my $requested=<$f>//''; close $f; chomp $requested;
                    $cancel=$requested if $requested=~/^(HUP|INT|TERM)$/;
                }
                my $t=snapshot($limit); kill $cancel,$pid if alive($id,$t); $sent=1;
            }
            if(waitpid($pid,WNOHANG)==$pid) { $status=normalized($?); $reaped=1; last }
            nap();
        }
        if (defined($pid) && !defined($status)) {
            # Unreaped direct ownership is safe even before confirmation.
            kill 'KILL',$pid unless $reaped;
            $status=125; print STDERR "bounded-run: relay watchdog exceeded absolute deadline\n";
        }
        $status=128+($cancel eq 'HUP'?1:$cancel eq 'INT'?2:15) if defined $cancel;
        1;
    } or do { print STDERR "bounded-run: relay setup/inspection failure: $@"; $status=125; kill 'TERM',$pid if $pid && !$reaped };
    if($pid && !$reaped) { while(now()<$limit) { last if waitpid($pid,WNOHANG)!=0; nap() } }
    eval { write_file("$relay/done.tmp",($status//125)."\n"); rename "$relay/done.tmp","$relay/done" or die $! };
    exit($status//125);
}
my (%owned,%stopped,$root,$root_id,$original_status,$error,$release);
sub collect_root {
    return if !defined($root) || defined($original_status);
    if(waitpid($root,WNOHANG)==$root) { $original_status=$? }
}
sub reap_helpers {
    for my $p (keys %helpers) { delete $helpers{$p} if waitpid($p,WNOHANG)!=0 }
}
sub discover {
    my ($t)=@_; my %seed;
    for my $p (keys %owned) {
        if (equal($owned{$p},$t->{$p})) { $seed{$p}=1 }
        else { delete $owned{$p}; delete $stopped{$p} }
    }
    if($root_id && equal($root_id,$t->{$root})) { $seed{$root}=1; $owned{$root}=$t->{$root} }
    my $changed=1;
    while($changed) { $changed=0;
        for my $p (keys %$t) { next if $p==$$ || $helpers{$p} || $seed{$p};
            if ($seed{$t->{$p}{ppid}}) { $owned{$p}=$t->{$p}; $seed{$p}=1; $changed=1 }
        }
    }
}
sub signal_owned {
    my ($sig,$id,$end)=@_;
    my $t=snapshot($end); discover($t); # fresh identity before EVERY individual signal
    return unless alive($id,$t) && $id->{pid}!=$$ && !$helpers{$id->{pid}};
    kill $sig,$id->{pid};
    $stopped{$id->{pid}}=$id if $sig eq 'STOP';
    delete $stopped{$id->{pid}} if $sig eq 'CONT' || $sig eq 'KILL';
}
my $result;
eval {
    pipe(my $r,my $w) or die "handshake pipe: $!\n";
    $root=fork(); die "command fork: $!\n" unless defined $root;
    if (!$root) {
        close $w; $SIG{$_}='DEFAULT' for qw(HUP INT TERM ALRM PIPE);
        setpgrp(0,0) or POSIX::_exit(125);
        nb($r); my $hold=$deadline; my $go='';
        while(now()<$hold) { my $n=sysread($r,my $b,1); if(defined($n)) { $go=$b if $n; last } nap() }
        close $r; POSIX::_exit(125) unless $go eq 'G';
        delete @ENV{qw(BR_INNER_READY BR_INNER_RELEASE)};
        exec 'env',@ARGV or POSIX::_exit(127);
    }
    close $r; $release=$w;
    my $t=snapshot($deadline); $root_id=$t->{$root};
    die "held command identity absent\n" unless $root_id && $root_id->{ppid}==$$;
    $owned{$root}=$root_id;
    if (defined($ENV{BR_COMMAND_ID_DIR}) && -d $ENV{BR_COMMAND_ID_DIR}) {
        require JSON::PP; write_file("$ENV{BR_COMMAND_ID_DIR}/command-$root",JSON::PP::encode_json($root_id));
    }
    if (defined($ENV{BR_INNER_READY})) {
        my $file=$ENV{BR_INNER_READY};
        write_file("$file.tmp","$$\t$t->{$$}{birth}\t$root\t$root_id->{birth}\n");
        rename "$file.tmp",$file or die "inner ready rename: $!";
        while(now()<$deadline && !defined($cancel) && !-f $ENV{BR_INNER_RELEASE}) { nap() }
        die "inner release budget exhausted\n" if !defined($cancel) && !-f $ENV{BR_INNER_RELEASE};
    }
    # Handler was installed before fork; a pending cancellation never releases exec.
    if (!defined $cancel) { syswrite($release,'G',1)==1 or die "handshake write: $!\n" }
    close $release; undef $release;
    while(1) {
        last if defined($cancel);
        if(now()>=$deadline) { $cancel='TIMEOUT'; $cancel_at=$deadline; last }
        collect_root(); last if defined($original_status);
        my $scan=eval { snapshot($deadline+0.2) };
        if (!$scan) {
            my $failure=$@;
            if (canceled_probe_timeout($failure,$cancel,scalar keys %helpers)) {
                print STDERR "bounded-run: canceled inspection deferred: $failure";
                last; # Cleanup still requires fresh closure and verified absence.
            }
            die $failure;
        }
        $t=$scan; discover($t); reap_helpers(); nap();
    }
    $result= defined($cancel) ? ($cancel eq 'TIMEOUT'?142:128+($cancel eq 'HUP'?1:$cancel eq 'INT'?2:15)) : normalized($original_status);
    1;
} or do { $error=$@; $result=125; close $release if $release; undef $release };
my $cleanup_start=now();
my $cleanup_end=defined($cancel_at)?$cancel_at+3:$cleanup_start+3;
my $reported_cancel=$cancel;
print STDERR "bounded-run: timeout after $secs s\n" if defined($cancel) && $cancel eq 'TIMEOUT';
print STDERR "bounded-run: interrupted by $cancel\n" if defined($cancel) && $cancel ne 'TIMEOUT';
print STDERR "bounded-run: inspection/setup failure: $error" if $error;
# Stop ancestors before refreshing closure. Retained records survive reparenting.
my $cleanup_error;
eval {
    my $t;
    # Freeze/discovery is optional after its bounded phase; verification is not.
    my $freeze_ok=eval {
    my $final_end=$cleanup_start+0.25; $final_end=$cleanup_end if $cleanup_end<$final_end;
    $t=snapshot($final_end); discover($t);
    my %depth;
    for my $id (values %owned) { my $p=$id->{pid}; my $d=0; my %seen;
        while ($t->{$p} && $owned{$p} && !$seen{$p}++) { $d++; $p=$t->{$p}{ppid} }
        $depth{$id->{pid}}=$d;
    }
    my @queue=sort { $depth{$a->{pid}}<=>$depth{$b->{pid}} } values %owned;
    for my $id (@queue) { last if now()>=$final_end; signal_owned('STOP',$id,$final_end) }
    while(now()+0.025<$final_end) {
        $t=snapshot($final_end); discover($t);
        my @new=grep {!$stopped{$_->{pid}} && alive($_,$t)} values %owned;
        last unless @new;
        for my $id (@new) { last if now()>=$final_end; signal_owned('STOP',$id,$final_end) }
    }
    1;
    };
    if (!$freeze_ok) {
        my $freeze_error=$@;
        die $freeze_error unless $freeze_error=~/\A(?:ps transient read\/exit budget exceeded 200ms|inspection budget exhausted)/;
        print STDERR "bounded-run: freeze inspection deferred: $freeze_error";
    }
    # Even after a deferred freeze, refresh native closure before any TERM.
    $t=snapshot($cleanup_end); discover($t);
    for my $id (values %owned) {
        last if now()>=$cleanup_end; signal_owned('TERM',$id,$cleanup_end);
        signal_owned('CONT',$id,$cleanup_end) if now()<$cleanup_end;
    }
    my $grace=now()+0.5; $grace=$cleanup_end-0.35 if $grace>$cleanup_end-0.35;
    while(now()<$grace) { collect_root(); reap_helpers(); $t=snapshot($cleanup_end); discover($t); last unless grep {alive($_,$t)} values %owned; nap() }
    for my $id (values %owned) { last if now()>=$cleanup_end; signal_owned('KILL',$id,$cleanup_end) }
    my $survivors=1;
    while(now()+0.025<$cleanup_end) { collect_root(); reap_helpers(); $t=snapshot($cleanup_end); discover($t);
        $survivors=scalar grep {alive($_,$t)} values %owned; last if !$survivors && !keys(%helpers) && defined($original_status); nap() }
    die "living owned process at cleanup deadline\n" if $survivors;
    1;
} or do { $cleanup_error=$@; $result=125 };
# On an inspection error, never leave a previously stopped identity frozen.
# Each emergency signal still requires its own fresh identity observation.
my @recovery=$cleanup_error ? values(%owned) : values(%stopped);
for my $id (@recovery) {
    my @signals=$cleanup_error ? qw(TERM CONT KILL) : qw(CONT KILL);
    for my $sig (@signals) { last if now()>=$cleanup_end; eval { signal_owned($sig,$id,$cleanup_end) } }
}
# A held unreaped direct child can safely be killed even when ps is unavailable.
if($root && !defined($original_status)) { kill 'KILL',$root; }
for my $p (keys %helpers) { kill 'KILL',$p }
while(now()<$cleanup_end && (keys(%helpers) || ($root && !defined($original_status)))) { collect_root(); reap_helpers(); nap() }
print STDERR "bounded-run: interrupted by $cancel\n" if defined($cancel) && !defined($reported_cancel) && $cancel ne 'TIMEOUT';
if (defined($cancel) && !$error && !$cleanup_error) {
    $result=$cancel eq 'TIMEOUT'?142:128+($cancel eq 'HUP'?1:$cancel eq 'INT'?2:15);
}
print STDERR "bounded-run: cleanup failure: $cleanup_error" if $cleanup_error;
exit($result//125);

BOUNDED_PERL
