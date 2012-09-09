#!/usr/bin/env perl

use List::Util qw(min max sum);

sub mean { return @_ ? sum(@_) / @_ : 0 }

%insns = ();
%count = (
  alu => 0,
  muldiv => 0,
  jmp => 0,
  branch => 0,
  load => 0,
  store => 0
);

@block_sz = ();
$block_idx = 0;
$last_pc = -4;
$branches_taken = 0;
$branch_inst_d1 = 0;
$branch_inst_d2 = 0;
$jmp_inst_d1 = 0;
$jmp_inst_d2 = 0;

open(FD, $ARGV[0]) or die "Could not open file";
while (<FD>) {
	$_ =~ /\s*(\d+).*pc=([0-9a-f]+);\s*(\w+).*;.*alu=(\d).*muldiv=(\d).*jmp=(\d).*branch=(\d).*load=(\d).*store=(\d).*unknown=(\d)/;
	$time = $1;
	$pc = hex($2);
	$inst = $3;
	$alu_inst = $4;
	$muldiv_inst = $5;
	$jmp_inst = $6;
	$branch_inst = $7;
	$load_inst = $8;
	$store_inst = $9;
	$unknown_inst = $10;

	++$insns{$inst};

	$count{alu} += $alu_inst;
	$count{muldiv} += $muldiv_inst;
	$count{jmp} += $jmp_inst;
	$count{branch} += $branch_inst;
	$count{load} += $load_inst;
	$count{store} += $store_inst;

	if ($pc != ($last_pc+4)) {
		++$block_idx;
		$branches_taken += $branch_inst_d2;
	}

	$last_pc = $pc;

	++$block_sz[$block_idx];

	$branch_inst_d2 = $branch_inst_d1;
	$branch_inst_d1 = $branch_inst;
}


while (($key, $value) = each %count) {
	print "$key $value\n";
}
print "=================\n";

while (($key, $value) = each %insns) {
	print "$key $value\n";
}
print "=================\n";

print "Branches (excluding jmps) taken: $branches_taken\n";

open (BF, '> branch_blocks.dat');
for my $value (@block_sz) {
	print BF "$value\n";
}

my @block_sz = sort @block_sz;
my $mean = mean @block_sz;
my $min = min @block_sz;
my $max = max @block_sz;
my $idx =  int @block_sz/2;
my $median = (@block_sz %2) ? $block_sz[$idx] : ($block_sz[$idx] + $block_sz[$idx+1])/2;

print "mean: $mean, median: $median, min: $min, max: $max\n";

%bins = ();
for my $value (@block_sz) {
	++$bins{$value};
}

while (($key, $value) = each %bins) {
	print "$key $value\n";
}
