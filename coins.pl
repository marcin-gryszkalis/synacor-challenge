#!/usr/bin/perl
use warnings;
use strict;
use Data::Dumper;
use List::Util qw/min max first sum product all any/;
use List::MoreUtils qw(uniq);
use File::Slurp;
use Algorithm::Combinatorics qw(combinations permutations);
use Clone qw/clone/;

# _ + _ * _^2 + _^3 - _ = 399

my @coins = qw/2 9 5 7 3/;
my $it = permutations(\@coins);
while (my $p = $it->next)
{
    print(join(" ", @$p)) if $p->[0] + $p->[1] * $p->[2]**2 + $p->[3]**3 - $p->[4] == 399;
}

