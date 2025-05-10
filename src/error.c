#include <stdio.h>
#include <stdarg.h>
#include "error.h"

int error_occurred = 0;

static void vreport(const char *type, int line, const char *fmt, va_list ap) {
    printf("Error type %s at Line %d: ", type, line);
    vprintf(fmt, ap);
    puts(".");
    error_occurred = 1;
}

void lex_error(int line, const char *fmt, ...) {
    va_list ap; va_start(ap, fmt);
    vreport("A", line, fmt, ap);
    va_end(ap);
}

void syn_error(int line, const char *fmt, ...) {
    va_list ap; va_start(ap, fmt);
    vreport("B", line, fmt, ap);
    va_end(ap);
}
