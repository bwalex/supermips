#!/usr/bin/env perl

use List::Util qw(min max sum);

sub mean { return @_ ? sum(@_) / @_ : 0 }


%opnotready = (
  branch => 0,
  jmp => 0
);

%opnotready_raw = (
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

%b = ();
$branchjmp_count = 0;

$last_time = 0;
open(FD, $ARGV[0]) or die "Could not open file";
while (<FD>) {
	if ($_ =~ m/.*OP_NOT_READY.*/) {
		$_ =~ /\s*(\d+).*ISS: (branch|jmp), pc=\s*([0-9a-f]+).*/;
		$time = $1;
		$brj = $2;
		$pc = $3;
		if ($b{hex($pc)} == 0) {
			++$opnotready{$brj};
			$b{hex($pc)} = 1;
		}
		if ($time != $last_time) {
			++$opnotready_raw{$brj};
			$last_time = $time;
		}
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
		$_ =~ /\s*(\d+).*ISS: issuing to (\w+):.*pc=\s*([0-9a-f]+).*fwd=(\d).*fwd=(\d).*/;
		$time = $1;
		$unit = $2;
		$pc = $3;
		$fwdA = $4;
		$fwdB = $5;
		if ($fwdA != 0 or $fwdB != 0) {
			++$forwarding{yes};
		} else {
			++$forwarding{no};
		}
	} elsif ($_ =~ m/.*issuing.*/) {
		$_ =~ /\s*(\d+).*ISS: issuing to (\w+):.*pc=\s*([0-9a-f]+).*/;
		$time = $1;
		$unit = $2;
		$pc = $3;
		if ($unit eq "BRANCH") {
			++$branchjmp_count;
			$b{hex($pc)} = 0;
		}
	}
}

print "issued branches + jmps: $branchjmp_count\n";

print "OP_NOT_READY (unique branches):\n";
while (($key, $value) = each %opnotready) {
	print "$key $value\n";
}


print "=================\n";
print "OP_NOT_READY (raw, number of cycles wasted on trying to issue branches):\n";
while (($key, $value) = each %opnotready_raw) {
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

