%option noyywrap
%option yylineno
%option nounput

%{
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <unistd.h>
#include "ast.h"
#include "error.h"
#include "parser.tab.h"

static int ret_tok(const char *name, int tok)
{
    yylval.node = new_token(name, yytext, yylineno);
    return tok;
}

int comment_line_start = 0;
%}

%x COMMENT

DIGIT      [0-9]
LETTER     [A-Za-z_]

INT10      0|([1-9][0-9]*)
INT8       0[0-7]+
INT16      0[xX][0-9a-fA-F]+
INT        ({INT16}|{INT8}|{INT10})

FLOATA     {DIGIT}+\.{DIGIT}*([eE][+-]?{DIGIT}+)?
FLOATB     \.{DIGIT}+([eE][+-]?{DIGIT}+)?
FLOATC     {DIGIT}+[eE][+-]?{DIGIT}+
FLOAT      ({FLOATA}|{FLOATB}|{FLOATC})

ID         {LETTER}({LETTER}|{DIGIT}|_)*

%%

[ \t\r]+                       { /* 忽略空白字符，但不包括换行符 */ }
\n                             { /* 让flex自动处理换行符，不手动增加yylineno */ }

"//".*                         { /* 单行注释 */ }
"/*"                           { 
                                   comment_line_start = yylineno; 
                                   BEGIN(COMMENT); 
                               }

<COMMENT>"*/"                  { BEGIN(INITIAL); }
<COMMENT>\n                    { /* 在注释中不手动增加yylineno */ }
<COMMENT>.                     { /* 忽略注释内容 */ }
<COMMENT><<EOF>>               { 
                                   fprintf(stderr, "Error: Unterminated comment started at line %d\n", 
                                           comment_line_start);
                                   exit(1);
                               }

"int"                          { return ret_tok("TYPE",   TYPE); }
"float"                        { return ret_tok("TYPE",   TYPE); }
"struct"                       { return ret_tok("STRUCT", STRUCT); }
"return"                       { return ret_tok("RETURN", RETURN); }
"if"                           { return ret_tok("IF",     IF   ); }
"else"                         { return ret_tok("ELSE",   ELSE ); }
"while"                        { return ret_tok("WHILE",  WHILE); }

{FLOAT}                        { return ret_tok("FLOAT",  FLOAT); }
{INT}                          { return ret_tok("INT",    INT  ); }
{ID}                           { return ret_tok("ID",     ID   ); }

"&&"                           { return ret_tok("AND",     AND); }
"||"                           { return ret_tok("OR",      OR ); }
"=="|"!="                      { return ret_tok("RELOP", RELOP); }
">="|"<="|">"|"<"              { return ret_tok("RELOP", RELOP); }
"="                            { return ret_tok("ASSIGNOP",ASSIGNOP); }
"+"                            { return ret_tok("PLUS",     PLUS); }
"-"                            { return ret_tok("MINUS",   MINUS); }
"*"                            { return ret_tok("STAR",     STAR); }
"/"                            { return ret_tok("DIV",       DIV); }
"!"                            { return ret_tok("NOT",       NOT); }
"."                            { return ret_tok("DOT",       DOT); }
";"                            { return ret_tok("SEMI",     SEMI); }
","                            { return ret_tok("COMMA",   COMMA); }
"("                            { return ret_tok("LP",         LP); }
")"                            { return ret_tok("RP",         RP); }
"["                            { return ret_tok("LB",         LB); }
"]"                            { return ret_tok("RB",         RB); }
"{"                            { return ret_tok("LC",         LC); }
"}"                            { return ret_tok("RC",         RC); }

.                              { lex_error(yylineno, "Mysterious character \"%s\"", yytext); }

%%
