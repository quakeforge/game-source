%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define YYDEBUG 1

struct menu_entry {
	char *name;
	int impulse, bit;

	char *func_name;
	char *number_name;

	float price;
	char *price_name;

	char *code_activate;
	char *code_strings;

	unsigned int type;
};

#define MAX_MENU_ENTRIES 4096
struct menu_entry menu_entries[MAX_MENU_ENTRIES];
int menu_entries_count = 0;
char *menu_name = NULL;

static char *gen_funcname(const char *str);
static char *gen_numbername(const char *str);
static char *gen_pricename(const char *str);
%}

%union {
	char *string;
	char *code;
	float number;
	struct menu_entry *entry;
}

%token STRING NUMBER TOK_DEFAULT CODE TOKEN
%type <string> STRING TOKEN
%type <number> NUMBER
%type <code> TOK_DEFAULT CODE code
%type <entry> entry

%%

file:	/* empty */						{ menu_name = NULL; }
	| { menu_entries_count = 0; } TOKEN '\n' menu_entries	{ menu_name = $2; YYACCEPT; }
	;

menu_entries:	  exp_entry			{}
		| menu_entries exp_entry	{}
	;

exp_entry:	  entry				{ $1->impulse = 0; }
		| NUMBER entry			{ $2->impulse = $1; }
	;

entry:	  STRING code code '\n' {
			if (menu_entries_count >= MAX_MENU_ENTRIES) YYERROR;
			memset(&menu_entries[menu_entries_count], 0, sizeof(*menu_entries));
			menu_entries[menu_entries_count].name = $1;
			menu_entries[menu_entries_count].func_name = gen_funcname($1);
			menu_entries[menu_entries_count].code_activate = $2;
			menu_entries[menu_entries_count].code_strings = $3;
			menu_entries[menu_entries_count].type = $2?1:0;
			$$ = &menu_entries[menu_entries_count];
			menu_entries_count++;
		}
	| STRING NUMBER code code '\n' {
			if (menu_entries_count >= MAX_MENU_ENTRIES) YYERROR;
			memset(&menu_entries[menu_entries_count], 0, sizeof(*menu_entries));
			menu_entries[menu_entries_count].name = $1;
			menu_entries[menu_entries_count].func_name = gen_funcname($1);
			menu_entries[menu_entries_count].number_name = gen_numbername($1);
			menu_entries[menu_entries_count].price = $2;
			menu_entries[menu_entries_count].price_name = gen_pricename($1);
			menu_entries[menu_entries_count].code_activate = $3;
			menu_entries[menu_entries_count].code_strings = $4;
			menu_entries[menu_entries_count].type = 2;
			$$ = &menu_entries[menu_entries_count];
			menu_entries_count++;
		}
	;

code:	/* empty */	{ $$ = NULL; }
	| TOK_DEFAULT
	| CODE
	;

%%

static char *gen_funcname(const char *str) {
	char *ret, *t, ch;
	
	ret = malloc(strlen(str) + 8 + 1);
	strcpy(ret, "k_menup_");
	for (t = ret + 8; *str; t++, str++) {
		ch = *str & ~0x80;
		if (ch >= 'A' && ch <= 'Z')
			*t = ch | 0x20;
		else if ((ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9'))
			*t = ch;
		else
			*t = '_';
	}
	*t = '\0';

	return ret;
}

static char *gen_numbername(const char *str) {
	char *ret, *t, ch;
	
	ret = malloc(strlen(str) + 2 + 6/* for _PRICE */ + 1);
	strcpy(ret, "K_");
	for (t = ret + 2; *str; t++, str++) {
		ch = *str & ~0x80;
		if (ch >= 'a' && ch <= 'z')
			*t = ch & ~0x20;
		else if ((ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9'))
			*t = ch;
		else
			*t = '_';
	}
	*t = '\0';
	
	return ret;
}

static char *gen_pricename(const char *str) {
	char *ret;
	
	ret = gen_numbername(str);
	strcat(ret, "_PRICE");

	return ret;
}

yyerror(char *s) {
	fprintf(stderr, "Parse error 000D!\n");
	exit(-1);
}
