%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>
#include <errno.h>
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
int is_symlink(const char *);

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

char *resolve_path(const char *path, const char *relative_to)
{
	char *result = malloc(1000);
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
	
	int len = strlen(path) + strlen(dir) + 1;
	char *result; 

	result = malloc(len);
	
	return strcat(strcat(strcpy(result, dir), "/"), path);
}

char *path_from_string(const char *string_const)
{
	char *result = resolve_path(strip_quotations(string_const), NULL);
	return result;
}

char *strip_quotations(const char *string_const)
{
	int len;
	char *target, *ptrsrc, *ptrtgt;
	len = strlen(string_const);
	target = (char *) malloc(len-2);
	ptrsrc = (char *) string_const;
	ptrtgt = target;

	for (; *ptrsrc != '\0'; ptrsrc++) {
		if (*ptrsrc != '"') {
			*(ptrtgt++) = *ptrsrc;
		}
	}
	*ptrtgt = '\0';
	return target;
}

int is_symlink(const char *filename)
{
	struct stat p_statbuf;
	if (lstat(filename, &p_statbuf) < 0) {
		yyerror("something went wrong calling lstat");
	}

	return S_ISLNK(p_statbuf.st_mode) == 1;
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
