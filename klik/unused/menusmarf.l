%{
#include <string.h>
#include "menusmarf.tab.c"

static char str_buf[16384], *str_buf_head;
static int caller, parens;
static int bronze;

static char *qccpy(char *buffer, const char *str);
%}

%s s_string
%s s_comment
%s s_code
%s s_code_string

%%

<INITIAL>{
	[-+]?([0-9]+\.?)|(\.[0-9]+)|([0-9]+\.[0-9]+)	yylval.number = atof(yytext); return NUMBER;
	default			yylval.string = NULL; return TOK_DEFAULT;
	[a-z0-9][a-z0-9_]*	yylval.string = strdup(yytext); return TOKEN;
	"{"			parens = 0; str_buf_head = str_buf; *str_buf_head++ = '{'; BEGIN(s_code);
	\"			str_buf_head = str_buf; bronze = 0; BEGIN(s_string);
}

<INITIAL,s_code>{
	"//".*\n
	"/*"			caller = YY_START; BEGIN(s_comment);
}

<s_comment>{
	[^*]+
	"*"+[^*/]*
	"*"+"/"		BEGIN(caller);
}

<s_code>{
	\"		bronze = 0; BEGIN(s_code_string);
	[^"{}]*		bronze = 0; str_buf_head = qccpy(str_buf_head, yytext);
	"{"		*str_buf_head++ = '{'; parens++;
	"}"		{
				*str_buf_head++ = '}';
				if (!parens--) {
					*str_buf_head = '\0';
					yylval.string = strdup(str_buf);
					BEGIN(INITIAL);
					return CODE;
				}
			}
}

<s_code_string>{
	\\.		str_buf_head = qccpy(str_buf_head, yytext);
	[^"]*		str_buf_head = qccpy(str_buf_head, yytext);
	\"		BEGIN(s_code);
}

<s_string>{
	\\b			bronze = !bronze;
	\\\{[0-9]{1,3}\}	*str_buf_head++ = atoi(yytext+2);
	\\\[			*str_buf_head++ = 0x10;
	\\\]			*str_buf_head++ = 0x11;
	\\\.			*str_buf_head++ = bronze?(0x1C|0x80):0x1C;
	\\<			*str_buf_head++ = 29;
	\\-			*str_buf_head++ = 30;
	\\>			*str_buf_head++ = 31;
	\\\(			*str_buf_head++ = 128;
	\\=			*str_buf_head++ = 129;
	\\\)			*str_buf_head++ = 130;
	\\.			*str_buf_head++ = bronze?(yytext[1]^0x80):yytext[1];
	[^"\\]*			str_buf_head = qccpy(str_buf_head, yytext);
	\"			{
					*str_buf_head = '\0';
					yylval.string = strdup(str_buf);
					BEGIN(INITIAL);
					return STRING;
				}
}

[ \t]*

(.|\n)			return *yytext;

<*><<EOF>>		return 0;

%%

static char *qccpy(char *buffer, const char *str) {
	while (*str) {
		if (bronze && (*str & ~0x80) > 32) *buffer++ = *str++ ^ 0x80;
		else *buffer++ = *str++;
	}
	*buffer = '\0';
	return buffer;
}

static char *bronzize(const char *str, int bronzetype) {
	static char *ret = NULL;
	char *tmp;
	
	if (ret) free(ret);
	tmp = ret = strdup(str);
	
	switch (bronzetype) {
	  case -1:
		while (*tmp) {
			if ((*tmp & ~0x80) > 32) *tmp++ &= ~0x80;
			else tmp++;
		}
		break;
	  case 0:
		while (*tmp) {
			if ((*tmp & ~0x80) > 32) *tmp++ ^= 0x80;
			else tmp++;
		}
		break;
	  case 1:
		while (*tmp) {
			if ((*tmp & ~0x80) > 32) *tmp++ |= 0x80;
			else tmp++;
		}
		break;
	}

	return ret;
}

yywrap() { return 1; }

static void writewrites(const char *str) {
	signed short shrt;
	while (str[0] && str[1]) {
		shrt = (str[0]&0xff) | (str[1] << 8);
		printf("\t\tWriteShort(MSG_ONE, %d);\n", shrt);
		str += 2;
	}

	if (*str)
		printf("\t\tWriteByte(MSG_ONE, %d);\n", (unsigned char)*str);
}

struct {
	const char *func_name;
	const char *def, *disabled, *selected, *unmangled;
} func_names[4096];
static char func_names_count = 0;
static int mungefunc(struct menu_entry *e, const char *def, const char *disabled, const char *selected, const char *unmangled) {
	int i, j;
	char *func1 = NULL, *func2 = NULL;

  do_over:
	for (i = 0; i < func_names_count; i++) {
		if ((func_names[i].def && !strcmp(func_names[i].def, def))
		 && ((!disabled && !func_names[i].disabled) || !strcmp(func_names[i].disabled, disabled))
		 && ((!selected && !func_names[i].selected) || !strcmp(func_names[i].selected, selected))
		 && ((!unmangled && !func_names[i].unmangled) || !strcmp(func_names[i].unmangled, unmangled))) {
			e->func_name = (char*)func_names[i].func_name;
			return 0;
		}
		
		if (!strcmp(func_names[i].func_name, e->func_name)) {
			if (!func1) {
				j = 2;
				func1 = e->func_name;
				func2 = malloc(strlen(e->func_name) + 10 + 1);
				e->func_name = func2;
			}

			sprintf(func2, "%s%d", func1, j);
			j++;
			
			goto do_over;
		}
	}
	
	func_names[i].func_name = e->func_name;
	func_names[i].def = strdup(def);
	func_names[i].disabled = disabled?strdup(disabled):NULL;
	func_names[i].selected = selected?strdup(selected):NULL;
	func_names[i].unmangled = unmangled?strdup(unmangled):NULL;
	func_names_count++;
	
	return 1;
}

static int writefunc(struct menu_entry *e, const char *def, const char *disabled, const char *selected, const char *unmangled) {
	if (!mungefunc(e, def, disabled, selected, unmangled)) return 0;

	printf("void(float type) %s = {\n", e->func_name);
	if (disabled || selected || unmangled)
		printf("\tif (type == K_DEFAULT) {\n");

	writewrites(def);

	if (disabled) {
		printf("\t} else if (type == K_DISABLED) {\n");
		writewrites(disabled);
	}
	if (selected) {
		printf("\t} else if (type == K_SELECTED) {\n");
		writewrites(selected);
	}
	if (unmangled) {
		printf("\t} else if (type == K_UNMANGLED) {\n");
		writewrites(unmangled);
	}
	if (disabled || selected || unmangled)
		printf("\t}\n");
	printf("}\n\n");
	
	return 1;
}

static const char default_activate_code[] =
	"{\n"
	"\t\tstatus = k_weapon_toggle(self, %1$s, %2$s);\n"
	"\t\tif (status == FALSE) bs = k_menup_sold_;\n"
	"\t\telse if (status == TRUE) bs = k_menup_bought_;\n"
	"\t\telse if (status == -1) bs = k_menup_can_t_afford_;\n"
	"\t\tselected = %3$s;\n"
	"\t}"
;

static const char default_strings_code[] =
	"{\n"
	"\tif (k_weapon_query(self, %1$s)) return K_SELECTED;\n"
	"\n"
	"\treturn K_DEFAULT;\n"
	"}"
;

int main(int argc, char *argv[]) {
	unsigned int i, j;
	unsigned int runwidth, thiswidth;
	unsigned int bit = 0;
	char buffer[4096];

	yydebug = 0;

	printf("/* This file was automatically generated by menusmarf */\n\n");

	func_names[0].func_name = "k_menup_begin";
	func_names[0].def = NULL;
	func_names_count++;
	printf(	"void() k_menup_begin = {\n"
		"\tmsg_entity = self;\n"
		"\tWriteByte(MSG_ONE, SVC_CENTERPRINT);\n"
		"}\n\n");

	func_names[1].func_name = "k_menup_end";
	func_names[1].def = NULL;
	func_names_count++;
	printf(	"void() k_menup_end = {\n"
		"\tWriteByte(MSG_ONE, 0);\n"
		"}\n\n");

	{
		struct menu_entry decor[] = {
			{ func_name: "k_menup_entry_begin" },
			{ func_name: "k_menup_entry_end" },
			{ func_name: "k_menup_bought_" },
			{ func_name: "k_menup_sold_" },
			{ func_name: "k_menup_points__" },
			{ func_name: "k_menup_can_t_afford_" },
		};

		writefunc(&decor[0], "\20  ", bronzize("[  ", 1), "\20 \274", NULL);
		writefunc(&decor[1], "  \21\n", bronzize("  ]\n", 1), "\276 \21\n", NULL);
		writefunc(&decor[2], bronzize("Bought ", 1), NULL, NULL, NULL);
		writefunc(&decor[3], bronzize("Sold ", 1), NULL, NULL, NULL);
		writefunc(&decor[4], "Points\272 ", NULL, NULL, NULL);
		writefunc(&decor[5], bronzize("Can't afford ", 1), NULL, NULL, NULL);
	}

	while (!yyparse() && menu_name) {
		for (i = 0; i < menu_entries_count; i++) {
			runwidth = 0;
	
			for (j = i; menu_entries[j].type == menu_entries[i].type; j++) {
				switch (menu_entries[j].type) {
				  case 0:
					continue; /* Don't need to pad. */
				  case 1:
					thiswidth = strlen(menu_entries[j].name);
					break;
				  case 2:
					thiswidth = strlen(menu_entries[j].name);
					break;
				}
				
				if (thiswidth > runwidth)
					runwidth = thiswidth;
			}
	
			for (j = i; menu_entries[j].type == menu_entries[i].type; j++) {
				switch (menu_entries[j].type) {
				  case 0:
					/* Don't need to pad. */
					snprintf(buffer, sizeof(buffer), "%s\n", menu_entries[j].name);
					writefunc(&menu_entries[j], buffer, NULL, NULL, NULL);

					menu_entries[j].bit = -1;
					break;
				  case 1:
					snprintf(buffer, sizeof(buffer), "%d. %-*s", menu_entries[j].impulse%10, runwidth, menu_entries[j].name);
					writefunc(&menu_entries[j], buffer, bronzize(buffer, 1), NULL, NULL);
					
					menu_entries[j].bit = -1;
					break;
				  case 2:
					printf("float %-30s = %d;\n", menu_entries[j].number_name, bit);
					printf("float %-30s = %.0f;\n", menu_entries[j].price_name, menu_entries[j].price);

					snprintf(buffer, sizeof(buffer), "%d\256 %-*s \234\34\234%6.0f", menu_entries[j].impulse%10, runwidth, menu_entries[j].name, menu_entries[j].price);
					writefunc(&menu_entries[j], buffer, bronzize(buffer, 1), buffer, menu_entries[j].name);

					menu_entries[j].bit = bit++;
					break;
				}
			}
	
			i = j-1;
		}

		for (i = 0; i < menu_entries_count; i++) {
			if (menu_entries[i].bit != -1 && !menu_entries[i].code_strings)
				menu_entries[i].code_strings = (char*)default_strings_code;

			if (menu_entries[i].code_strings) {
				printf("float() %s_%d = ", menu_name, i);
				printf(menu_entries[i].code_strings,
					menu_entries[i].number_name,
					menu_entries[i].price_name,
					menu_entries[i].func_name,
					menu_entries[i].name,
					menu_entries[i].impulse);
				printf(";\n\n");
			}
		}
		
		printf(	"float() %s = {\n"
			"\tlocal float status, nomenu;\n"
			"\tlocal void() bs;\n"
			"\tlocal void(float type) selected;\n"
			"\n"
			"\tnomenu = 0;\n"
			"\tbs = SUB_Null;\n"
			"\tselected = SUB_Null;\n"
			"\n", menu_name);
		for (i = 0; i < menu_entries_count; i++) {
			if (menu_entries[i].impulse) {
				printf("\tif (self.impulse == %d) ", menu_entries[i].impulse);
				snprintf(buffer, sizeof(buffer), default_activate_code,
					menu_entries[i].number_name,
					menu_entries[i].price_name,
					menu_entries[i].func_name,
					menu_entries[i].name,
					menu_entries[i].impulse);
				if (menu_entries[i].code_activate)
					printf(menu_entries[i].code_activate,
						menu_entries[i].number_name,
						menu_entries[i].price_name,
						menu_entries[i].func_name,
						menu_entries[i].name,
						menu_entries[i].impulse,
						buffer);
				else
					printf("%s", buffer);
				printf("\n");
			}
		}
		printf(	"\n"
			"\tif (nomenu || (!self.impulse && time < self.menu_time)) { self.impulse = 0; return TRUE; }\n"
			"\tself.menu_time = time + 1.4;\n"
			"\n"
			"\tself.impulse = 0;\n"
			"\n"
			"\tk_menup_begin();\n");

		for (i = 0; i < menu_entries_count; i++) {
			if (menu_entries[i].code_strings)
				printf(	"\tstatus = %s_%d();\n"
					"%s"
					"\t%s(status);\n"
					"%s",
					menu_name, i,
					menu_entries[i].type?"\tk_menup_entry_begin(status);\n":"",
					menu_entries[i].func_name,
					menu_entries[i].type?"\tk_menup_entry_end(status);\n":"");
					
			else
				printf(	"%s"
					"\t%s(K_DEFAULT);\n"
					"%s",
					menu_entries[i].type?"\tk_menup_entry_begin(K_DEFAULT);\n":"",
					menu_entries[i].func_name,
					menu_entries[i].type?"\tk_menup_entry_end(K_DEFAULT);\n":"");
		}
		
		printf(	"\tk_menu_status();\n"
			"\tif (bs != SUB_Null) {\n"
			"\t\tbs();\n"
			"\t\tselected(K_UNMANGLED);\n"
			"\t} else\n"
			"\t\tWriteByte(MSG_ONE, 10);\n"
			"\tk_menup_end();\n"
			"\n"
			"\treturn TRUE;"
			"\n"
			"}\n\n");
	}
}

