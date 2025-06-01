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

BAD_OCT    0[0-7]*[89][0-9]*
BAD_HEX1   0[xX][0-9a-fA-F]*[g-zG-Z][0-9a-zA-Z]*
BAD_HEX2   0[xX]
BAD_FLOAT1 {DIGIT}+\.{DIGIT}*[eE][+-]
BAD_FLOAT2 \.{DIGIT}+[eE][+-]
BAD_FLOAT3 {DIGIT}+[eE][+-]
BAD_FLOAT4 {DIGIT}+\.{DIGIT}*[eE]
BAD_FLOAT5 \.{DIGIT}+[eE]
BAD_FLOAT6 {DIGIT}+[eE]

ID         {LETTER}({LETTER}|{DIGIT})*

%%

[ \t\r]+                       {}
\n                             {}

"//".*                         {}
"/*"                           { 
                                   comment_line_start = yylineno; 
                                   BEGIN(COMMENT); 
                               }

<COMMENT>"*/"                  { BEGIN(INITIAL); }
<COMMENT>\n                    {}
<COMMENT>.                     {}
<COMMENT><<EOF>>               { 
                                   fprintf(stderr, "Error: Unterminated comment started at line %d\n", 
                                           comment_line_start);
                                   exit(1);
                               }

{BAD_OCT}                      { lex_error(yylineno, "Invalid octal number \"%s\"", yytext); }
{BAD_HEX1}                     { lex_error(yylineno, "Invalid hexadecimal number \"%s\"", yytext); }
{BAD_HEX2}                     { lex_error(yylineno, "Invalid hexadecimal number \"%s\"", yytext); }
{BAD_FLOAT1}                   { lex_error(yylineno, "Invalid floating point number \"%s\"", yytext); }
{BAD_FLOAT2}                   { lex_error(yylineno, "Invalid floating point number \"%s\"", yytext); }
{BAD_FLOAT3}                   { lex_error(yylineno, "Invalid floating point number \"%s\"", yytext); }
{BAD_FLOAT4}                   { lex_error(yylineno, "Invalid floating point number \"%s\"", yytext); }
{BAD_FLOAT5}                   { lex_error(yylineno, "Invalid floating point number \"%s\"", yytext); }
{BAD_FLOAT6}                   { lex_error(yylineno, "Invalid floating point number \"%s\"", yytext); }

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
