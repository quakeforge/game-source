#!/usr/bin/perl

my ($pos, %equipids);

$pos = 0;

while (<>) {
	while (s/^(\s*#\s*define\s+STR_(EQUIPID_[A-Z_]+)\s+(.*))$//) {
		next if defined($equipids{$2});

		print "$1\n";

		$equipids{$2} = $pos;
		$pos++;
	}
}

while (($key, $value) = each %equipids) {
	print "#define $key $value\n";
}
print "#define EQUIPID_LAST $pos\n";

open(HANDLE, ">equipid.qc");

print HANDLE <<EOF;
#include "common.qh"
#include "equip.qh"

EOF

print HANDLE "\nstring(float eid) equip_id_to_string = {\n";
while (($key, $value) = each %equipids) {
	print HANDLE "\tif (eid == $key) return STR_$key;\n";
}
print HANDLE "\n\terror(\"Unknown EQUIPID\");\n\treturn \"BUG\";\n};\n";

close(HANDLE);
