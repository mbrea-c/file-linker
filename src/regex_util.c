#include <stdlib.h>
#include <string.h>
#include <regex.h>
#include "regex_util.h"

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
