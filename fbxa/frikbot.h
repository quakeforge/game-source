@extern void() BotInit;
@extern void() BotFrame;
@extern void() BotPreFrame;
@extern void () BotImpulses;
@extern void() ClientInRankings;
@extern void() ClientDisconnected;
@extern void() ClientFixRankings;

@extern void(entity	e) setspawnparms;
@extern vector(entity e, float sped) aim;
@extern void(entity e, float chan, string samp, float vol, float atten) sound;
