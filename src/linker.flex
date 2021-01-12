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
#include "y.tab.h"

extern YYSTYPE yylval;
extern FILE *yyin;
extern void yyerror(const char *);
extern char *path_from_string(const char *);
%}

string     \"[^\"]*\" 

%x incl

%%
\n               { return NEWLINE; }
link             { return LINK; }
{string}         { yylval.string=strdup(yytext); printf("FILEPATH: %s\n", yytext); return FILEPATH; }

include          { BEGIN(incl); }
<incl>[ \t]*      /*eat whitespace*/
<incl>{string}   { 
	char *filename = path_from_string(yytext);
	printf("Including file %s...\n", filename);
	yyin = fopen(filename, "r");
	if (!yyin) {
		yyerror("Included file not found");
	}
	yypush_buffer_state(yy_create_buffer(yyin, YY_BUF_SIZE));
	BEGIN(INITIAL);
}
<<EOF>> {
	yypop_buffer_state();

	if ( !YY_CURRENT_BUFFER )
	{
		yyterminate();
	}
}

%%

