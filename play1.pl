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
# 1st code in instructions
# 2nd after startup
# 3rd after successful selftest

# testing:
help
inv

# 4th code
north
take tablet
use tablet

# 5th code
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

# 6th code
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

# 7th code

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

# 7th code
north
north
north
north
north
north
north
east
take journal
look journal
west
north
north

# antechamber
look orb
take orb

# solved with orb.pl
north
east
east
north
west
south
east
east
west
north
north
east

# final 8th code
vault
take mirror
use mirror
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
