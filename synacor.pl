#!/usr/bin/perl
use warnings;
use strict;
use Data::Dumper;
use List::Util qw/min max first sum product all any/;
use List::MoreUtils qw(uniq);
use File::Slurp;
use Algorithm::Combinatorics qw(combinations permutations);
use Clone qw/clone/;

my @mem;
my @stack;
my %regs = map { $_ => 0 } (0..7);
my $ip = 0;

my %ops = qw/
0 halt
1 set
2 push 3 pop
4 eq 5 gt
6 jmp 7 jt 8 jf
9 add 10 mult 11 mod
12 and 13 or 14 not
15 rmem 16 wmem
17 call 18 ret
19 out 20 in
21 noop
/;

my %opsargs = qw/
halt 0
set 2
push 1 pop 1
eq 3 gt 3
jmp 1 jt 2 jf 2
add 3 mult 3 mod 3
and 3 or 3 not 2
rmem 2 wmem 2
call 1 ret 0
out 1 in 1
noop 0
/;

my $dbgf;
sub dbg
{
    open($dbgf, ">debug.txt") unless defined $dbgf;
    my $a = shift;
    print $dbgf "$a\n";
}

open my $fh, '<:raw', 'challenge.bin';
while (1)
{
    my $br = read $fh, my $b, 2;
    last unless $br == 2;

    # my ($magic, $version, @numbers) = unpack 'a4 a x15 N N N N N N', $bytes;
    $b = unpack 'v', $b;
    push(@mem, $b);
}

sub r($)
{
    my $r = shift;
    $r -= 32768;
    die "invalid register ($r)" if $r < 0 || $r > 7;
    return $r;
}

sub v($)
{
    my $v = shift;
    die "invalid value ($v)" if $v < 0 || $v > 32767;
    return $v;
}

sub vr($)
{
    my $v = shift;
    if ($v >= 0 && $v <= 32767)
    {
        # as is
    }
    elsif ($v >= 32768 && $v <= 32775)
    {
        $v = $regs{$v - 32768};
    }
    else
    {
        die "invalid value ($v)";
    }
    return $v;
}

while (1)
{
    my $op = $mem[$ip];

    die "invalid operation: $op at $ip" unless exists $ops{$op};

    my @a = ();
    for my $i (1..$opsargs{$ops{$op}})
    {
        push(@a, $mem[$ip+$i]);
    }

    my @b = ();
    for my $e (@a)
    {
        if ($e >= 32768 && $e <= 32775)
        {
            my $r = $e - 32768;
            my $v = $regs{$r};
            push(@b, "R$r"."=$v");
        }
        else
        {
            push(@b,  $e);
        }
    }
    dbg sprintf("%4d: %5s %s", $ip, $ops{$op}, join(" ", @b));

    my $skip = $opsargs{$ops{$op}} + 1;
    my ($a,$b,$c);

    if ($ops{$op} eq 'halt')
    {
        last;
    }
    elsif ($ops{$op} eq 'set')
    {
        $a = r $mem[$ip+1];
        $b = vr $mem[$ip+2];
        $regs{$a} = $b;
        $ip += $skip;
    }
    elsif ($ops{$op} eq 'push')
    {
        $a = vr $mem[$ip+1];
        push(@stack, $a);
        $ip += $skip;
        dbg "stack: ".join(" ", @stack);
    }
    elsif ($ops{$op} eq 'pop')
    {
        $b = pop(@stack);
        die "pop from empty stack at $ip" unless defined $b;
        $a = r $mem[$ip+1];
        $regs{$a} = $b;
        $ip += $skip;
        dbg "stack: ".join(" ", @stack);
    }
    elsif ($ops{$op} eq 'eq')
    {
        $a = r $mem[$ip+1];
        $b = vr $mem[$ip+2];
        $c = vr $mem[$ip+3];

        $regs{$a} = $b == $c ? 1 : 0;
        $ip += $skip;
    }
    elsif ($ops{$op} eq 'gt')
    {
        $a = r $mem[$ip+1];
        $b = vr $mem[$ip+2];
        $c = vr $mem[$ip+3];

        $regs{$a} = $b > $c ? 1 : 0;
        $ip += $skip;
    }
    elsif ($ops{$op} eq 'jmp')
    {
        $a = vr $mem[$ip+1];
        $ip = $a;
    }
    elsif ($ops{$op} eq 'jt')
    {
        $a = vr $mem[$ip+1];
        $b = vr $mem[$ip+2];
        $ip = $a != 0 ? $b : $ip+$skip;
    }
    elsif ($ops{$op} eq 'jf')
    {
        $a = vr $mem[$ip+1];
        $b = vr $mem[$ip+2];
        $ip = $a == 0 ? $b : $ip+$skip;
    }
    elsif ($ops{$op} eq 'add')
    {
        $a = r $mem[$ip+1];
        $b = vr $mem[$ip+2];
        $c = vr $mem[$ip+3];
        $regs{$a} = ($b + $c) % 32768;
        $ip += $skip;
    }
    elsif ($ops{$op} eq 'mult')
    {
        $a = r $mem[$ip+1];
        $b = vr $mem[$ip+2];
        $c = vr $mem[$ip+3];
        $regs{$a} = ($b * $c) % 32768;
        $ip += $skip;
    }
    elsif ($ops{$op} eq 'mod')
    {
        $a = r $mem[$ip+1];
        $b = vr $mem[$ip+2];
        $c = vr $mem[$ip+3];
        $regs{$a} = $b % $c;
        $ip += $skip;
    }
    elsif ($ops{$op} eq 'and')
    {
        $a = r $mem[$ip+1];
        $b = vr $mem[$ip+2];
        $c = vr $mem[$ip+3];
        $regs{$a} = $b & $c;
        $ip += $skip;
    }
    elsif ($ops{$op} eq 'or')
    {
        $a = r $mem[$ip+1];
        $b = vr $mem[$ip+2];
        $c = vr $mem[$ip+3];
        $regs{$a} = $b | $c;
        $ip += $skip;
    }
    elsif ($ops{$op} eq 'not')
    {
        $a = r $mem[$ip+1];
        $b = vr $mem[$ip+2];
        $regs{$a} = (~$b & 32767);
        $ip += $skip;
    }
    elsif ($ops{$op} eq 'rmem')
    {
        $a = r $mem[$ip+1];
        $b = vr $mem[$ip+2];
        $regs{$a} = $mem[$b];
        $ip += $skip;
    }
    elsif ($ops{$op} eq 'wmem')
    {
        $a = vr $mem[$ip+1];
        $b = vr $mem[$ip+2];
        $mem[$a] = $b;
        $ip += $skip;
    }
    elsif ($ops{$op} eq 'call')
    {
        $a = vr $mem[$ip+1];
        push(@stack, $ip+2);
        $ip = $a;
    }
    elsif ($ops{$op} eq 'ret')
    {
        $a = pop(@stack);
        die "pop from empty stack at $ip" unless defined $a;
        $ip = $a;
    }
    elsif ($ops{$op} eq 'out')
    {
        $a = vr $mem[$ip+1];
        print(chr($a));
        $ip += $skip;
    }
    elsif ($ops{$op} eq 'in')
    {
        $b = ord(getc());
        $a = r $mem[$ip+1];
        $regs{$a} = $b;
        $ip += $skip;
    }
    elsif ($ops{$op} eq 'noop')
    {
        $ip += $skip;
    }
    else
    {
        die "unhandled operation: $op at $ip";
    }

}


