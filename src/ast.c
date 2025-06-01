#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include "ast.h"
#include "utils.h"

static Node *make_node(const char *name, const char *text, int line, NodeKind k) {
    Node *p = (Node *)calloc(1, sizeof(Node));
    p->name = strdup_s(name);
    p->text = text ? strdup_s(text) : NULL;
    p->line = line;
    p->kind = k;
    return p;
}

Node *new_token(const char *name, const char *yytext, int line) {
    return make_node(name, yytext, line, NODE_TOKEN);
}

Node *new_nonterm(const char *name, int line, int num, ...) {
    Node *p = make_node(name, NULL, line, NODE_NONTERM);
    va_list ap; va_start(ap, num);
    Node *prev = NULL;
    for (int i = 0; i < num; ++i) {
        Node *c = va_arg(ap, Node *);
        if (!c) continue;
        if (!p->child) p->child = c;
        else prev->sibling = c;
        prev = c;
    }
    va_end(ap);
    return p;
}

static void print_indent(int d) { while (d--) printf("  "); }

static int get_first_line(Node *r) {
    if (!r) return 1;
    
    if (r->kind == NODE_TOKEN) {
        return r->line;
    }
    
    for (Node *c = r->child; c; c = c->sibling) {
        int line = get_first_line(c);
        if (line > 0) return line;
    }
    
    return 1;
}

void preorder_print(Node *r, int dep) {
    if (!r) return;
    if (r->kind == NODE_NONTERM) {
        int line = get_first_line(r);
        printf("%*s%s (%d)\n", dep * 2, "", r->name, line);
    } else { /* token */
        if (strcmp(r->name, "ID") == 0 || strcmp(r->name, "TYPE") == 0 ||
            strcmp(r->name, "INT") == 0 || strcmp(r->name, "FLOAT") == 0)
            printf("%*s%s: %s\n", dep * 2, "", r->name, r->text);
        else
            printf("%*s%s\n", dep * 2, "", r->name);
    }
    for (Node *c = r->child; c; c = c->sibling)
        preorder_print(c, dep + 1);
}

void free_tree(Node *r) {
    if (!r) return;
    free_tree(r->child);
    free_tree(r->sibling);
    free(r->name);
    if (r->text) free(r->text);
    free(r);
}
