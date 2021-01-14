%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <regex.h>
#include "y.tab.h"
#include "path_util.h"
#include "regex_util.h"

extern YYSTYPE yylval;
extern FILE *yyin;
extern void yyerror(const char *);

char *envsubst(char *);
%}

string  	\"[^\"]*\" 

%x incl
%x comment

%%
\n 		{ return NEWLINE; }
link 		{ return LINK; }
{string} 	{ 
			yylval.string=envsubst(strip_quotations(yytext)); 
			return FILEPATH; 
		}
# 		{ BEGIN(comment); }
include 	{ BEGIN(incl); }
<<EOF>> 	{
			printf("Done with file\n");
			yypop_buffer_state();

			if ( !YY_CURRENT_BUFFER )
			{
				yyterminate();
			}
		}

<incl>[ \t]*      /* eat whitespace */
<incl>{string} 	{ 
			char *filename = path_from_string(envsubst(strip_quotations(yytext)));
			printf("Including file %s...\n", filename);
			yyin = fopen(filename, "r");
			if (!yyin) {
				yyerror("Included file not found");
			}
			yypush_buffer_state(yy_create_buffer(yyin, YY_BUF_SIZE));
			BEGIN(INITIAL);
		}

<comment>[^\n]* {} /* eat everything until end of line */
<comment>\n    	{ BEGIN(INITIAL); }
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
