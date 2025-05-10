#ifndef ERROR_H
#define ERROR_H

void lex_error(int line, const char *fmt, ...);
void syn_error(int line, const char *fmt, ...);

extern int error_occurred;      /* 任一阶段出错置 1 */

#endif
