%code requires {
#include "ast.h"
}
%{
#include <stdio.h>
#include "error.h"
%}


//%define parse.error verbose
%locations
%parse-param { Node **root }
%expect 37

%union { Node *node; }

%token <node> ID INT FLOAT TYPE
%token <node> SEMI COMMA
%token <node> ASSIGNOP RELOP
%token <node> PLUS MINUS STAR DIV DOT
%token <node> AND OR NOT
%token <node> LP RP LB RB LC RC
%token <node> STRUCT RETURN IF ELSE WHILE

/* ---------- non-terminal ---------- */
%type <node> Program ExtDefList ExtDef ExtDecList Specifier StructSpecifier
%type <node> OptTag Tag VarDec FunDec VarList ParamDec CompSt
%type <node> StmtList Stmt DefList Def DecList Dec Exp Args

/* ---------- 优先级 ---------- */
%left OR
%left AND
%left RELOP
%left PLUS MINUS
%left STAR DIV
%right NOT UMINUS
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

Program
    : ExtDefList      { *root = new_nonterm("Program", @1.first_line, 1, $1); }
    ;

ExtDefList
    : ExtDef ExtDefList { $$ = new_nonterm("ExtDefList", @1.first_line, 2, $1, $2); }
    |                   { $$ = NULL; }
    ;

ExtDef
    : Specifier ExtDecList SEMI { $$ = new_nonterm("ExtDef", @1.first_line, 3, $1, $2, $3); }
    | Specifier SEMI            { $$ = new_nonterm("ExtDef", @1.first_line, 2, $1, $2); }
    | Specifier FunDec CompSt   { $$ = new_nonterm("ExtDef", @1.first_line, 3, $1, $2, $3); }
    ;

ExtDecList
    : VarDec                    { $$ = new_nonterm("ExtDecList", @1.first_line, 1, $1); }
    | VarDec COMMA ExtDecList   { $$ = new_nonterm("ExtDecList", @1.first_line, 3, $1, $2, $3); }
    ;

Specifier
    : TYPE              { $$ = new_nonterm("Specifier", @1.first_line, 1, $1); }
    | StructSpecifier   { $$ = new_nonterm("Specifier", @1.first_line, 1, $1); }
    ;

StructSpecifier
    : STRUCT OptTag LC DefList RC { $$ = new_nonterm("StructSpecifier", @1.first_line, 5, $1,$2,$3,$4,$5); }
    | STRUCT Tag                  { $$ = new_nonterm("StructSpecifier", @1.first_line, 2, $1,$2); }
    ;

OptTag
    : ID  { $$ = new_nonterm("OptTag", @1.first_line, 1, $1); }
    |     { $$ = NULL; }
    ;

Tag
    : ID  { $$ = new_nonterm("Tag", @1.first_line, 1, $1); }
    ;

VarDec
    : ID                     { $$ = new_nonterm("VarDec", @1.first_line, 1, $1); }
    | VarDec LB INT RB       { $$ = new_nonterm("VarDec", @1.first_line, 4, $1,$2,$3,$4); }
    ;

FunDec
    : ID LP VarList RP       { $$ = new_nonterm("FunDec", @1.first_line, 4, $1,$2,$3,$4); }
    | ID LP RP               { $$ = new_nonterm("FunDec", @1.first_line, 3, $1,$2,$3); }
    ;

VarList
    : ParamDec COMMA VarList { $$ = new_nonterm("VarList", @1.first_line, 3, $1,$2,$3); }
    | ParamDec               { $$ = new_nonterm("VarList", @1.first_line, 1, $1); }
    ;

ParamDec
    : Specifier VarDec       { $$ = new_nonterm("ParamDec", @1.first_line, 2, $1,$2); }
    ;

CompSt
    : LC DefList StmtList RC { $$ = new_nonterm("CompSt", @1.first_line, 4, $1,$2,$3,$4); }
    ;

StmtList
    : Stmt StmtList          { $$ = new_nonterm("StmtList", @1.first_line, 2, $1,$2); }
    |                        { $$ = NULL; }
    ;

