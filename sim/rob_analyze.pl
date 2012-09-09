#!/usr/bin/env perl

use List::Util qw(min max sum);

sub mean { return @_ ? sum(@_) / @_ : 0 }


@used_count = ();

open(FD, $ARGV[0]) or die "Could not open file";
while (<FD>) {
	if ($_ =~ m/.*ROB: ins_ptr.*/) {
		$_ =~ /\s*(\d+).*ROB: ins_ptr:.*used_count:\s*(\d+).*/;
		$time = $1;
		$count = $2;
		push(@used_count, $count);
	}
}

open (BF, '> rob_count.dat');
for my $value (@used_count) {
	print BF "$value\n";
}
