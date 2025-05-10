#include <stdio.h>
#include "ast.h"
#include "error.h"

extern int yyparse(Node **root);
extern FILE *yyin;

int main(int argc, char **argv) {
    if (argc <= 1) return 1;
    yyin = fopen(argv[1], "r");
    if (!yyin) { perror("open"); return 1; }

    Node *root = NULL;
    yyparse(&root);

    if (!error_occurred && root) preorder_print(root, 0);

    free_tree(root);
    fclose(yyin);
    return 0;
}
