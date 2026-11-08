#!/usr/bin/env perl
# Independent row-7ad guardian. It never uses the candidate as its watchdog.
use strict;
use warnings;
use POSIX qw(:sys_wait_h setsid);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC sleep);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use Errno qw(EAGAIN EWOULDBLOCK EINTR);
use Config;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Copy qw(copy);
use Cwd qw(abs_path);
use JSON::PP;
use Digest::SHA qw(sha256_hex);
my $SELF = abs_path($0);
my $PERL = -x $^X ? abs_path($^X) : $Config{perlpath};
die "absolute Perl interpreter unavailable" unless defined($PERL) && $PERL =~ m{^/} && -x $PERL;
my %PS_HELPERS;
sub reap_ps { for my $p (keys %PS_HELPERS) { delete $PS_HELPERS{$p} if waitpid($p,WNOHANG)!=0 } }
sub readable_until {
    my ($r,$end,$eof)=@_; my $left=$end-now(); return if $left<=0;
    $left=0.005 if $left>0.005;
    my $bits=''; vec($bits,fileno($r),1)=1 unless $eof;
    select($bits,undef,undef,$left);
}
our ($ROOT, $ART, $MODE, $GUARDIAN, $SENTINEL, $TOKEN);
$ART=$ENV{BR_ART} if defined $ENV{BR_ART};
my @CASES;
my $JSON = JSON::PP->new->canonical->pretty;
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub pause { sleep(0.015) }
sub put { my ($p,$s)=@_; open my $f,'>',$p or die "$p: $!"; print {$f} $s; close $f or die "$p: $!" }
sub get { my ($p)=@_; open my $f,'<',$p or return ''; local $/; return <$f> // '' }
sub save { put("$ART/results.json",$JSON->encode({mode=>$MODE, artifacts=>$ART,
    head=>get("$ART/head.txt"), worker_cap_fired=>JSON::PP::false,
    inspection_restricted=>JSON::PP::false, void_fixture=>JSON::PP::false, cases=>\@CASES})) }
sub norm { my ($s)=@_; return $s & 127 ? 128+($s & 127) : $s >> 8 }
sub nb { my ($f)=@_; fcntl($f,F_SETFL,fcntl($f,F_GETFL,0)|O_NONBLOCK) or die "nonblock: $!" }
# The only host inspection: actual numeric identities, five lstart tokens, state.
# Both the reader and helper wait have an absolute bound; never read command lines.
sub table {
    my ($end)=@_; $end = now()+0.2 if !defined($end) || $end > now()+0.2;
    pipe(my $r,my $w) or die "inspection_restricted: pipe";
    my $p=fork(); die "inspection_restricted: fork" unless defined $p;
    reap_ps();
    if (!$p) { close $r; open STDOUT,'>&',$w; open STDERR,'>',"$ART/ps-$$.err"; close $w;
        $ENV{LC_ALL}='C'; exec '/bin/ps','-axo','pid=,ppid=,pgid=,lstart=,stat=' or POSIX::_exit(127) }
    $PS_HELPERS{$p}=1;
    close $w; nb($r); my ($buf,$st,$eof)=('',undef,0); my $read_error;
    while (now()<$end) {
        if (!defined($st) && waitpid($p,WNOHANG)==$p) { $st=$?; delete $PS_HELPERS{$p} }
        if (!$eof) {
            my $n=sysread($r,my $b,65536);
            if (defined($n)) { if ($n>0) { $buf.=$b; next } $eof=1 }
            elsif (!$!{EAGAIN} && !$!{EWOULDBLOCK} && !$!{EINTR}) { $read_error="$!"; last }
        }
        last if defined($st) && $eof;
        readable_until($r,$end,$eof);
    }
    close $r;
    if (!defined($st) && waitpid($p,WNOHANG)==$p) { $st=$?; delete $PS_HELPERS{$p} }
    kill 'KILL',$p unless defined($st); # only our unreaped direct helper
    reap_ps();
    my $detail=get("$ART/ps-$p.err");
    die "inspection_restricted: ps read error: $read_error\n" if $read_error;
    die "inspection_restricted: ps execution rc=".norm($st)." stderr=$detail\n" if defined($st) && $st!=0;
    die "inspection_restricted: ps read/exit budget exceeded 200ms (bytes=".length($buf).", eof=$eof, status=".(defined($st)?$st:'unreaped').")\n" unless defined($st) && $eof;
    return parse_actual_table($buf);
}
sub parse_actual_table {
    my ($buf)=@_; my %t;
    for my $l (split /\n/,$buf) {
        next unless $l =~ /\S/;
        my @v=split /\s+/, $l =~ s/^\s+//r;
        die "inspection_restricted: malformed actual ps row [$l]\n" unless @v==9 && $v[0]=~/^\d+$/ && $v[1]=~/^\d+$/ && $v[2]=~/^\d+$/ && $v[3]=~/^(Mon|Tue|Wed|Thu|Fri|Sat|Sun)$/ && $v[4]=~/^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)$/ && $v[5]=~/^\d+$/ && $v[6]=~/^\d\d:\d\d:\d\d$/ && $v[7]=~/^\d{4}$/ && $v[8]=~/^[A-Za-z?][A-Za-z0-9<>+\-]*$/;
        $t{$v[0]}={pid=>0+$v[0],ppid=>0+$v[1],pgid=>0+$v[2],birth=>join(' ',@v[3..7]),stat=>$v[8]};
    }
    die "inspection_restricted: no self identity\n" unless $t{$$};
    return \%t;
}
sub controlled_table {
    my $t=table(@_);
    for my $p ($GUARDIAN,$SENTINEL) { die "inspection_restricted: guardian/sentinel positive control\n" unless $t->{$p} && $t->{$p}{stat}!~/Z/ }
    return $t;
}
sub matches { my ($a,$b)=@_; return $a && $b && $a->{pid}==$b->{pid} && $a->{birth} eq $b->{birth} }
sub live { my ($a,$t)=@_; return matches($a,$t->{$a->{pid}}) && $t->{$a->{pid}}{stat}!~/Z/ }
sub signal_id { my ($sig,$id,$end)=@_; my $t=controlled_table($end); return 0 unless live($id,$t); return kill $sig,$id->{pid} }
# Validate only against a controlled snapshot acquired AFTER reading the request.
# The preceding polling snapshot can predate the requesting child's birth.
sub registration_reason {
    my ($r,$file,$tab,$wid,$registered)=@_;
    return 'authentication/nonce mismatch' unless defined($r->{token}) && $r->{token} eq $TOKEN && defined($r->{nonce}) && $file eq "$r->{nonce}.req";
    my $par=$tab->{$r->{ppid}};
    return 'parent absent in fresh snapshot' unless $par;
    return 'parent birth mismatch' unless defined($r->{parent_birth}) && $par->{birth} eq $r->{parent_birth};
    return 'parent not live' if $par->{stat}=~/Z/;
    my $child=$tab->{$r->{pid}};
    return 'request identity absent/birth mismatch' unless matches($r,$child);
    return 'request identity not live' if $child->{stat}=~/Z/;
    return 'live parent relation mismatch' unless $child->{ppid}==$r->{ppid};
    my $ownedparent=matches($wid,$par) || grep { matches($_,$par) } values %$registered;
    my $ancestor=$par; my %seen;
    while ($ancestor && !$seen{$ancestor->{pid}}++) {
        $ownedparent ||= matches($wid,$ancestor);
        $ancestor=$tab->{$ancestor->{ppid}};
    }
    return 'parent outside owned ancestry' unless $ownedparent;
    return undef;
}
sub registration_snapshot {
    my ($r,$file,$end,$wid,$registered)=@_;
    my $fresh=controlled_table($end);
    my $reason=registration_reason($r,$file,$fresh,$wid,$registered);
    if (defined($reason)) {
        put("$ART/registration-refusal.txt",$JSON->encode({reason=>$reason,request=>$r,
            guardian=>$fresh->{$GUARDIAN},sentinel=>$fresh->{$SENTINEL},worker=>$fresh->{$wid->{pid}},
            child=>$fresh->{$r->{pid}},parent=>$fresh->{$r->{ppid}}}));
        die "void_fixture: registration $reason\n";
    }
    return $fresh;
}
sub parent_exit_after {
    my ($value)=@_; return undef unless defined($value) && length($value);
    die "void_fixture: invalid parent lifetime\n" unless length($value)<=16 && $value=~/\A(?:[0-9]+(?:\.[0-9]+)?|\.[0-9]+)\z/ && $value>0;
    return 0+$value;
}
sub register_id {
    my ($dir,$label)=@_; my $t=controlled_table(); my $id=$t->{$$}; my $par=$t->{getppid()} or die "void_fixture: parent absent";
    my $nonce=join('-', $$,int(rand(1e9)), $label);
    my $req={%$id,parent_birth=>$par->{birth},nonce=>$nonce,token=>$TOKEN};
    put("$dir/$nonce.tmp",$JSON->encode($req)); rename "$dir/$nonce.tmp","$dir/$nonce.req" or die $!;
    my $end=now()+2;
    while(now()<$end) { return $id if -f "$dir/$nonce.ack"; pause() }
    die "void_fixture: registration not acknowledged\n";
}
sub finite_hold { my ($end)=@_; pause() while now()<$end }
sub fixture {
    my $entry=now();
    my ($dir,$kind,$ready)=@_; $GUARDIAN=$ENV{BR_GUARDIAN}; $SENTINEL=$ENV{BR_SENTINEL}; $TOKEN=$ENV{BR_TOKEN};
    $|=1; my $end=$entry+18;
    register_id($dir,'parent');
    my $c=fork(); die "fixture fork" unless defined $c;
    if (!$c) {
        register_id($dir,'child'); setsid() if $kind ne 'same';
        $SIG{$_}='IGNORE' for qw(HUP INT TERM ALRM);
        put("$ready.child",$JSON->encode(controlled_table()->{$$}));
        finite_hold($end); POSIX::_exit(0);
    }
    my $ce=now()+2; pause() while !-f "$ready.child" && now()<$ce;
    die "void_fixture: child readiness" unless -f "$ready.child";
    put($ready,$JSON->encode(controlled_table()->{$$}));
    print "drill: 1 passed, 0 failures\ncrew-console: 0 failures\n";
    if ($kind eq 'parentexit') {
        my $e=now()+3; pause() while !-f "$ready.release" && now()<$e;
        POSIX::_exit(7);
    }
    $SIG{$_}='IGNORE' for qw(HUP INT ALRM);
    $SIG{TERM}='IGNORE' unless $kind eq 'parentfirst';
    my $early=parent_exit_after($ENV{BR_PARENT_EXIT_AFTER});
    if (defined($early)) { finite_hold($entry+$early); POSIX::_exit(0) }
    finite_hold($end); POSIX::_exit(0);
}
if (@ARGV && $ARGV[0] eq '__registration_probe') {
    shift @ARGV; ($GUARDIAN,$SENTINEL,$TOKEN)=@ENV{qw(BR_GUARDIAN BR_SENTINEL BR_TOKEN)};
    register_id($ARGV[0],'fresh-after-snapshot'); exit 0;
}
if (@ARGV && $ARGV[0] eq '__fixture') { shift @ARGV; fixture(@ARGV); exit 0 }
# This escaped command tree registers with the OUTER control guardian only.
# The inner guard must discover/retain it from actual ancestry, without those
# registrations. Both processes have finite backup lifetimes.
sub guard_tree {
    my ($dir,$ready)=@_;
    ($GUARDIAN,$SENTINEL,$TOKEN)=@ENV{qw(BR_CONTROL_GUARDIAN BR_CONTROL_SENTINEL BR_CONTROL_TOKEN)};
    my $end=now()+10; register_id($dir,'arbitrary-parent');
    my $c=fork(); die 'tree fork' unless defined $c;
    if (!$c) { register_id($dir,'arbitrary-child'); setsid();
        $SIG{$_}='IGNORE' for qw(HUP INT TERM ALRM);
        put("$ready.child",$JSON->encode(controlled_table()->{$$})); finite_hold($end); POSIX::_exit(0) }
    my $e=now()+2; pause() while !-f "$ready.child" && now()<$e;
    die 'void_fixture: arbitrary child not ready' unless -f "$ready.child";
    put($ready,$JSON->encode(controlled_table()->{$$}));
    $SIG{$_}='IGNORE' for qw(HUP INT TERM ALRM); finite_hold($end); POSIX::_exit(0);
}
if (@ARGV && $ARGV[0] eq '__guard_tree') { shift @ARGV; guard_tree(@ARGV); exit 0 }
sub case_result {
    my (%c)=@_; $c{passed}=$c{passed}?JSON::PP::true:JSON::PP::false;
    $c{guardian_cap_fired}=JSON::PP::false unless exists $c{guardian_cap_fired};
    $c{inspection_restricted}//=JSON::PP::false; $c{void_fixture}//=JSON::PP::false;
    $c{pre_identities}//=[]; $c{post_identities}//=[]; $c{inner_make_rc}//=undef;
    push @CASES,\%c; save(); return \%c;
}
# Candidate execution is bounded independently, including all red/mutant cases.
sub run_command {
    my ($name,$cap,$argv,$trigger,$input)=@_;
    my $t0=now(); my $end=$t0+$cap; my $out="$ART/$name.out"; my $err="$ART/$name.err";
    put("$ART/$name.stdin",$input//'');
    my $p=fork(); die "command fork" unless defined $p;
    if (!$p) { $SIG{$_}='DEFAULT' for qw(HUP INT TERM ALRM);
        eval { register_id($ENV{BR_REG_DIR},'command'); 1 } or do { put("$ART/$name.inspection-restricted",$@); POSIX::_exit(3) };
        setpgrp(0,0) unless $MODE eq 'guard';
        open STDOUT,'>',$out; open STDERR,'>',$err; open STDIN,'<',"$ART/$name.stdin";
        chdir $ROOT or POSIX::_exit(126); exec @$argv or POSIX::_exit(127) }
    my ($st,$fired,$trig)=(undef,0,undef);
    while(now()<$end) {
        if ($trigger) { my $v=$trigger->($p,$t0); if (ref($v) eq 'HASH') { $end=$v->{deadline} if $v->{deadline}<$end } elsif (defined($v) && !defined($trig)) { $trig=$v; $end=$trig+4 if $trig+4<$end } }
        my $q=waitpid($p,WNOHANG); if ($q==$p) { $st=$?; last } pause();
    }
    if (!defined $st) { $fired=1; kill 'KILL',$p; my $e=now()+0.15; while(now()<$e) { if(waitpid($p,WNOHANG)==$p) {$st=$?;last} pause() } }
    die 'inspection_restricted: command registration: '.get("$ART/$name.inspection-restricted") if -f "$ART/$name.inspection-restricted";
    return {actual_rc=>defined($st)?norm($st):124, elapsed=>now()-$t0,
        guardian_cap_fired=>$fired?JSON::PP::true:JSON::PP::false,stdout=>get($out),stderr=>get($err),trigger_at=>$trig};
}
sub clean_ids {
    my ($ids,$absolute)=@_; return 'no_live_registered_survivors' unless @$ids; my $end=now()+2.8; $end=$absolute if defined($absolute) && $absolute<$end;
    for my $id (reverse @$ids) { last if now()>$end; signal_id('KILL',$id,$end) }
    while(now()<$end) { my $t=controlled_table($end); return 'no_live_registered_survivors' unless grep { live($_,$t) } @$ids; pause() }
    return 'live_registered_survivors';
}
sub guard_worker {
    my ($cap,@cmd)=@_; my $r=run_command('guard-command',$cap,\@cmd);
    print STDOUT $r->{stdout}; print STDERR $r->{stderr};
    case_result(name=>'guard-command',%$r,passed=>!$r->{guardian_cap_fired},trigger=>'command',cleanup_outcome=>'guardian_cleanup_pending');
    return $r->{guardian_cap_fired}?124:$r->{actual_rc};
}
sub fixture_ids {
    my ($ready)=@_; return [] unless -f $ready && -f "$ready.child";
    return [decode_json(get($ready)),decode_json(get("$ready.child"))];
}
sub guardian_positive {
    local $ENV{BR_PARENT_EXIT_AFTER}=''; # ordinary empty environment must keep parent live
    my $ready="$ART/guardian-positive.ready"; my $pre=[]; my $obs=0;
    my $r=run_command('guardian-positive',4,[$PERL,$SELF,'__fixture',$ENV{BR_REG_DIR},'parentfirst',$ready],sub {
        $pre=fixture_ids($ready); return undef unless @$pre;
        my $t=controlled_table(); $obs++ if !grep {!live($_,$t)} @$pre;
        if ($obs>=2) { signal_id('TERM',$pre->[0]); return now() } return undef;
    });
    my $t=controlled_table(); my $ok=@$pre==2 && $obs>=2 && $pre->[0]{pgid}!=$pre->[1]{pgid} && live($pre->[1],$t);
    my $c=case_result(name=>'guardian-positive-identities',%$r,passed=>$ok,trigger=>'two real identity observations; escaped child survives parent TERM',pre_identities=>$pre,post_identities=>[map {$t->{$_->{pid}}//{}} @$pre],cleanup_outcome=>'pending');
    $c->{cleanup_outcome}=clean_ids($pre); save();
}
sub parser_controls {
    my $actual=controlled_table();
    my $render=sub { my ($t)=@_; return join('',map {my $r=$t->{$_}; join(' ',@$r{qw(pid ppid pgid birth stat)})."\n"} sort {$a<=>$b} keys %$t) };
    my $raw=$render->($actual); put("$ART/actual-ps-table.txt",$raw);
    my $parsed=parse_actual_table($raw);
    my $positive=matches($actual->{$GUARDIAN},$parsed->{$GUARDIAN}) && matches($actual->{$SENTINEL},$parsed->{$SENTINEL});
    case_result(name=>'guardian-parser-actual',actual_rc=>0,passed=>$positive,trigger=>'generated actual ps table with two positive controls',elapsed=>0,cleanup_outcome=>'no_live_registered_survivors');
    # Controller's actual native capture; metadata only, NEVER a signal target.
    # Apple adv_cmds 6bed8737a34dbb54782a18f47dccf933a9967a12:
    # tasks.c:48 mach_state_table=" RUSITH?"; print.c:478 emits that state.
    my $captured='19539 18976 18976 Sun Nov 8 06:03:58 2026 ?';
    my %without=%$actual; delete $without{19539};
    my $capture_table=parse_actual_table($render->(\%without).$captured."\n");
    my $capture=$capture_table->{19539};
    case_result(name=>'guardian-parser-native-unknown-capture',actual_rc=>0,
        passed=>$capture && $capture->{stat} eq '?' && $capture->{birth} eq 'Sun Nov 8 06:03:58 2026' && live($capture,$capture_table),
        trigger=>'actual captured unknown state stays possibly live; metadata only',elapsed=>0,cleanup_outcome=>'no_live_registered_survivors',captured_row=>$captured,
        provenance=>'/tmp/iter80-M1-r2-check/7ad-6EIiSCXH/results.json');
    for my $state ('?','?>','?s','R>','S<+','Ss+') {
        my %variant=%$actual; $variant{$$}={%{$actual->{$$}},stat=>$state};
        my $t=parse_actual_table($render->(\%variant));
        case_result(name=>"guardian-parser-native-flags-$state",actual_rc=>0,
            passed=>matches($actual->{$$},$t->{$$}) && $t->{$$}{stat} eq $state && live($t->{$$},$t),
            trigger=>'native state/flags applied only to current actual row; > is documented ps flag',elapsed=>0,cleanup_outcome=>'no_live_registered_survivors');
    }
    my @changes=(['pid',0,'bad'],['ppid',1,'bad'],['pgid',2,'bad'],['weekday',3,'bad'],['month',4,'bad'],['day',5,'bad'],['clock',6,'bad'],['year',7,'bad'],['state',8,'!']);
    for my $m (@changes) {
        my @lines=split /\n/,$raw; my @v=split /\s+/,$lines[0]; $v[$m->[1]]=$m->[2]; $lines[0]=join(' ',@v);
        my $bad=join("\n",@lines)."\n"; put("$ART/ps-refusal-$m->[0].txt",$bad);
        my $accepted=eval {parse_actual_table($bad);1};
        case_result(name=>"guardian-parser-refuse-$m->[0]",actual_rc=>$accepted?0:125,passed=>!$accepted,trigger=>'corrupted field of actual ps output',elapsed=>0,cleanup_outcome=>'no_live_registered_survivors');
    }
    for my $which ('self','guardian','sentinel','empty','field-count') {
        my %copy=%$actual;
        delete $copy{$which eq 'self'?$$:$which eq 'guardian'?$GUARDIAN:$SENTINEL};
        my @lines=split /\n/,$raw; my @fields=split /\s+/,$lines[0]; pop @fields; $lines[0]=join(' ',@fields);
        my $bad=$which eq 'empty'?'':$which eq 'field-count'?join("\n",@lines)."\n":$render->(\%copy);
        my $accepted=eval { my $t=parse_actual_table($bad); die 'positive control absent' unless $t->{$GUARDIAN} && $t->{$SENTINEL}; 1 };
        case_result(name=>"guardian-parser-refuse-$which",actual_rc=>$accepted?0:125,passed=>!$accepted,trigger=>'actual table positive-control/shape refusal',elapsed=>0,cleanup_outcome=>'no_live_registered_survivors');
    }
}
sub registration_controls {
    my $dir="$ART/fresh-registration"; make_path($dir);
    my $old=controlled_table(); my $wid=$old->{$$}; my $checked=0;
    my $result=run_command('registration-fresh-probe',4,[$PERL,$SELF,'__registration_probe',$dir],sub {
        return undef if $checked;
        opendir my $d,$dir or die $!; my @req=grep {/\.req$/} readdir $d; closedir $d;
        return undef unless @req;
        my $file=$req[0]; my $r=decode_json(get("$dir/$file"));
        my $fresh=registration_snapshot($r,$file,now()+0.2,$wid,{});
        my $stale=registration_reason($r,$file,$old,$wid,{});
        case_result(name=>'guardian-registration-after-snapshot',actual_rc=>0,
            passed=>!$old->{$r->{pid}} && defined($stale) && !defined(registration_reason($r,$file,$fresh,$wid,{})),
            trigger=>'actual requesting child born after old table; fresh controlled table before ACK',elapsed=>0,cleanup_outcome=>'no_live_registered_survivors');
        my @changes=(['authentication/nonce mismatch','token','wrong'],['authentication/nonce mismatch','nonce','wrong'],
            ['parent birth mismatch','parent_birth','wrong'],['request identity absent/birth mismatch','birth','wrong'],
            ['parent absent in fresh snapshot','ppid',0]);
        for my $i (0..$#changes) {
            my ($why,$field,$value)=@{$changes[$i]}; my %bad=%$r; $bad{$field}=$value;
            my $accepted=eval { registration_snapshot(\%bad,$file,now()+0.2,$wid,{}); 1 }; my $error=$@;
            my $evidence=decode_json(get("$ART/registration-refusal.txt"));
            my $reason=$evidence->{reason};
            case_result(name=>"guardian-registration-refuse-$field",actual_rc=>$accepted?0:3,
                passed=>!$accepted && $error=~/^void_fixture: registration/ && $reason eq $why &&
                    matches($fresh->{$GUARDIAN},$evidence->{guardian}) && matches($fresh->{$SENTINEL},$evidence->{sentinel}),
                trigger=>'one-field corruption of actual private request',elapsed=>0,cleanup_outcome=>'no_live_registered_survivors');
        }
        for my $which (qw(parent-zombie child-zombie relation ancestry)) {
            my %tab=map { $_=>{%{$fresh->{$_}}} } keys %$fresh; my $root=$wid;
            $tab{$r->{ppid}}{stat}='Z' if $which eq 'parent-zombie';
            $tab{$r->{pid}}{stat}='Z' if $which eq 'child-zombie';
            $tab{$r->{pid}}{ppid}=0 if $which eq 'relation';
            $root=$fresh->{$SENTINEL} if $which eq 'ancestry';
            my %why=('parent-zombie'=>'parent not live','child-zombie'=>'request identity not live',
                relation=>'live parent relation mismatch',ancestry=>'parent outside owned ancestry');
            my $reason=registration_reason($r,$file,\%tab,$root,{});
            case_result(name=>"guardian-registration-refuse-$which",actual_rc=>defined($reason)?3:0,passed=>defined($reason) && $reason eq $why{$which},
                trigger=>'metadata-only alteration of fresh actual identities; never signalled',elapsed=>0,cleanup_outcome=>'no_live_registered_survivors');
        }
        put("$dir/$r->{nonce}.ack",'ack'); $checked=1; return undef;
    });
    case_result(name=>'guardian-registration-probe-completes',%$result,passed=>$checked && $result->{actual_rc}==0 && !$result->{guardian_cap_fired},
        trigger=>'fresh valid requesting process released only after validation and ACK',cleanup_outcome=>'no_live_registered_survivors');
}
sub lifetime_controls {
    for my $test (['empty','',undef],['unset',undef,undef],['configured','4.8',4.8]) {
        my $value=parent_exit_after($test->[1]);
        case_result(name=>"guardian-parent-lifetime-$test->[0]",actual_rc=>0,
            passed=>defined($test->[2]) ? defined($value) && $value==$test->[2] : !defined($value),
            trigger=>'same lifetime selector used before fixture finite early exit; ordinary fallback remains 18s',elapsed=>0,cleanup_outcome=>'no_live_registered_survivors');
    }
    for my $bad ('0','-1','bad','NaN','Inf','1e999') {
        my $accepted=eval { parent_exit_after($bad); 1 };
        case_result(name=>"guardian-parent-lifetime-refuse-$bad",actual_rc=>$accepted?0:3,passed=>!$accepted,
            trigger=>'invalid configured finite early-exit lifetime',elapsed=>0,cleanup_outcome=>'no_live_registered_survivors');
    }
}
sub guard_controls {
    lifetime_controls();
    registration_controls();
    for my $rc (0,7,142) {
        my $r=run_command("guard-status$rc",5,[$PERL,$SELF,'guard',$ROOT,$ART,2,'--','sh','-c',"exit $rc"]);
        case_result(name=>"guard-status$rc",%$r,passed=>$r->{actual_rc}==$rc,trigger=>'ordinary',cleanup_outcome=>'no_live_registered_survivors');
    }
    my $r=run_command('guard-signal',5,[$PERL,$SELF,'guard',$ROOT,$ART,2,'--',$PERL,'-e','kill "TERM",$$; select undef,undef,undef,1']);
    case_result(name=>'guard-signal',%$r,passed=>$r->{actual_rc}==143,trigger=>'child TERM',cleanup_outcome=>'no_live_registered_survivors');
    $r=run_command('guard-cap',5,[$PERL,$SELF,'guard',$ROOT,$ART,1,'--',$PERL,'-MTime::HiRes=clock_gettime,CLOCK_MONOTONIC,sleep','-e','my $e=clock_gettime(CLOCK_MONOTONIC)+10; sleep .02 while clock_gettime(CLOCK_MONOTONIC)<$e']);
    case_result(name=>'guard-cap',%$r,passed=>$r->{actual_rc}==124 && !$r->{guardian_cap_fired} && $r->{elapsed}<4 && $r->{stderr}=~/bounded-guard: cap/,trigger=>'independent cap',cleanup_outcome=>'no_live_registered_survivors');
    {
        local $ENV{BR_CONTROL_GUARDIAN}=$GUARDIAN; local $ENV{BR_CONTROL_SENTINEL}=$SENTINEL; local $ENV{BR_CONTROL_TOKEN}=$TOKEN;
        my $ready="$ART/general-tree.ready"; my $ids=[]; my $observations=0;
        my $tree=run_command('guard-general-tree',6,[$PERL,$SELF,'guard',$ROOT,$ART,2,'--',$PERL,$SELF,'__guard_tree',$ENV{BR_REG_DIR},$ready],sub {
            $ids=fixture_ids($ready); if (@$ids==2) { my $t=controlled_table(); $observations++ unless grep {!live($_,$t)} @$ids } return undef;
        });
        my $post=controlled_table(); my $ok=@$ids==2 && $observations>=2 && $ids->[0]{pgid}!=$ids->[1]{pgid} && !grep {live($_,$post)} @$ids;
        $ok &&=$tree->{actual_rc}==124 && !$tree->{guardian_cap_fired} && $tree->{stderr}=~/bounded-guard: cap/;
        my $c=case_result(name=>'guard-general-descendants',%$tree,passed=>$ok,trigger=>'independent cap with arbitrary observed setsid descendants',pre_identities=>$ids,post_identities=>[map {$post->{$_->{pid}}//{pid=>$_->{pid},absent=>JSON::PP::true}} @$ids],cleanup_outcome=>'pending');
        $c->{cleanup_outcome}=clean_ids($ids); save();
    }
    {
        my $ready="$ART/guard-cancel.ready"; my ($trigger,$rootid); my @ids;
        my $code='open my $f,">",shift or die $!; print {$f} "$$\\n"; close $f; my $e=clock_gettime(CLOCK_MONOTONIC)+10; sleep .02 while clock_gettime(CLOCK_MONOTONIC)<$e;';
        my $r=run_command('guard-cancel',6,[$PERL,$SELF,'guard',$ROOT,$ART,10,'--',$PERL,'-MTime::HiRes=clock_gettime,CLOCK_MONOTONIC,sleep','-e',$code,$ready],sub {
            my ($pid)=@_; return undef if defined($trigger) || !-f $ready;
            my $t=controlled_table(); my $command=0+get($ready); return undef unless $t->{$command} && $t->{$pid};
            $rootid=$t->{$pid}; my %tree=($pid=>$rootid); my $more=1;
            while($more) { $more=0; for my $p (keys %$t) { next if $tree{$p}; if ($tree{$t->{$p}{ppid}}) { $tree{$p}=$t->{$p}; $more=1 } } }
            return undef unless $tree{$command}; @ids=values %tree;
            signal_id('TERM',$rootid); $trigger=now(); return $trigger;
        });
        my $post=controlled_table(); my $ok=defined($trigger) && $r->{actual_rc}==143 && !$r->{guardian_cap_fired} && now()-$trigger<=4 && !grep {live($_,$post)} @ids;
        my $c=case_result(name=>'guard-first-cancel-cleanup',%$r,passed=>$ok,trigger=>'direct guardian TERM after actual command readiness/ancestry',pre_identities=>\@ids,post_identities=>[map {$post->{$_->{pid}}//{pid=>$_->{pid},absent=>JSON::PP::true}} @ids],cleanup_outcome=>'pending');
        $c->{cleanup_outcome}=clean_ids(\@ids); save();
    }
    guardian_positive();
    parser_controls();
    make_path("$ART/deny-bin"); put("$ART/deny-bin/ps","#!/bin/sh\nexit 1\n"); chmod 0700,"$ART/deny-bin/ps";
    my $deny_source=get($SELF); my $deny_mut=$deny_source;
    $deny_mut =~ s{exec '/bin/ps','-axo'}{exec '$ART/deny-bin/ps','-axo'} or die 'denial mutation absent';
    put("$ART/denied-inspection.pl",$deny_mut);
    my $d=run_command('guard-denied-ps',3,[$PERL,"$ART/denied-inspection.pl",'guard',$ROOT,$ART,1,'--','sh','-c','exit 0']);
    case_result(name=>'guard-denied-ps',%$d,passed=>$d->{actual_rc}==3 && !$d->{guardian_cap_fired},trigger=>'private denied inspection copy',cleanup_outcome=>'no_live_registered_survivors');
    put("$ART/denied-inspection.pl",$deny_source); die 'denial restore cmp' unless get("$ART/denied-inspection.pl") eq $deny_source;
    put("$ART/slow-ps","#!/bin/sh\nexec '$PERL' -MTime::HiRes=sleep -e 'sleep 0.4'\n"); chmod 0700,"$ART/slow-ps";
    my $slow_source=get($SELF); my $slow_mut=$slow_source;
    $slow_mut =~ s{exec '/bin/ps','-axo'}{exec '$ART/slow-ps','-axo'} or die 'budget mutation absent';
    put("$ART/budget-inspection.pl",$slow_mut);
    my $slow=run_command('guard-ps-budget',3,[$PERL,"$ART/budget-inspection.pl",'guard',$ROOT,$ART,1,'--','sh','-c','exit 0']);
    case_result(name=>'guard-ps-budget',%$slow,passed=>$slow->{actual_rc}==3 && !$slow->{guardian_cap_fired} && $slow->{stderr}=~/read\/exit budget exceeded 200ms/,trigger=>'finite private ps helper exceeds unchanged 200ms budget',cleanup_outcome=>'no_live_registered_survivors');
    put("$ART/budget-inspection.pl",$slow_source); die 'budget restore cmp' unless get("$ART/budget-inspection.pl") eq $slow_source;
    # Normalize a real returned status incorrectly in a private copy, then reject it.
    my $source=get($SELF); my $mut=$source; $mut =~ s/return \$s & 127 \? 128\+\(\$s & 127\) : \$s >> 8/return 0/ or die 'normalization mutation absent';
    put("$ART/normalization-mutant.pl",$mut);
    $r=run_command('guard-normalization-mutant',4,[$PERL,"$ART/normalization-mutant.pl",'guard',$ROOT,$ART,2,'--','sh','-c','exit 7']);
    case_result(name=>'guard-normalization-control',%$r,passed=>$r->{actual_rc}==0 && !$r->{guardian_cap_fired},trigger=>'wrong normalization must be rejected',cleanup_outcome=>'no_live_registered_survivors');
    put("$ART/normalization-mutant.pl",$source); die 'restore cmp' unless get("$ART/normalization-mutant.pl") eq $source;
    return scalar(grep {!$_->{passed}} @CASES)?1:0;
}
my @FIXED = qw(
runner-exit0 runner-exit7 runner-exit142 runner-missing127 runner-child-term143
runner-transport runner-usage runner-timeout-same-group runner-timeout-escaped
runner-timeout-parent-first runner-hup runner-int runner-term runner-parent-exit7-retained
runner-first-signal-wins runner-inherited-ignored-int guardian-positive-identities
 gate-counted-pass gate-want1 gate-zero-reject gate-timeout-same-group
 rawmake-pass rawmake-rc7 rawmake-error rawmake-nosummary gate-timeout-escaped rawmake-summary-hang
 gate-relay-prereg-hup gate-relay-prereg-int gate-relay-prereg-term
 gate-relay-ready-hup gate-relay-ready-int gate-relay-ready-term
 raw-relay-prereg-hup raw-relay-prereg-int raw-relay-prereg-term
 raw-relay-ready-hup raw-relay-ready-int raw-relay-ready-term
 raw-make-group-hup raw-make-group-int raw-make-group-term);
sub simple_case {
    my ($name,$argv,$want,$pattern,$input)=@_; my $r=run_command($name,4,$argv,undef,$input);
    my $ok=$r->{actual_rc}==$want && !$r->{guardian_cap_fired};
    $ok &&= ($r->{stdout}.$r->{stderr}) =~ $pattern if defined $pattern;
    $ok &&= $r->{stderr}!~/timeout after/ if $name eq 'runner-exit142';
    case_result(name=>$name,%$r,passed=>$ok,trigger=>'ordinary',cleanup_outcome=>'no_live_registered_survivors');
}
sub make_stub {
    my ($dir)=@_; make_path($dir);
    put("$dir/ailang","#!/bin/sh\nexit 0\n"); chmod 0700,"$dir/ailang";
    # Stubs validate the real Make expansion; no test recipe or predicate copies.
    put("$dir/godot",<<'STUB');
#!/usr/bin/env perl
use strict; use warnings;
exit 0 if grep { $_ eq '--import' } @ARGV;
die "wrong AILANG_BIN" unless ($ENV{AILANG_BIN}//'') eq $ENV{BR_AILANG_STUB};
die "wrong crew script" unless grep { $_ eq 'tests/test_crew_console.gd' } @ARGV;
if ($ENV{BR_STUB_MODE} eq 'fixture') {
 exec $^X,$ENV{BR_HARNESS},'__fixture',$ENV{BR_REG_DIR},$ENV{BR_FIX_KIND},$ENV{BR_READY}; die $!;
}
print "SCRIPT ERROR: deliberate stub error\n" if $ENV{BR_STUB_MODE} eq 'error';
print "crew-console: 0 failures\n" unless $ENV{BR_STUB_MODE} eq 'nosummary';
exit($ENV{BR_STUB_MODE} eq 'rc7'?7:0);
STUB
    chmod 0700,"$dir/godot"; return ("$dir/godot","$dir/ailang");
}
sub raw_argv {
    my ($dir)=@_; my ($g,$a)=make_stub($dir); $ENV{BR_AILANG_STUB}=$a; $ENV{BR_HARNESS}=$SELF;
    return ['make','--no-print-directory','-C',$ROOT,'crew-console-test',"GODOT=$g","AILANG=$a",'CREW_CONSOLE_TIMEOUT_S=2',"SCRATCH=$dir/scratch","SCRIPT_GATE=$dir/does-not-exist"];
}
sub fixture_case {
    my ($name,$type,$kind,$sig,$phase)=@_;
    my $dir="$ART/$name"; make_path($dir); my $ready="$dir/fixture.ready";
    local $ENV{BR_READY}=$ready; local $ENV{BR_FIX_KIND}=$kind; local $ENV{BR_STUB_MODE}='fixture';
    local $ENV{BR_RELAY_TEST_DIR}=defined($phase) && $phase ne 'group'?$dir:'';
    local $ENV{BR_PARENT_EXIT_AFTER}= $type eq 'raw'?3.0:undef;
    my $cmd=[$PERL,$SELF,'__fixture',$ENV{BR_REG_DIR},$kind,$ready];
    my $argv=$type eq 'runner'?['sh',"$ROOT/tools/bounded_run.sh",2,'--',@$cmd]
       :$type eq 'gate'?['sh',"$ROOT/tools/script_gate.sh",$name,"$dir/gate.log",2,'^drill: [1-9][0-9]* passed, 0 failures$',defined($sig)?128+(lc($sig) eq 'hup'?1:lc($sig) eq 'int'?2:15):0,'--',@$cmd]
       :raw_argv($dir);
    if ($name eq 'runner-inherited-ignored-int') {
        $argv=[$PERL,'-e','$SIG{INT}="IGNORE"; exec @ARGV',@$argv];
    }
    my %early; my $unconfirmed_child;
    my ($pre,$obs,$sent,$barrier,$target,$trigger_at,$release_at)=([],0,0,0,undef,undef,undef);
    my $candidate_barrier_seen=0;
    my $r=run_command($name,6,$argv,sub {
        my ($pid,$t0)=@_; my $t=controlled_table();
        if (defined($phase) && $phase ne 'group') {
            for my $hook (qw(prereg ready)) {
                next unless -f "$dir/$hook";
                $candidate_barrier_seen=1;
                # Advance past non-target hooks without waiting for identities;
                # the selected hook still requires two healthy observations.
                put("$dir/$hook.release",'release') if $hook ne $phase && !-f "$dir/$hook.release";
            }
        }
        my $ids=fixture_ids($ready);
        if(@$ids==2) { $pre=$ids; $obs++ if !grep {!live($_,$t)} @$ids }
        if ($kind eq 'parentexit' && $obs>=2 && !defined($release_at)) { put("$ready.release",'release'); $release_at=now() }
        if (defined($phase) && $phase eq 'prereg' && !$sent && $obs>=2 && -f "$dir/prereg") {
            my ($shell,$child)=split /\s+/,get("$dir/prereg");
            $target=0+$shell;
            die 'void_fixture: prereg not a spawned unconfirmed direct child' unless defined($child) && $t->{$child} && $t->{$child}{ppid}==$target;
            $unconfirmed_child=$t->{$child}; $early{$child}=$t->{$child};
            my $more=1; while($more) { $more=0; for my $p (keys %$t) { next if $early{$p};
                if ($early{$t->{$p}{ppid}} && matches($early{$t->{$p}{ppid}},$t->{$t->{$p}{ppid}})) { $early{$p}=$t->{$p}; $more=1 }
            } }
            $barrier=1;
        } elsif (defined($phase) && $phase eq 'ready' && -f "$dir/ready" && $obs>=2) {
            $barrier=1; ($target)=split /\s+/,get("$dir/ready"); $target=0+$target;
        } elsif (!defined($phase) && $obs>=2) { $target=$pid }
        if (%early) {
            my $more=1; while($more) { $more=0; for my $p (keys %$t) { next if $early{$p};
                my $par=$t->{$p}{ppid}; if ($early{$par} && matches($early{$par},$t->{$par})) { $early{$p}=$t->{$p}; $more=1 }
            } }
        }
        # Only a candidate with no observed hooks may use the pre-integration
        # fallback; once any hook is seen, wait for the selected barrier.
        if (defined($phase) && !$candidate_barrier_seen && !$barrier && $obs>=2 && now()-$t0>0.3) {
            $target=$type eq 'raw' ? $pre->[0]{ppid}:$pid;
        }
        if (defined($sig) && defined($target) && !$sent) {
            if ($phase && $phase eq 'group') { $target=$pid }
            my $id=$t->{$target}; die 'void_fixture: signal target absent' unless $id;
            if (defined($phase) && $phase eq 'group') {
                die 'void_fixture: command group leader' unless $id->{pgid}==$pid;
                kill uc($sig),-$pid;
            } else { signal_id(uc($sig),$id) }
            $sent=1; $trigger_at=now();
            put("$dir/$phase.release",'release') if defined($phase) && $phase ne 'group';
            return $trigger_at;
        }
        if ($name eq 'runner-first-signal-wins' && $sent && $sent<3 && now()>$trigger_at+0.05*$sent) {
            my $id=$t->{$pid}; signal_id($sent==1?'INT':'HUP',$id) if $id; $sent++;
        }
        return undef;
    });
    my $post=controlled_table(); my @checked=(@$pre,values %early); my @survivors=grep {live($_,$post)} @checked;
    my $ok=!$r->{guardian_cap_fired} && !@survivors && live($post->{$SENTINEL},$post);
    if(defined($phase) && $phase eq 'prereg') { $ok &&=$barrier && $sent && $unconfirmed_child }
    else { $ok &&=@$pre==2 && $obs>=2; $ok &&=$pre->[0]{pgid}!=$pre->[1]{pgid} if $kind ne 'same' }
    my $expected=$type eq 'runner' ? (defined($sig)?128+(lc($sig) eq 'hup'?1:lc($sig) eq 'int'?2:15):$kind eq 'parentexit'?7:142) : $type eq 'gate'?1:2;
    if (defined($phase) && $phase eq 'group') { $ok &&=$r->{actual_rc}!=0 } else { $ok &&=$r->{actual_rc}==$expected }
    my $log=$r->{stdout}.$r->{stderr}.get("$dir/gate.log").get("$dir/scratch/crew-console.log");
    $ok &&=$log=~/timeout after 2 s/ unless defined($sig) || $kind eq 'parentexit';
    $ok &&=$r->{elapsed}<=6;
    $ok &&=defined($trigger_at) && now()-$trigger_at<=4 if defined $sig;
    $ok &&=$log!~/script-gate: .* ok:|^crew-console-test: ok/m if defined $sig;
    my $named=defined($sig)?uc($sig):'';
    if (defined($sig)) {
        $ok &&=$log=~/^bounded-run: interrupted by \Q$named\E$/m;
    }
    my $c=case_result(name=>$name,%$r,passed=>$ok,trigger=>defined($sig)?"direct $sig ".($phase//'runner'):$kind eq 'parentexit'?'ordinary exit after two observations':'deadline',
        pre_identities=>$pre,post_identities=>[map {$post->{$_->{pid}}//{pid=>$_->{pid},absent=>JSON::PP::true}} @$pre],
        inner_make_rc=>$type eq 'raw'?$r->{actual_rc}:undef,behavioral_leak=>@survivors?JSON::PP::true:JSON::PP::false,
        unconfirmed_child=>$unconfirmed_child,early_identities=>[values %early],
        inner_interruption_observed=>defined($sig) && $log=~/^bounded-run: interrupted by \Q$named\E$/m?JSON::PP::true:JSON::PP::false,
        production_log=>$log,barrier_observed=>$barrier?JSON::PP::true:JSON::PP::false,cleanup_outcome=>'pending');
    # Leak observation and passed=false are durable BEFORE independent cleanup.
    $c->{cleanup_outcome}=clean_ids(\@checked); save();
    die "interruption reporter disagrees with passing functional case\n" if $ok && defined($sig) && !$c->{inner_interruption_observed};
}
sub selftest {
    @CASES=();
    for my $rc (0,7,142) { simple_case("runner-exit$rc",['sh',"$ROOT/tools/bounded_run.sh",2,'--','sh','-c',"exit $rc"],$rc) }
    simple_case('runner-missing127',['sh',"$ROOT/tools/bounded_run.sh",2,'--',"$ART/missing-command"],127);
    simple_case('runner-child-term143',['sh',"$ROOT/tools/bounded_run.sh",2,'--',$PERL,'-e','kill "TERM",$$; select undef,undef,undef,1'],143);
    local $ENV{BR_REMOVE}='remove-me';
    my $transport='die "env" unless $ENV{BR_VALUE} eq "a b" && !exists $ENV{BR_REMOVE}; die "args" unless @ARGV==3 && $ARGV[0] eq "" && $ARGV[1] eq "a b" && $ARGV[2] eq q{$(never);*}; die "stdin" unless <STDIN> eq "input\\n"; print "transport stdout\\n"; print STDERR "transport stderr\\n";';
    $transport=~s/\\\\n/\\n/g;
    simple_case('runner-transport',['sh',"$ROOT/tools/bounded_run.sh",2,'--','BR_VALUE=a b','env','-u','BR_REMOVE',$PERL,'-e',$transport,'','a b','$(never);*'],0,qr/transport stdout.*transport stderr/s,"input\n");
    my $usageok=1; my $last;
    for my $v (['0','--'],['-1','--'],['1.5','--'],['2','missing'],['2','--']) {
        my @cmd=@$v; push @cmd,'sh','-c',"touch '$ART/forbidden-launch'" unless @$v==2 && $v->[0] eq '2' && $v->[1] eq '--';
        $last=run_command('runner-usage-'.int(rand(1e8)),3,['sh',"$ROOT/tools/bounded_run.sh",@cmd]);
        $usageok &&=$last->{actual_rc}==2 && !-e "$ART/forbidden-launch" && !$last->{guardian_cap_fired};
    }
    # Inspection refusal is a real candidate execution with a private denied ps.
    make_path("$ART/runner-deny"); put("$ART/runner-deny/ps","#!/bin/sh\nexit 1\n"); chmod 0700,"$ART/runner-deny/ps";
    { local $ENV{PATH}="$ART/runner-deny:/usr/bin:/bin";
      my $d=run_command('runner-inspection125',4,['sh',"$ROOT/tools/bounded_run.sh",2,'--','true']);
      $usageok &&=$d->{actual_rc}==125 && !$d->{guardian_cap_fired}; }
    case_result(name=>'runner-usage',%$last,passed=>$usageok,trigger=>'invalid boundary and denied inspection125',cleanup_outcome=>'no_live_registered_survivors');
    fixture_case('runner-timeout-same-group','runner','same');
    fixture_case('runner-timeout-escaped','runner','escaped');
    fixture_case('runner-timeout-parent-first','runner','parentfirst');
    for my $s (qw(hup int term)) { fixture_case("runner-$s",'runner','escaped',$s) }
    fixture_case('runner-parent-exit7-retained','runner','parentexit');
    fixture_case('runner-first-signal-wins','runner','escaped','term');
    fixture_case('runner-inherited-ignored-int','runner','escaped','int');
    guardian_positive();
    my $gate="$ROOT/tools/script_gate.sh";
    simple_case('gate-counted-pass',['sh',$gate,'counted',"$ART/counted.log",2,'^drill: [1-9][0-9]* passed, 0 failures$','--','sh','-c','echo "drill: 1 passed, 0 failures"'],0);
    simple_case('gate-want1',['sh',$gate,'want1',"$ART/want1.log",2,'^negative: FAIL$',1,'--','sh','-c','echo "negative: FAIL"; exit 1'],0);
    simple_case('gate-zero-reject',['sh',$gate,'zero',"$ART/zero.log",2,'^crew-console: 0 failures$','--','sh','-c','echo "crew-console: 0 failures"'],1,qr/carries no nonzero count/);
    fixture_case('gate-timeout-same-group','gate','same');
    for my $mode (qw(pass rc7 error nosummary)) {
        local $ENV{BR_STUB_MODE}=$mode;
        simple_case("rawmake-$mode",raw_argv("$ART/raw-$mode"),$mode eq 'pass'?0:2);
        $CASES[-1]{inner_make_rc}=$CASES[-1]{actual_rc}; save();
    }
    fixture_case('gate-timeout-escaped','gate','escaped');
    fixture_case('rawmake-summary-hang','raw','escaped');
    for my $type (qw(gate raw)) { for my $phase (qw(prereg ready)) { for my $sig (qw(hup int term)) {
        fixture_case("$type-relay-$phase-$sig",$type,'escaped',$sig,$phase);
    } } }
    for my $sig (qw(hup int term)) { fixture_case("raw-make-group-$sig",'raw','escaped',$sig,'group') }
    my %got; $got{$_->{name}}++ for @CASES;
    die 'fixed selftest case-set mismatch' unless @CASES==@FIXED && !grep {($got{$_}//0)!=1} @FIXED;
    save(); return scalar(grep {!$_->{passed}} @CASES)?1:0;
}

sub dispatch {
    my (@args)=@_;
    my $head=run_command('root-head',2,['git','-C',$ROOT,'rev-parse','HEAD']);
    die 'ROOT HEAD unavailable' unless $head->{actual_rc}==0; put("$ART/head.txt",$head->{stdout});
    return guard_worker(@args) if $MODE eq 'guard';
    return guard_controls() if $MODE eq 'guardian-controls';
    return selftest() if $MODE eq 'selftest';
    return mutants() if $MODE eq 'mutants';
    return crew(@args) if $MODE eq 'crew';
    return audit(@args) if $MODE eq 'audit';
    die "usage: unknown mode\n";
}
sub main {
    ($MODE,$ROOT,my $parent,my @args)=@ARGV;
    die "usage: MODE absolute-ROOT absolute-artifact-parent\n" unless defined($MODE) && $MODE=~/^(guard|guardian-controls|selftest|mutants|crew|audit)$/ && defined($parent) && $ROOT =~ m{^/} && $parent =~ m{^/} && -f "$ROOT/Makefile" && -d $parent && -w $parent;
    $ROOT=abs_path($ROOT); $ART=tempdir('7ad-XXXXXXXX',DIR=>$parent,CLEANUP=>0); chmod 0700,$ART;
    print "artifacts=$ART\n"; $|=1;
    my $cap= $MODE eq 'crew' ? (($args[0]//'') eq 'normal'?480:240) : $MODE eq 'mutants'?180:$MODE eq 'audit'?30:120;
    if ($MODE eq 'guard') { $cap=shift @args; die "usage: guard CAP -- command\n" unless defined($cap) && $cap =~ /^[1-9][0-9]*$/ && @args>1 && shift(@args) eq '--' }
    make_path("$ART/registrations","$ART/script-gate");
    $ENV{SCRIPT_GATE_TMP}="$ART/script-gate"; $ENV{BR_ART}=$ART;
    my ($cancel,$guardian_signal);
    $SIG{$_}=do { my $sig=$_; sub { if (!defined($cancel)) { $cancel=now(); $guardian_signal=$sig } } } for qw(HUP INT TERM);
    $GUARDIAN=$$; $TOKEN=join('-', $$,now(),rand());
    $SENTINEL=fork(); die 'sentinel fork' unless defined $SENTINEL;
    if (!$SENTINEL) { $SIG{$_}='DEFAULT' for qw(HUP INT TERM); finite_hold(now()+$cap+4); POSIX::_exit(0) }
    my ($sentid,$wid,$worker,$st,$fail,$capfired); my (%registered,%observed); my $end=now()+$cap;
    eval {
        my $t=controlled_table(); $sentid=$t->{$SENTINEL};
        $ENV{BR_GUARDIAN}=$GUARDIAN; $ENV{BR_SENTINEL}=$SENTINEL; $ENV{BR_TOKEN}=$TOKEN; $ENV{BR_REG_DIR}="$ART/registrations";
        $worker=fork(); die 'worker fork' unless defined $worker;
        if (!$worker) {
            setpgrp(0,0); $SIG{$_}='DEFAULT' for qw(HUP INT TERM);
            # Held leader remains alive until guardian has cleaned its private group.
            my $rc; eval { $rc=dispatch($MODE eq 'guard'?($cap,@args):@args); 1 } or do { my $e=$@; put("$ART/worker-error.txt",$e); $rc=$e=~/^usage:/?2:$e=~/inspection_restricted|void_fixture/?3:1 };
            save() unless -f "$ART/results.json";
            put("$ART/worker-status",$rc); finite_hold(now()+4); POSIX::_exit($rc);
        }
        $t=controlled_table(); $wid=$t->{$worker}; die 'inspection_restricted: worker identity' unless $wid;
        while(now()<$end-0.2 && !defined($cancel)) {
            my $tab=controlled_table($end);
            # Retain every actually observed worker descendant independently of
            # candidate registrations, including arbitrary commands that setsid.
            for my $p (keys %observed) { delete $observed{$p} unless matches($observed{$p},$tab->{$p}) }
            $observed{$worker}=$wid if matches($wid,$tab->{$worker});
            my $more=1;
            while ($more) { $more=0;
                for my $p (keys %$tab) {
                    next if $p==$$ || $p==$SENTINEL || $PS_HELPERS{$p} || $observed{$p};
                    if ($observed{$tab->{$p}{ppid}}) { $observed{$p}=$tab->{$p}; $more=1 }
                }
            }
            for my $key (keys %registered) { delete $registered{$key} unless live($registered{$key},$tab) }
            opendir my $d,"$ART/registrations" or die $!; my @req=grep {/\.req$/} readdir $d; closedir $d;
            for my $file (@req) {
                my $ackfile=$file =~ s/\.req$/.ack/r; next if -f "$ART/registrations/$ackfile"; my $r=decode_json(get("$ART/registrations/$file"));
                # Authentication, birth and ancestry are all checked on this new
                # bounded positive-control table, never the pre-readdir table.
                registration_snapshot($r,$file,$end,$wid,\%registered);
                $registered{$file}=$r; put("$ART/registrations/$r->{nonce}.ack",'ack');
            }
            last if -f "$ART/worker-status"; pause();
        }
        while(now()<$end && !defined($cancel) && !-f "$ART/worker-status") { pause() }
        $capfired= !defined($cancel) && !-f "$ART/worker-status"; $st=defined($cancel)?128+($guardian_signal eq 'HUP'?1:$guardian_signal eq 'INT'?2:15):$capfired?124:0+get("$ART/worker-status");
        $fail="guardian interrupted by $guardian_signal" if defined $cancel;
        $fail='guardian worker cap fired' if $capfired;
        print STDERR "bounded-guard: cap after $cap s (rc 124)\n" if $capfired;
        1;
    } or do { $fail=$@; $st=$fail=~/inspection_restricted|void_fixture/?3:1 };
    # Record the failure BEFORE cleanup. Candidate observations remain immutable.
    my $data=eval { decode_json(get("$ART/results.json")) } || {mode=>$MODE,artifacts=>$ART,cases=>[]};
    $data->{worker_cap_fired}=$capfired?JSON::PP::true:JSON::PP::false;
    $fail //=get("$ART/worker-error.txt") if $st==3;
    $data->{inspection_restricted}=($fail//'')=~/inspection_restricted/?JSON::PP::true:JSON::PP::false;
    $data->{void_fixture}=($fail//'')=~/void_fixture/?JSON::PP::true:JSON::PP::false;
    $data->{failure_before_cleanup}=$fail if $fail;
    put("$ART/results.json",$JSON->encode($data));
    my $ce=defined($cancel)?$cancel+3:$capfired?$end+3:now()+3;
    eval {
        my %all=(%observed,map { $_->{pid}=>$_ } values %registered);
        # Fresh birth checks precede each individual signal; never broadcast a
        # cached arbitrary command group. Keep candidate leak evidence above.
        for my $id (values %all) { signal_id('KILL',$id,$ce) if now()<$ce }
        $data->{observed_descendants}=[values %observed];
        $data->{cleanup_outcome}=clean_ids([values %all],$ce);
        1;
    } or do { $fail=$@; $data->{cleanup_error}=$fail; $data->{cleanup_outcome}='inspection_restricted'; $st=3; $data->{inspection_restricted}=JSON::PP::true };
    # Unreaped direct children cannot have had their PIDs reused, even without ps.
    kill 'KILL',$worker if $worker; kill 'KILL',$SENTINEL;
    kill 'KILL',$_ for keys %PS_HELPERS;
    while(now()<$ce) { reap_ps(); my $a=$worker?waitpid($worker,WNOHANG):-1; my $b=waitpid($SENTINEL,WNOHANG); last if $a==-1 && $b==-1 && !keys(%PS_HELPERS); pause() }
    my $saved_head=get("$ART/head.txt"); $data->{head}=$saved_head if length($saved_head);
    put("$ART/results.json",$JSON->encode($data));
    print STDERR "UNMEASURED: inspection/fixture unavailable: ".($fail//'see retained results')."\n" if $st==3;
    return $st//1;
}
my $rc=eval { main() };
if ($@) { print STDERR $@; exit($@=~/^usage:/?2:1) }
exit($rc//1);
