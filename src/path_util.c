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
#include "path_util.h"
#include "regex_util.h"

extern void yyerror(const char *str);

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
	if (*path == '/') return (char *) path;
	
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
	return regex_subst("\"", (char *) string_const, quote_sub);
}

int is_symlink(const char *filename)
{
	struct stat p_statbuf;
	if (lstat(filename, &p_statbuf) < 0) {
		return 0;
	}

	return S_ISLNK(p_statbuf.st_mode);
}
