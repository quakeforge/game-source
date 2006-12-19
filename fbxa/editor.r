#include "impulse_menu.h"
#include "libfrikbot.h"
#include "string.h"
#include "PropertyList.h"
#include "qfile.h"
#include "editor.h"

@interface TeleportMenu: ImpulseValueMenu
@end

@interface NoclipFlag: Object <FlagMenuItem>
@end

@interface GodmodeFlag: Object <FlagMenuItem>
@end

@interface HoldSelectFlag: Object <FlagMenuItem>
@end

@interface DynamicFlag: Object <FlagMenuItem>
@end

@interface DynamicLinkFlag: Object <FlagMenuItem>
@end

@interface ConfirmationMenu: ImpulseListMenu
@end

@interface FlagCluster: Object <FlagMenuItem>
{
	integer mask;
}
- initWithMask:(integer)msk;
@end

@implementation TeleportMenu
-(id) init
{
	return [super initWithText:"-- Teleport to Way # --\n\n"
							   "Enter way number and press\n"
							   "impulse 104 to warp\n\n"
							   "Waypoint #"];
}

-(integer) impulse:(integer)imp
{
	local Waypoint way = NIL;
	if ((imp = [super impulse:imp]) == 104) {
		imp = 0;
		if (value)
			way = (Waypoint) [waypoint_array getItemAt:value - 1];
		value = 0;
		if (way)
			setorigin (@self, way.origin - @self.view_ofs);
		else
			sprint (@self, PRINT_HIGH, "No waypoint with that number\n");
		[EditorState main_menu];
	}
	return imp;
}
@end

@implementation NoclipFlag
-(integer) getState
{
	return @self.movetype == MOVETYPE_NOCLIP;
}

-(void) toggleState
{
	if (@self.movetype == MOVETYPE_NOCLIP)
		@self.movetype = MOVETYPE_WALK;
	else
		@self.movetype = MOVETYPE_NOCLIP;
}
@end

@implementation GodmodeFlag
-(integer) getState
{
	return !!(@self.flags & FL_GODMODE);
}

-(void) toggleState
{
	@self.flags ^= FL_GODMODE;
}
@end

@implementation HoldSelectFlag
-(integer) getState
{
	return [EditorState getHoldSelectState];
}

-(void) toggleState
{
	[EditorState toggleHoldSelectState];
}
@end

@implementation DynamicFlag
-(integer) getState
{
	return waypoint_mode == WM_EDITOR_DYNAMIC;
}

-(void) toggleState
{
	if (waypoint_mode == WM_EDITOR_DYNAMIC)
		waypoint_mode = WM_EDITOR;
	else
		waypoint_mode = WM_EDITOR_DYNAMIC;
}
@end

@implementation DynamicLinkFlag
-(integer) getState
{
	local integer mode = waypoint_mode;
	return mode == WM_EDITOR_DYNAMIC || mode == WM_EDITOR_DYNLINK;
}

-(void) toggleState
{
	if (waypoint_mode == WM_EDITOR_DYNLINK)
		waypoint_mode = WM_EDITOR;
	else
		waypoint_mode = WM_EDITOR_DYNLINK;
}
@end

@implementation FlagCluster
-(id) initWithMask:(integer)msk
{
	self = [super init];
	mask = msk;
}

-(integer) getState
{
	local Waypoint way = [EditorState current_way];
	if (!way)
		return 0;
	return !!(way.flags & mask);
}

-(void) toggleState
{
	local Waypoint way = [EditorState current_way];
	if (way)
		way.flags ^= mask;
}
@end

@implementation ConfirmationMenu
-(string) text
{
	text = [EditorState getConfirmText];
	return [super text];
}
@end

@static ImpulseListMenu main_menu;
@static ImpulseListMenu waypoint_menu;
@static ImpulseListMenu link_menu;
@static ImpulseListMenu ai_flags_menu;
@static ImpulseListMenu ai_flag2_menu;
@static ImpulseListMenu bot_menu;
@static ImpulseListMenu waylist_menu;

@static ConfirmationMenu confirm_menu;
@static TeleportMenu teleport_menu;

