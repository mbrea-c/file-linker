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

extern FILE *yyin;

const int dryrun;
const char* targetdir;

/*int yydebug=1;*/

char *strip_quotations(const char *);
char *resolve_path(const char *, const char *);
char *path_from_string(const char *);
char *path_relative_to(const char *, const char *);
char *regex_subst(const char *regex, char *str, char *substitute(char *match));

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

char *regex_subst(const char *regex, char *str, char *substitute(char *match))
{
	const int ngroups = 1;
	char *curr_str;

	/* First, compile regex */
	regex_t compiled;
	regcomp(&compiled, regex, REG_EXTENDED);

	/* Find number of capture groups and allocate memory */
	regmatch_t matches[ngroups];
	
	curr_str = strcpy(malloc(strlen(str)), str);
	while (regexec(&compiled, curr_str, ngroups, matches, 0) != REG_NOMATCH) {
		char str_copy[strlen(curr_str) + 1];  
		strcpy(str_copy, curr_str);
		str_copy[matches[0].rm_eo] = '\0'; 
		char *identifier = str_copy + matches[0].rm_so;

		char *replacement = substitute(identifier);
		const int new_str_len = strlen(curr_str) + (strlen(replacement) - strlen(identifier));
		char *new_str = malloc(new_str_len);
		strncpy(new_str, curr_str, new_str_len);
		new_str[matches[0].rm_so] = '\0'; // add null terminator
		strcat(new_str, replacement);
		strcat(new_str, curr_str + matches[0].rm_eo);
		free(curr_str);
		curr_str = new_str;
	}
	return curr_str;
}

char *resolve_path(const char *path, const char *relative_to)
{
	char *result = malloc(PATH_MAX);
	if (!relative_to) {
		realpath(path, result);
	} else {
		realpath(path_relative_to(path, relative_to), result);
	}
	if (!result) {
		char *err = malloc(100);
		snprintf(err, 100, "%s", strerror(errno));
		yyerror(err);
	}
	return result;
}

char *path_relative_to(const char *path, const char *dir)
{
	if (*path == '/') return path;
	
	int len = strlen(path) + strlen(dir) + 100;
	char *result; 

	result = malloc(len);
	strcpy(result, dir);
	strcat(result, "/");
	strcat(result, path);
	
	return result;
}

char *path_from_string(const char *string_const)
{
	char *result = resolve_path(strip_quotations(string_const), NULL);
	return result;
}

char *quote_sub(char *str) {
	return "";
}

char *strip_quotations(const char *string_const)
{
	return regex_subst("\"", string_const, quote_sub);
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
		    if (access(filetarget, F_OK) == 0) { //TODO: Ensure filetarget is symlink
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
