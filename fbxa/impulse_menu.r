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
}

- (string) text
{
	local integer state = (integer)[flag getState];
	return sprintf ("[%c] %s", state ? '#' : ' ', [super text]);
}

- (void) select
{
	[flag toggleState];
}
@end

@implementation CommandMenuItem
- (id) initWithText:(string)txt object:(id)obj selector:(SEL)sel
{
	self = [super initWithText: txt];
	object = obj;
	selector = sel;
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

- (integer) impulse: (integer) imp
{
	return imp;
}

- (string) text
{
	return sprintf ("%s", text);
}
@end

@implementation ImpulseValueMenu
- (integer) impulse: (integer) imp
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

- (integer) value
{
	return value;
}
@end

@implementation ImpulseListMenu
- (integer) impulse: (integer) imp
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
	local integer i;

	for (i = 0; i < 10; i++) {
		if (!items[i])
			break;
		s = [items[i] text];
		if (s)
			str = sprintf ("%s\n[%i] %s", str, (i + 1) % 10, s);
		else
			str = sprintf ("%s\n", str);
	}
	return str;
}

- (void) addItem:(MenuItem) item
{
	local integer i;

	for (i = 0; i < 10; i++) {
		if (!items[i]) {
			items[i] = item;
			break;
		}
	}
}
@end