@static void init_menus (void)
{
	main_menu = [[ImpulseListMenu alloc]
				 initWithText:"-- Main Menu --"];
	waypoint_menu = [[ImpulseListMenu alloc]
					 initWithText:"-- Waypoint Management --"];
	link_menu = [[ImpulseListMenu alloc]
				 initWithText:"-- Link Management --"];
	ai_flags_menu = [[ImpulseListMenu alloc]
					initWithText:"-- AI Flag Management Menu --"];
	ai_flag2_menu = [[ImpulseListMenu alloc]
					initWithText:"-- AI Flag pg. 2 --"];
	bot_menu = [[ImpulseListMenu alloc]
				initWithText:"-- Bot Management Menu --"];
	waylist_menu = [[ImpulseListMenu alloc]
					initWithText:"-- Waylist Management --"];

	confirm_menu = [[ConfirmationMenu alloc] init];
	teleport_menu = [[TeleportMenu alloc] init];

	[main_menu addItem:[[CommandMenuItem alloc]
						initWithText:">>Waypoint Management"
						object:[EditorState class]
						selector:@selector(waypoint_menu)]];
	[main_menu addItem:[[CommandMenuItem alloc]
						initWithText:">>Link Management"
						object:[EditorState class]
						selector:@selector(link_menu)]];
	[main_menu addItem:[[CommandMenuItem alloc]
						initWithText:">>AI Flag Management"
						object:[EditorState class]
						selector:@selector(ai_flags_menu)]];
	[main_menu addItem:[[CommandMenuItem alloc]
						initWithText:">>Bot Management"
						object:[EditorState class]
						selector:@selector(bot_menu)]];
	[main_menu addItem:[[CommandMenuItem alloc]
						initWithText:">>Waylist Management"
						object:[EditorState class]
						selector:@selector(waylist_menu)]];
	[main_menu addItem:[[FlagMenuItem alloc]
						initWithText:"Noclip"
						flagObject:[[NoclipFlag alloc] init]]];
	[main_menu addItem:[[FlagMenuItem alloc]
						initWithText:"Godmode"
						flagObject:[[GodmodeFlag alloc] init]]];
	[main_menu addItem:[[FlagMenuItem alloc]
						initWithText:"Hold Select"
						flagObject:[[HoldSelectFlag alloc] init]]];
	[main_menu addItem:[[CommandMenuItem alloc]
						initWithText:"Teleport to Way #"
						object:[EditorState class]
						selector:@selector(teleport_to_way)]];
	[main_menu addItem:[[CommandMenuItem alloc]
						initWithText:"Close Menu"
						object:[EditorState class]
						selector:@selector(close_menu)]];

	[waypoint_menu addItem:[[CommandMenuItem alloc]
							initWithText:"Move Waypoint"
							object:[EditorState class]
							selector:@selector(move_waypoint)]];
	[waypoint_menu addItem:[[CommandMenuItem alloc]
							initWithText:"Delete Waypoint"
							object:[EditorState class]
							selector:@selector(delete_waypoint)]];
	[waypoint_menu addItem:[[CommandMenuItem alloc]
							initWithText:"Make Waypoint"
							object:[EditorState class]
							selector:@selector(make_waypoint)]];
	[waypoint_menu addItem:[[CommandMenuItem alloc]
							initWithText:"Make Waypoint + Link"
							object:[EditorState class]
							selector:@selector(make_waypoint_link)]];
	[waypoint_menu addItem:[[CommandMenuItem alloc]
							initWithText:"Make Way + Link X2"
							object:[EditorState class]
							selector:@selector(make_way_link_x2)]];
	[waypoint_menu addItem:[[CommandMenuItem alloc]
							initWithText:"Make Way + Telelink"
							object:[EditorState class]
							selector:@selector(make_way_telelink)]];
	[waypoint_menu addItem:[[CommandMenuItem alloc]
							initWithText:"Show waypoint info"
							object:[EditorState class]
							selector:@selector(show_waypoint_info)]];
	[waypoint_menu addItem:[[CommandMenuItem alloc]
							initWithText:">>Link Management"
							object:[EditorState class]
							selector:@selector(link_menu)]];
	[waypoint_menu addItem:[[CommandMenuItem alloc]
							initWithText:">>AI Flag Management"
							object:[EditorState class]
							selector:@selector(ai_flags_menu)]];
	[waypoint_menu addItem:[[CommandMenuItem alloc]
							initWithText:">>Main Menu"
							object:[EditorState class]
							selector:@selector(main_menu)]];

	[link_menu addItem:[[CommandMenuItem alloc]
						initWithText:"Unlink Waypoint"
						object:[EditorState class]
						selector:@selector(unlink_waypoint)]];
	[link_menu addItem:[[CommandMenuItem alloc]
						initWithText:"Create Link"
						object:[EditorState class]
						selector:@selector(create_link)]];
	[link_menu addItem:[[CommandMenuItem alloc]
						initWithText:"Create Telelink"
						object:[EditorState class]
						selector:@selector(create_telelink)]];
	[link_menu addItem:[[CommandMenuItem alloc]
						initWithText:"Delete Link"
						object:[EditorState class]
						selector:@selector(delete_link)]];
	[link_menu addItem:[[CommandMenuItem alloc]
						initWithText:"Create Link X2"
						object:[EditorState class]
						selector:@selector(create_link_x2)]];
	[link_menu addItem:[[CommandMenuItem alloc]
						initWithText:"Delete Link X2"
						object:[EditorState class]
						selector:@selector(delete_link_x2)]];
	[link_menu addItem:[[CommandMenuItem alloc]
						initWithText:"Make Waypoint"
						object:[EditorState class]
						selector:@selector(make_waypoint)]];
	[link_menu addItem:[[CommandMenuItem alloc]
						initWithText:">>Waypoint Management"
						object:[EditorState class]
						selector:@selector(waypoint_menu)]];
	[link_menu addItem:[[CommandMenuItem alloc]
						initWithText:">>AI Flag Management"
						object:[EditorState class]
						selector:@selector(ai_flags_menu)]];
	[link_menu addItem:[[CommandMenuItem alloc]
						initWithText:">>Main Menu"
						object:[EditorState class]
						selector:@selector(main_menu)]];

	[ai_flags_menu addItem:[[FlagMenuItem alloc]
							initWithText:"Door Flag"
							flagObject:[[FlagCluster alloc]
										initWithMask:AI_DOORFLAG]]];
	[ai_flags_menu addItem:[[FlagMenuItem alloc]
							initWithText:"Precision"
							flagObject:[[FlagCluster alloc]
										initWithMask:AI_PRECISION]]];
	[ai_flags_menu addItem:[[FlagMenuItem alloc]
							initWithText:"Surface for Air"
							flagObject:[[FlagCluster alloc]
										initWithMask:AI_SURFACE]]];
	[ai_flags_menu addItem:[[FlagMenuItem alloc]
							initWithText:"Blind mode"
							flagObject:[[FlagCluster alloc]
										initWithMask:AI_BLIND]]];
	[ai_flags_menu addItem:[[FlagMenuItem alloc]
							initWithText:"Jump"
							flagObject:[[FlagCluster alloc]
										initWithMask:AI_JUMP]]];
	[ai_flags_menu addItem:[[FlagMenuItem alloc]
							initWithText:"Directional"
							flagObject:[[FlagCluster alloc]
										initWithMask:AI_DIRECTIONAL]]];
	[ai_flags_menu addItem:[[FlagMenuItem alloc]
							initWithText:"Super Jump"
							flagObject:[[FlagCluster alloc]
										initWithMask:AI_SUPER_JUMP]]];
	[ai_flags_menu addItem:[[MenuItem alloc] initWithText:""]];
	[ai_flags_menu addItem:[[CommandMenuItem alloc]
							initWithText:">>AI Flags page 2"
							object:[EditorState class]
							selector:@selector(ai_flag2_menu)]];
	[ai_flags_menu addItem:[[CommandMenuItem alloc]
							initWithText:">>Main Menu"
							object:[EditorState class]
							selector:@selector(main_menu)]];

	[ai_flag2_menu addItem:[[FlagMenuItem alloc]
							initWithText:"Difficult"
							flagObject:[[FlagCluster alloc]
										initWithMask:AI_DIFFICULT]]];
	[ai_flag2_menu addItem:[[FlagMenuItem alloc]
							initWithText:"Wait for plat"
							flagObject:[[FlagCluster alloc]
										initWithMask:AI_PLAT_BOTTOM]]];
	[ai_flag2_menu addItem:[[FlagMenuItem alloc]
							initWithText:"Ride train"
							flagObject:[[FlagCluster alloc]
										initWithMask:AI_RIDE_TRAIN]]];
	[ai_flag2_menu addItem:[[FlagMenuItem alloc]
							initWithText:"Door flag no open"
							flagObject:[[FlagCluster alloc]
										initWithMask:AI_DOOR_NO_OPEN]]];
	[ai_flag2_menu addItem:[[FlagMenuItem alloc]
							initWithText:"Ambush"
							flagObject:[[FlagCluster alloc]
										initWithMask:AI_AMBUSH]]];
	[ai_flag2_menu addItem:[[FlagMenuItem alloc]
							initWithText:"Snipe"
							flagObject:[[FlagCluster alloc]
										initWithMask:AI_SNIPER]]];
	[ai_flag2_menu addItem:[[FlagMenuItem alloc]
							initWithText:"Trace Test"
							flagObject:[[FlagCluster alloc]
										initWithMask:AI_TRACE_TEST]]];
	[ai_flag2_menu addItem:[[MenuItem alloc] initWithText:""]];
	[ai_flag2_menu addItem:[[CommandMenuItem alloc]
							initWithText:">>AI Flags page 2"
							object:[EditorState class]
							selector:@selector(ai_flag2_menu)]];
	[ai_flag2_menu addItem:[[CommandMenuItem alloc]
							initWithText:">>Main Menu"
							object:[EditorState class]
							selector:@selector(main_menu)]];

	[bot_menu addItem:[[CommandMenuItem alloc]
					   initWithText:"Add a Test Bot"
					   object:[EditorState class]
					   selector:@selector(add_test_bot)]];
	[bot_menu addItem:[[CommandMenuItem alloc]
					   initWithText:"Order Test Bot here"
					   object:[EditorState class]
					   selector:@selector(call_test_bot)]];
	[bot_menu addItem:[[CommandMenuItem alloc]
					   initWithText:"Remove Test Bot"
					   object:[EditorState class]
					   selector:@selector(remove_test_bot)]];
	[bot_menu addItem:[[CommandMenuItem alloc]
					   initWithText:"Stop Test Bot"
					   object:[EditorState class]
					   selector:@selector(stop_test_bot)]];
	[bot_menu addItem:[[CommandMenuItem alloc]
					   initWithText:"Teleport Bot here"
					   object:[EditorState class]
					   selector:@selector(teleport_bot)]];
	[bot_menu addItem:[[CommandMenuItem alloc]
					   initWithText:"Teleport to Way #"
					   object:[EditorState class]
					   selector:@selector(teleport_to_way)]];
	[bot_menu addItem:[[MenuItem alloc] initWithText:""]];
	[bot_menu addItem:[[MenuItem alloc] initWithText:""]];
	[bot_menu addItem:[[MenuItem alloc] initWithText:""]];
	[bot_menu addItem:[[CommandMenuItem alloc]
					   initWithText:">>Main Menu"
					   object:[EditorState class]
					   selector:@selector(main_menu)]];

	[waylist_menu addItem:[[CommandMenuItem alloc]
						   initWithText:"Delete ALL Waypoints"
						   object:[EditorState class]
						   selector:@selector(delete_all_waypoints)]];
	[waylist_menu addItem:[[CommandMenuItem alloc]
						   initWithText:"Dump Waypoints"
						   object:[EditorState class]
						   selector:@selector(dump_waypoints)]];
	[waylist_menu addItem:[[CommandMenuItem alloc]
						   initWithText:"Check For Errors"
						   object:[EditorState class]
						   selector:@selector(check_for_errors)]];
	[waylist_menu addItem:[[CommandMenuItem alloc]
						   initWithText:"Save Waypoints"
						   object:[EditorState class]
						   selector:@selector(save_waypoints)]];
	[main_menu addItem:[[FlagMenuItem alloc]
						initWithText:"Dynamic Mode"
						flagObject:[[DynamicFlag alloc] init]]];
	[main_menu addItem:[[FlagMenuItem alloc]
						initWithText:"Dynamic Link"
						flagObject:[[DynamicLinkFlag alloc] init]]];
	[waylist_menu addItem:[[MenuItem alloc] initWithText:""]];
	[waylist_menu addItem:[[MenuItem alloc] initWithText:""]];
	[waylist_menu addItem:[[MenuItem alloc] initWithText:""]];
	[waylist_menu addItem:[[MenuItem alloc] initWithText:""]];
	[waylist_menu addItem:[[MenuItem alloc] initWithText:""]];
	[waylist_menu addItem:[[CommandMenuItem alloc]
						   initWithText:">>Main Menu"
						   object:[EditorState class]
						   selector:@selector(main_menu)]];
	[confirm_menu addItem:[[CommandMenuItem alloc]
						   initWithText:"OK"
						   object:[EditorState class]
						   selector:@selector(confirm)]];
	[confirm_menu addItem:[[CommandMenuItem alloc]
						   initWithText:"Cancel"
						   object:[EditorState class]
						   selector:@selector(cancel)]];
}

