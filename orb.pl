#!/usr/bin/perl
use 5.28.0;
use warnings;
use strict;
use Data::Dumper;
use List::Util qw/min max/;
use Graph::Undirected;
use Algorithm::Combinatorics qw(combinations);
use Clone qw/clone/;

$; = ',';

my @og = qw/
22  -   9   *
+   4   -   18
4   *   11  *
*   8   -   1
/;

my $goal = 30;

my @dx = qw/1 0 -1 0/;
my @dy = qw/0 1 0 -1/;
my @dn = qw/east north west south/;

my $h;
for my $y (0..3)
{
    for my $x (0..3)
    {
        $h->{$x,$y} = shift(@og);
    }
}

my @bfs = ();

my %node = (
    x => 0,
    y => 0,
    path => '0',
    value => 0,
    op => '+',
    cmds => '',
    l => 0,
);

push(@bfs, \%node);

my $bestlen = 1000;
while (1)
{
    my $n = shift(@bfs);
    last unless defined $n;
    next if $n->{l} > $bestlen;
    next if $n->{l} > 0 && $n->{x} == 0 && $n->{y} == 0; # don't go back to pedestal
# print Dumper $n;
# sleep(1);
    my $e = $h->{$n->{x},$n->{y}};
    if ($e =~ /\d+/)
    {
        my $v = $n->{value};
        my $nv = eval "$v $n->{op} $e";

        next if $nv > 100 || $nv < -100;
        $n->{path} .= " $n->{op} $e";
        $n->{value} = $nv;


        if ($n->{x} == 3 && $n->{y} == 3)
        {
            if ($nv == $goal)
            {
                $n->{path} =~ s/^0 \+ //;
                print "(LEN $n->{l}) $n->{path} = $nv\n\n";
                $n->{cmds} =~ s/\s+/\n/g;
                print $n->{cmds}."\n";

                $bestlen = $n->{l} if $n->{l} < $bestlen;
            }
            next; # don't go deeper
        }
    }
    else # operator
    {
        $n->{op} = $e;
    }

    for my $d (0..3)
    {
        my $nx = $n->{x} + $dx[$d];
        my $ny = $n->{y} + $dy[$d];
        my $nd = $dn[$d];
        next if $nx < 0 || $nx > 3 || $ny < 0 || $ny > 3;

        my $nn = clone($n);
        $nn->{x} = $nx;
        $nn->{y} = $ny;
        $nn->{cmds} .= "$nd ";

        $nn->{l}++;
        push(@bfs, $nn);
    }

#    print Dumper \@bfs;
}
