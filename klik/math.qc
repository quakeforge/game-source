#include "math.qh"
#include "builtins.qh"

/* Ugh.  QuakeC doesn't include these ops. */
float(float num, float bits) shl = {
	if (bits >= 16) { num *= 65536; bits -= 16; }
	if (bits >= 8) { num *= 256; bits -= 8; }
	if (bits >= 4) { num *= 16; bits -= 4; }
	if (bits >= 2) { num *= 4; bits -= 2; }
	if (bits >= 1) { num *= 2; }
	return num;
};

float(float num, float bits) shr = {
	if (bits >= 16) { num /= 65536; bits -= 16; }
	if (bits >= 8) { num /= 256; bits -= 8; }
	if (bits >= 4) { num /= 16; bits -= 4; }
	if (bits >= 2) { num /= 4; bits -= 2; }
	if (bits >= 1) { num /= 2; }
	return floor(num);
};