@implementation EditorState: Object
+set_menu:(ImpulseMenu)item
{
	((Target) @self.@this).editor.menu = item;
	((Target) @self.@this).editor.menu_time = time;
}

+main_menu
{
	[EditorState set_menu: main_menu];
}

+waypoint_menu
{
	[EditorState set_menu: waypoint_menu];
}

+link_menu
{
	[EditorState set_menu: link_menu];
}

+ai_flags_menu
{
	[EditorState set_menu: ai_flags_menu];
}

+ai_flag2_menu
{
	[EditorState set_menu: ai_flag2_menu];
}

+bot_menu
{
	[EditorState set_menu: bot_menu];
}

+waylist_menu
{
	[EditorState set_menu: waylist_menu];
}

+teleport_to_way
{
	[EditorState set_menu: teleport_menu];
}

+close_menu
{
	[EditorState set_menu: NIL];
	[Waypoint hideAll];
	waypoint_mode = WM_LOADED;
}


+move_waypoint
{
	local EditorState editor = ((Target) @self.@this).editor;
	local Waypoint way = [editor current_way];
	if (way)
		[way setOrigin: @self.origin + @self.view_ofs];
}

+delete_waypoint
{
	local EditorState editor = ((Target) @self.@this).editor;
	local Waypoint way = [editor current_way];
	if (way) {
		editor.prev_menu = editor.menu;
		editor.confirm_text = "-- Delete Waypoint --\n\nAre you sure?";
		editor.confirm_cmd = "delete waypoitn";
		editor.menu = confirm_menu;
		editor.last_way = way;
	}
}

