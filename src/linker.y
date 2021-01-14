%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <regex.h>
#include <unistd.h>
#include <libgen.h>
#include <errno.h>
#include <limits.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "regex_util.h"
#include "path_util.h"

extern FILE *yyin;

const int dryrun;
const char* targetdir;

void yyerror(const char *str)
{
        fprintf(stderr,"error: %s\n",str);
	abort();
}
 
int yywrap()
{
        return 1;
} 
  
int main(int argc, char **argv)
{
	if (argc < 2) yyerror("missing file argument");
	yyin = fopen(argv[1], "r");
	if (!yyin) yyerror("Target file not found");
	targetdir = dirname(resolve_path(argv[1], NULL));
	printf("%s/%s\n", targetdir, argv[1]);

        yyparse();
} 

%}

%token NEWLINE LINK

%union
{
	char *string;
}

%token <string> FILEPATH

%%
statements:
	| statement
	| statements NEWLINE statement
	| statements NEWLINE
	;

statement:
	link_statement
	;

link_statement:
	LINK FILEPATH FILEPATH
	{ 
		const char *filesrc, *filetarget;
		filesrc = resolve_path(strip_quotations($2), targetdir);
		filetarget = path_relative_to(strip_quotations($3), targetdir);
		if (access(filesrc, F_OK) == 0) {
			if (is_symlink(filetarget)) {
				unlink(filetarget);
			}
			if (symlink(filesrc, filetarget) == 0) {
				printf("Created link %s --> %s)\n", filetarget, filesrc);
			} else {
				perror("");
				yyerror("Symlink could not be created");
			}	
		} else {
			yyerror("Source file does not exist!");
		}
	}
	;
%%
