#include "impulse_menu.h"
#include "string.h"

@implementation MenuItem
- (id) initWithText:(string)txt
{
	self = [super init];
	text = txt;
	return self;
}

- (string) text
{
	return text;
}

- (void) select
{
}
@end

@implementation FlagMenuItem
- (id) initWithText:(string)txt flagObject:(id)flg
{
	self = [super initWithText: txt];
	flag = flg;
	return self;
}

- (string) text
{
	local int state = (int)[flag state];
	return sprintf ("[%c] %s", state ? '#' : ' ', [super text]);
}

- (void) select
{
	[flag toggle];
}
@end

@implementation CommandMenuItem
- (id) initWithText:(string)txt object:(id)obj selector:(SEL)sel
{
	self = [super initWithText: txt];
	object = obj;
	selector = sel;
	return self;
}

- (void) select
{
	[object performSelector:selector];
}
@end

@implementation ImpulseMenu
- (id) initWithText:(string)txt
{
	self = [super init];
	text = txt;
	return self;
}

- (int) impulse: (int) imp
{
	return imp;
}

- (string) text
{
	return sprintf ("%s", text);
}
@end

@implementation ImpulseValueMenu
- (int) impulse: (int) imp
{
	if (imp < 1 || imp > 10)
		return imp;
	if (imp == 10)
		imp = 0;
	value = value * 10 + imp;
	return 0;
}

- (string) text
{
	return sprintf ("%s%i", text, value);
}

- (void) clearValue
{
	value = 0;
}

- (int) value
{
	return value;
}
@end

@implementation ImpulseListMenu
- (int) impulse: (int) imp
{
	if (imp < 1 || imp > 10)
		return imp;
	if (items[imp - 1])
		[items[imp - 1] select];
	return 0;
}

- (string) text
{
	local string str = text;
	local string s;
	local int i;
	local string is[10];
	local int max_len = 0, len;

	for (i = 0; i < 10; i++) {
		if (!items[i])
			break;
		is[i] = [items[i] text];
		len = strlen(is[i]);
		if (len > max_len)
			max_len = len;
	}
	for (i = 0; i < 10; i++) {
		if (!items[i])
			break;
		s = is[i];
		if (s)
			str = sprintf (sprintf ("%%s\n[%%i] %%-%ds", max_len),
						   str, (i + 1) % 10, s);
		else
			str = sprintf ("%s\n", str);
	}
	return str;
}

- (void) addItem:(MenuItem *) item
{
	local int i;

	for (i = 0; i < 10; i++) {
		if (!items[i]) {
			items[i] = item;
			break;
		}
	}
}
@end