+make_waypoint
{
	[[Waypoint alloc] initAt: @self.origin + @self.view_ofs];
}

+make_waypoint_link
{
	local EditorState editor = ((Target) @self.@this).editor;
	local Waypoint way = [editor current_way];
	local Waypoint new = [[Waypoint alloc]
						  initAt: @self.origin + @self.view_ofs];
	if (!way || ![way linkWay: new])
		sprint (@self, PRINT_HIGH, "Unable to link them\n");
}

+make_way_link_x2
{
	local EditorState editor = ((Target) @self.@this).editor;
	local Waypoint way = [editor current_way];
	local Waypoint new = [[Waypoint alloc]
						  initAt: @self.origin + @self.view_ofs];
	if (!way || ![way linkWay: new])
		sprint (@self, PRINT_HIGH, "Unable to link old to new\n");
	if (!way || ![new linkWay: way])
		sprint (@self, PRINT_HIGH, "Unable to link new to old\n");
}

+make_way_telelink
{
	local EditorState editor = ((Target) @self.@this).editor;
	local Waypoint way = [editor current_way];
	local Waypoint new = [[Waypoint alloc]
						  initAt: @self.origin + @self.view_ofs];
	if (!way || ![way teleLinkWay: new])
		sprint (@self, PRINT_HIGH, "Unable to link them\n");
}

