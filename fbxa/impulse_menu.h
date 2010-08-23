#ifndef __impulse_menu_h
#define __impulse_menu_h

#include "Object.h"

@interface  MenuItem: Object
{
	string text;
}
- (id) initWithText:(string)txt;
- (string) text;
- (void) select;
@end

@protocol FlagMenuItem
-(integer) state;
-(void) toggle;
@end

@interface FlagMenuItem: MenuItem
{
	id flag;
}
- (id) initWithText:(string)txt flagObject:(id)flg;
@end

@interface CommandMenuItem: MenuItem
{
	id object;
	SEL selector;
}
- (id) initWithText:(string)txt object:(id)obj selector:(SEL)sel;
@end

@interface ImpulseMenu: Object
{
	string text;
}
- (id) initWithText:(string)txt;
- (integer) impulse:(integer)imp;
- (string) text;
@end

@interface ImpulseValueMenu: ImpulseMenu
{
	integer value;
}
@end

@interface ImpulseListMenu: ImpulseMenu
{
	MenuItem [10]items;
}
- (void) addItem:(MenuItem)item;
@end

#endif//__impulse_menu_h
