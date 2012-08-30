#!/usr/bin/env perl

use List::Util qw(min max sum);

sub mean { return @_ ? sum(@_) / @_ : 0 }


%opnotready = (
  branch => 0,
  jmp => 0
);

%unitnotready = (
  branch => 0,
  jmp => 0
);

@isscount = ();
%forwarding = (
  yes => 0,
  no => 0
);

open(FD, $ARGV[0]) or die "Could not open file";
while (<FD>) {
	if ($_ =~ m/.*OP_NOT_READY.*/) {
		$_ =~ /\s*(\d+).*ISS: (branch|jmp), pc=\s*([0-9a-f]+).*/;
		$time = $1;
		$brj = $2;
		$pc = $3;
		++$opnotready{$brj};
	} elsif ($_ =~ m/.*UNIT_NOT_READY.*/) {
		$_ =~ /\s*(\d+).*ISS: (branch|jmp), pc=\s*([0-9a-f]+).*/;
		$time = $1;
		$brj = $2;
		$pc = $3;
		++$unitnotready{$brj};
	} elsif ($_ =~ m/.*issue_count.*/) {
		$_ =~ /\s*(\d+).*ISS: issue_count=\s*(\d+).*/;
		$time = $1;
		$issue_count = $2;
		push(@isscount, $issue_count);
	} elsif ($_ =~ m/.*issuing.*fwd.*fwd.*/) {
		$_ =~ /\s*(\d+).*ISS: issuing.*fwd=(\d).*fwd=(\d).*/;
		$time = $1;
		$fwdA = $2;
		$fwdB = $3;
		if ($fwdA != 0 or $fwdB != 0) {
			++$forwarding{yes};
		} else {
			++$forwarding{no};
		}
	}
}

print "OP_NOT_READY:\n";
while (($key, $value) = each %opnotready) {
	print "$key $value\n";
}

print "=================\n";
print "UNIT_NOT_READY:\n";
while (($key, $value) = each %unitnotready) {
	print "$key $value\n";
}

print "=================\n";
print "forwarding:\n";
while (($key, $value) = each %forwarding) {
	print "$key $value\n";
}

print "=================\n";

open (BF, '> iss_count.dat');
for my $value (@isscount) {
	print BF "$value\n";
}