+show_waypoint_info
{
	local EditorState editor = ((Target) @self.@this).editor;
	local Waypoint way = [editor current_way];
	local integer i;
	if (!way)
		return self;
	sprint (@self, PRINT_HIGH,
			sprintf ("\nwaypoint info for waypoint #%i", [way id]));
	sprint (@self, PRINT_HIGH,
			sprintf ("\nAI Flag value: %#x", [way id]));
	for (i = 0; i < 4; i++) {
		if (!way.links[i])
			continue;
		sprint (@self, PRINT_HIGH,
				sprintf ("\n%s%d to: %i",
						 way.flags & (AI_TELELINK_1 << i) ? "Telelink" : "Link",
						 i + 1, [way.links[i] id]));
	}
	sprint (@self, PRINT_HIGH, "\n\n");
}


+unlink_waypoint
{
	local EditorState editor = ((Target) @self.@this).editor;
	local Waypoint way = [editor current_way];
	if (way)
		[way clearLinks];
}

+create_link
{
	local EditorState editor = ((Target) @self.@this).editor;
	local Waypoint way = [editor current_way];
	if (way) {
		editor.prev_menu = editor.menu;
		editor.confirm_text = "-- Link Ways --\n\nSelect another way";
		editor.confirm_cmd = "link ways";
		editor.menu = confirm_menu;
		editor.last_way = way;
	}
}

