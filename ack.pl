#!/usr/bin/perl
use strict;
use warnings;
no warnings 'recursion';
use Memoize qw/memoize flush_cache/;

$; = ",";

#https://en.wikipedia.org/wiki/Ackermann_function

# 5483:   set R0 4 <- 1st arg
# 5486:   set R1 1 <- 2nd arg
# 5489:  call 6027
#                         6027:    jt R0 6035
#                         6030:   add R0 R1 1
#                         6034:   ret

#                         6035:    jt R1 6048

#                         6038:   add R0 R0 32767
#                         6042:   set R1 R7 <- !!! r7 applied instead of 1
#                         6045:  call 6027
#                         6047:   ret

#                         6048:  push R0
#                         6050:   add R1 R1 32767
#                         6054:  call 6027

#                         6056:   set R1 R0
#                         6059:   pop R0
#                         6061:   add R0 R0 32767
#                         6065:  call 6027
#                         6067:   ret

# 5491:    eq R1 R0 6 <- expecter result
# 5495:    jf R1 5579

our $r7 = 777;
sub ack
{
    my ($a, $b) = @_;

    return ($b+1) % 32768 if $a == 0;
    return ack($a-1, $r7) if $b == 0;
    return ack($a-1, ack($a, $b-1));
}

memoize('ack');
while (1)
{
    flush_cache('ack');
    my $r = ack(4,1);
    printf("r7=%d ack(4,1)=%d\n", $r7, $r);
    exit if $r == 6;
    $r7++;
}
