/* vim: filetype=lex
 * Sample Scanner1: 
 * Description: Replace the string "username" from standard input 
 *              with the user's login name (e.g. lgao)
 * Usage: (1) $ flex sample1.lex
 *        (2) $ gcc lex.yy.c -lfl
 *        (3) $ ./a.out
 *            stdin> username
 *	      stdin> Ctrl-D
 * Question: What is the purpose of '%{' and '%}'?
 *           What else could be included in this section?
 */

%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <regex.h>
#include "y.tab.h"

extern YYSTYPE yylval;
extern FILE *yyin;
extern void yyerror(const char *);
extern char *path_from_string(const char *);
extern char *strip_quotations(const char *);
extern char *regex_subst(const char *regex, char *str, char *substitute(char *match));

char *envsubst(char *);
%}

string     \"[^\"]*\" 

%x incl
%x comment

%%
\n               { return NEWLINE; }
link             { return LINK; }
{string}         { yylval.string=envsubst(strip_quotations(yytext)); return FILEPATH; }
#                { BEGIN(comment); }
include          { BEGIN(incl); }
<<EOF>> {
	yypop_buffer_state();

	if ( !YY_CURRENT_BUFFER )
	{
		yyterminate();
	}
}

<incl>[ \t]*      /*eat whitespace*/
<incl>{string}   { 
	char *filename = path_from_string(envsubst(strip_quotations(yytext)));
	printf("Including file %s...\n", filename);
	yyin = fopen(filename, "r");
	if (!yyin) {
		yyerror("Included file not found");
	}
	yypush_buffer_state(yy_create_buffer(yyin, YY_BUF_SIZE));
	BEGIN(INITIAL);
}

<comment>[^\n]* {}
<comment>\n     { BEGIN(INITIAL); }

%%


char *sub(char *str) { 
	char *subst = getenv(str + 1);
	if (subst == NULL) 
		return "";
	else 
		return subst;
}

char *envsubst(char *str)
{
	const char *regex = "\\$([[:alnum:]_]+)";
	return regex_subst(regex, str, sub);
}