+create_telelink
{
	local EditorState editor = ((Target) @self.@this).editor;
	local Waypoint way = [editor current_way];
	if (way) {
		editor.prev_menu = editor.menu;
		editor.confirm_text = "-- Telelink Ways --\n\nSelect another way";
		editor.confirm_cmd = "telelink ways";
		editor.menu = confirm_menu;
		editor.last_way = way;
	}
}

+delete_link
{
	local EditorState editor = ((Target) @self.@this).editor;
	local Waypoint way = [editor current_way];
	if (way) {
		editor.prev_menu = editor.menu;
		editor.confirm_text = "-- Delete Link --\n\nSelect another way";
		editor.confirm_cmd = "delete link";
		editor.menu = confirm_menu;
		editor.last_way = way;
	}
}

+create_link_x2
{
	local EditorState editor = ((Target) @self.@this).editor;
	local Waypoint way = [editor current_way];
	if (way) {
		editor.prev_menu = editor.menu;
		editor.confirm_text = "-- Create Link X2 --\n\nSelect another way";
		editor.confirm_cmd = "create link x2";
		editor.menu = confirm_menu;
		editor.last_way = way;
	}
}

+delete_link_x2
{
	local EditorState editor = ((Target) @self.@this).editor;
	local Waypoint way = [editor current_way];
	if (way) {
		editor.prev_menu = editor.menu;
		editor.confirm_text = "-- Delete Link X2 --\n\nSelect another way";
		editor.confirm_cmd = "delete link x2";
		editor.menu = confirm_menu;
		editor.last_way = way;
	}
}


+add_test_bot
{
	local EditorState editor = ((Target) @self.@this).editor;
	local integer f;
	local string h;

	if (editor.test_bot) {
		sprint (@self, PRINT_HIGH, "already have test bot\n");
		return self;
	}
	h = infokey (NIL, "skill");
	f = (integer) stof (h);
	editor.test_bot = BotConnect (0, f);
}

+call_test_bot
{
	local EditorState editor = ((Target) @self.@this).editor;
	if (editor.test_bot)
		[editor.test_bot getPath:[Target forEntity:@self], TRUE];
}

+remove_test_bot
{
	local EditorState editor = ((Target) @self.@this).editor;
	if (editor.test_bot)
		[editor.test_bot disconnect];
}

+stop_test_bot
{
	local EditorState editor = ((Target) @self.@this).editor;
	if (editor.test_bot) {
		[editor.test_bot targetClearAll];
		route_table = NIL;
	}
}

+teleport_bot
{
	local EditorState editor = ((Target) @self.@this).editor;
	local Waypoint way = [editor current_way];
	if (way && editor.test_bot)
		setorigin (editor.test_bot.ent, [way origin]);
	if (!way)
		sprint(@self, PRINT_HIGH, "select a waypoint first\n");
}


