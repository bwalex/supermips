#!/usr/bin/env perl

use List::Util qw(min max sum);

sub mean { return @_ ? sum(@_) / @_ : 0 }


@used_count = ();

open(FD, $ARGV[0]) or die "Could not open file";
while (<FD>) {
	if ($_ =~ m/.*IQ: used_count.*/) {
		$_ =~ /\s*(\d+).*IQ: used_count:\s*(\d+).*/;
		$time = $1;
		$count = $2;
		push(@used_count, $count);
	}
}

open (BF, '> iq_count.dat');
for my $value (@used_count) {
	print BF "$value\n";
}
