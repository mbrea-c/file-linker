#ifndef PATH_UTIL_H
#define PATH_UTIL_H

char *strip_quotations(const char *);
char *resolve_path(const char *, const char *);
char *path_from_string(const char *);
char *path_relative_to(const char *, const char *);
int is_symlink(const char *filename);

#endif /* PATH_UTIL_H */