+delete_all_waypoints
{
	local EditorState editor = ((Target) @self.@this).editor;
	editor.prev_menu = editor.menu;
	editor.confirm_text = "-- Delete ALL Ways --\n\nAre you sure?";
	editor.confirm_cmd = "delete all ways";
	editor.menu = confirm_menu;
}

+dump_waypoints
{
	local PLItem plist = [Waypoint plist];
	bprint (PRINT_HIGH, [plist write]);
	bprint (PRINT_HIGH, "\n");
	[plist release];
}

+check_for_errors
{
	[Waypoint check:[Target forEntity:@self]];
}

+save_waypoints
{
	local QFile file;
	local PLItem plist;

	file = Qopen ("temp.way", "wt");
	if (!file) {
		sprint (@self, PRINT_HIGH, "cound not create file temp.way\n");
		return self;
	}
	plist = [Waypoint plist];
	Qputs (file, [plist write]);
	[plist release];
	Qclose (file);
	sprint (@self, PRINT_HIGH, "waypoints saved to temp.way\n");
}


+confirm
{
	local EditorState editor = ((Target) @self.@this).editor;
	switch (editor.confirm_cmd) {
	case "link ways":
		if (editor.current_way) {
			if (![editor.last_way linkWay:editor.current_way])
				sprint (@self, PRINT_HIGH, "Unable to link them\n");
		}
		break;
	case "telelink ways":
		if (editor.current_way) {
			if (![editor.last_way teleLinkWay:editor.current_way])
				sprint (@self, PRINT_HIGH, "Unable to link them\n");
		}
		break;
	case "delete link":
		if (editor.current_way) {
			[editor.last_way unlinkWay:editor.current_way];
		}
		break;
	case "create link x2":
		if (editor.current_way) {
			if (![editor.last_way teleLinkWay:editor.current_way])
				sprint (@self, PRINT_HIGH, "Unable to link 1 to 2\n");
			if (![editor.current_way teleLinkWay:editor.last_way])
				sprint (@self, PRINT_HIGH, "Unable to link 2 to 1\n");
		}
		break;
	case "delete link x2":
		if (editor.current_way) {
			[editor.last_way unlinkWay:editor.current_way];
			[editor.current_way unlinkWay:editor.last_way];
		}
		break;
	case "delete all ways":
		[Waypoint clearAll];
		editor.current_way = editor.last_way = NIL;
		break;
	case "delete waypoint":
		[waypoint_array removeItem:editor.last_way];
		if (editor.current_way == editor.last_way)
			editor.current_way = NIL;
		editor.last_way = NIL;
		break;
	}
	editor.menu = editor.prev_menu;
}

+cancel
{
	local EditorState editor = ((Target) @self.@this).editor;
	editor.menu = editor.prev_menu;
}


+(integer)getHoldSelectState
{
	local EditorState editor = ((Target) @self.@this).editor;
	return editor.hold_select != 0;
}

+(void)toggleHoldSelectState
{
	local EditorState editor = ((Target) @self.@this).editor;
	editor.hold_select = !editor.hold_select;
}

+(string)getConfirmText
{
	local EditorState editor = ((Target) @self.@this).editor;
	return editor.confirm_text;
}

+(Waypoint)current_way
{
	local EditorState editor = ((Target) @self.@this).editor;
	return editor.current_way;
}

+(void)impulse
{
	local Target player = (Target) @self.@this;
	local EditorState editor = player.editor;

	if (!editor) {
		dprint ("start editor");
		if (@self.impulse != 104)
			return;
		player.editor = [[EditorState alloc] init];
		[EditorState main_menu];
		@self.impulse = 0;
		return;
	}
	@self.impulse = [editor.menu impulse:@self.impulse];
	if (editor.menu_time < time) {
		centerprint (@self, [editor.menu text]);
		editor.menu_time = time + 1.25;
	}
}

-(id)init
{
	if (!main_menu)
		init_menus ();
	self = [super init];
	waypoint_mode = WM_EDITOR;
	[Waypoint showAll];
	return self;
}

@end
