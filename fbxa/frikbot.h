@extern void() BotInit;
@extern void() BotFrame;
@extern float () BotPreFrame;
@extern float () BotPostFrame;
@extern void() ClientInRankings;
@extern void() ClientDisconnected;
@extern void() ClientFixRankings;

@extern void(entity	e) setspawnparms;
@extern vector(entity e, float sped) aim;
@extern void(entity e, float chan, string samp, float vol, float atten) sound;
