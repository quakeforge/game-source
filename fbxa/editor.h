#ifndef __editor_h
#define __editor_h

@class ImpulseMenu;
@class Waypoint;
@class Bot;
@class Target;

@interface EditorState: Object
{
	ImpulseMenu *menu;
	ImpulseMenu *prev_menu;
	float menu_time;
	string confirm_text;
	string confirm_cmd;

	Target *owner;
	Waypoint *last_way;
	integer hold_select;
	Bot *test_bot;
	integer edit_mode;
}
+main_menu;
+waypoint_menu;
+link_menu;
+ai_flags_menu;
+ai_flag2_menu;
+bot_menu;
+waylist_menu;
+teleport_to_way;
+close_menu;

+move_waypoint;
+delete_waypoint;
+make_waypoint;
+make_waypoint_link;
+make_way_link_x2;
+make_way_telelink;
+show_waypoint_info;

+unlink_waypoint;
+create_link;
+create_telelink;
+delete_link;
+create_link_x2;
+delete_link_x2;

+add_test_bot;
+call_test_bot;
+remove_test_bot;
+stop_test_bot;
+teleport_bot;

+delete_all_waypoints;
+dump_waypoints;
+check_for_errors;
+save_waypoints;

+confirm;
+cancel;

+(integer)getHoldSelectState;
+(void)toggleHoldSelectState;
+(string)getConfirmText;
+(Waypoint *)current_way;
-(Waypoint *)current_way;

+(void)impulse;
-(id)initWithOwner:(Target *)owner;
-(void)refresh;
@end

#endif//__editor_h
