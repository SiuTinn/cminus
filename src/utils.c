#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "utils.h"

char *strdup_s(const char *s) {
    size_t n = strlen(s) + 1;
    char *p = (char *)malloc(n);
    if (!p) { perror("malloc"); exit(EXIT_FAILURE); }
    memcpy(p, s, n);
    return p;
}