Stmt
    : Exp SEMI                        { $$ = new_nonterm("Stmt", @1.first_line, 2, $1,$2); }
    | Exp error                       { extern int yylineno; syn_error(yylineno, "Missing \";\"."); }
    | CompSt                          { $$ = new_nonterm("Stmt", @1.first_line, 1, $1); }
    | RETURN Exp SEMI                 { $$ = new_nonterm("Stmt", @1.first_line, 3, $1,$2,$3); }
    | IF LP Exp RP Stmt  %prec LOWER_THAN_ELSE { $$ = new_nonterm("Stmt", @1.first_line, 5, $1,$2,$3,$4,$5); }
    | IF LP Exp RP Stmt ELSE Stmt     { $$ = new_nonterm("Stmt", @1.first_line, 7, $1,$2,$3,$4,$5,$6,$7); }
    | WHILE LP Exp RP Stmt            { $$ = new_nonterm("Stmt", @1.first_line, 5, $1,$2,$3,$4,$5); }
    ;

DefList
    : Def DefList            { $$ = new_nonterm("DefList", @1.first_line, 2, $1,$2); }
    |                        { $$ = NULL; }
    ;

Def
    : Specifier DecList SEMI { $$ = new_nonterm("Def", @1.first_line, 3, $1,$2,$3); }
    ;

DecList
    : Dec                    { $$ = new_nonterm("DecList", @1.first_line, 1, $1); }
    | Dec COMMA DecList      { $$ = new_nonterm("DecList", @1.first_line, 3, $1,$2,$3); }
    ;

Dec
    : VarDec                 { $$ = new_nonterm("Dec", @1.first_line, 1, $1); }
    | VarDec ASSIGNOP Exp    { $$ = new_nonterm("Dec", @1.first_line, 3, $1,$2,$3); }
    ;

Exp
    : Exp ASSIGNOP Exp       { $$ = new_nonterm("Exp", @1.first_line, 3, $1,$2,$3); }
    | Exp AND Exp            { $$ = new_nonterm("Exp", @1.first_line, 3, $1,$2,$3); }
    | Exp OR  Exp            { $$ = new_nonterm("Exp", @1.first_line, 3, $1,$2,$3); }
    | Exp RELOP Exp          { $$ = new_nonterm("Exp", @1.first_line, 3, $1,$2,$3); }
    | Exp PLUS Exp           { $$ = new_nonterm("Exp", @1.first_line, 3, $1,$2,$3); }
    | Exp MINUS Exp          { $$ = new_nonterm("Exp", @1.first_line, 3, $1,$2,$3); }
    | Exp STAR Exp           { $$ = new_nonterm("Exp", @1.first_line, 3, $1,$2,$3); }
    | Exp DIV  Exp           { $$ = new_nonterm("Exp", @1.first_line, 3, $1,$2,$3); }
    | LP Exp RP              { $$ = new_nonterm("Exp", @1.first_line, 3, $1,$2,$3); }
    | MINUS Exp %prec UMINUS { $$ = new_nonterm("Exp", @1.first_line, 2, $1,$2); }
    | NOT Exp                { $$ = new_nonterm("Exp", @1.first_line, 2, $1,$2); }
    | ID LP Args RP          { $$ = new_nonterm("Exp", @1.first_line, 4, $1,$2,$3,$4); }
    | ID LP RP               { $$ = new_nonterm("Exp", @1.first_line, 3, $1,$2,$3); }
    | Exp LB Exp RB          { $$ = new_nonterm("Exp", @1.first_line, 4, $1,$2,$3,$4); }
    | Exp DOT ID             { $$ = new_nonterm("Exp", @1.first_line, 3, $1,$2,$3); }
    | Exp LB error RB        { extern int yylineno;syn_error(yylineno, "Missing \"]\".");}
    | ID                     { $$ = new_nonterm("Exp", @1.first_line, 1, $1); }
    | INT                    { $$ = new_nonterm("Exp", @1.first_line, 1, $1); }
    | FLOAT                  { $$ = new_nonterm("Exp", @1.first_line, 1, $1); }
    ;

Args
    : Exp COMMA Args         { $$ = new_nonterm("Args", @1.first_line, 3, $1,$2,$3); }
    | Exp                    { $$ = new_nonterm("Args", @1.first_line, 1, $1); }
    ;

%%

void yyerror(YYLTYPE *loc, Node **root, const char *msg)
{
    // extern int yylineno;
    // syn_error(yylineno, "%s", msg);
}
