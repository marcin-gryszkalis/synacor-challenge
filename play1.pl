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

my $startupstr = "#
# testing:
help
inv

# 3rd code
north
take tablet
use tablet

# 4th code
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
west
south
north
take can
use can
use lantern

# 5th code
west
ladder
darkness
continue
west
west
west
west
north
take red coin
# red = 2
look red coin
north
west
take blue coin
# blue = 9
look blue coin
up
take shiny coin
# shiny = 5
look shiny coin
down
east
east
take concave coin
# concave = 7
look concave coin
down
take corroded coin
# corroded = 3
look corroded coin
up
west
# _ + _ * _^2 + _^3 - _ = 399
# 9 2 5 7 3
use blue coin
use red coin
use shiny coin
use concave coin
use corroded coin
north
take teleporter
use teleporter

take business card
look business card
take strange book
look strange book

# now we need to hack reg{7} :)
# calculated with ack.pl
hack r7=25734

# eg. noop
# hack m5489=21
# hack m5490=21

# jmp override:
hack m5489=6

# jmp = Miscalibration detected!  Aborting teleportation!
hack m5490=5579

# jmp = beach
hack m5490=5498

use teleporter
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

$SIG{CHLD} = \&quithandler;

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

W: while (1)
{
    $_ = getline();

    if (/^$prompt/)
    {
        while (1)
        {
            last W unless @startup;
            my $cmd = shift(@startup);

            next if $cmd =~ /^#/;
            next if $cmd =~ /^\s*$/;
            print("$cmd\n");
            print($in "$cmd\n");
            last;
        }
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
