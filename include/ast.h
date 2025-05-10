#ifndef AST_H
#define AST_H

#include <stdio.h>

typedef enum { NODE_TOKEN, NODE_NONTERM } NodeKind;

typedef struct Node {
    char        *name;      /* 词法/语法单元名 */
    char        *text;      /* 额外信息：ID串/TYPE/int值/float值 */
    int          line;      /* 出现的行号：词法单元行号；语法单元最左孩子行号 */
    NodeKind     kind;
    struct Node *child;     /* 第一子结点 */
    struct Node *sibling;   /* 兄弟 */
} Node;

/* 构造 */
Node *new_token(const char *name, const char *yytext, int line);
Node *new_nonterm(const char *name, int line, int num, ...);

/* 打印 & 释放 */
void preorder_print(Node *root, int depth);
void free_tree(Node *root);

#endif
