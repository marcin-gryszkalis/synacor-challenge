#!/usr/bin/perl
use warnings;
use strict;
use Data::Dumper;
use List::Util qw/min max first sum product all any/;
use List::MoreUtils qw(uniq);
use File::Slurp;
use Algorithm::Combinatorics qw(combinations permutations);
use Clone qw/clone/;

use IPC::Open3;
use POSIX ":sys_wait_h";

my $startupstr = "help
north
take tablet
use tablet
doorway
north
north
bridge
continue
down
east
take empty lantern
west
west
passage
ladder
";

my @startup = split/\n/, $startupstr;

my $prompt = 'What do you do?';

my $pid;
my %seen;
my $seenc = 0;

sub quithandler
{
    return unless defined $pid;

    my $kid = waitpid($pid, WNOHANG);
#    my $child_status = $?;

    # if ($kid > 0) {
    #     # child exited
    #     if ($child_status & 127) {
    #         # child died somehow
    #         die sprintf("child died with signal %d, %s coredump\n", ($? & 127),  ($? & 128) ? 'with' : 'without');
    #     } else {
    #         # child exited calmly
    #         $child_result = ($child_status >> 8);
    #         print "(child exited normally with result=$child_result)\n" if $COMMENTARY;
    #     }
    # } else {
    #     # unexpected (e.g. interrupted?)
    #     print "(other SIGCHILD: pid=$child_pid: child_status=$child_status\n" if $COMMENTARY;

    #     # we might decide this is fatal
    #     die "interrupted: unable to continue\n" if $DIE_ON_INTERRUPTION;
    # }

    for my $k (sort keys %seen)
    {
        print "$k\n";
    }
    exit 0;
};

$SIG{CHLD} = &quithandler;

$pid = open3(my $in, my $out, my $err, 'perl synacor.pl');

sub getline
{
    $_ = <$out>;
    exit unless defined $_;
    chomp;

    if (exists $seen{$_})
    {
        printf "[%03d] $_\n", $seen{$_};
    }
    else
    {
        $seen{$_} = $seenc++;
        printf "!%03d! $_\n", $seen{$_};
    }

    return $_;
}

while (1)
{
    $_ = getline();

    if (/^$prompt/)
    {
        last unless @startup;
        my $cmd = shift(@startup);
        print("$cmd\n");
        print($in "$cmd\n");
    }
}

while (1)
{
    print "# ";
    $_ = <>;

    if (/quit/)
    {
        kill 'TERM', $pid;
        sleep(5);
        exit(0);
    }

    print($in "$_");

    while (1)
    {
        $_ = getline();
        last if /^$prompt/;
    }
}

waitpid($pid, 0);
