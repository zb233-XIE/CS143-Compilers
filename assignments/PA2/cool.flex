/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

static int CALLER_CONDITION;
static int STRING_CALLER;
%}

%option stack

/* exclusive conditions */
%x COMMENT
%x STRING
%x STRING_ESC

DARROW      =>
ASSIGN      <-
LE          <=

CLASS       [cC][lL][aA][sS][sS]
ELSE        [eE][lL][sS][eE]
FI          [fF][iI]
IF          [iI][fF]
IN          [iI][nN]
INHERITS    [iI][nN][hH][eE][rR][iI][tT][sS]
LET         [lL][eE][tT]
LOOP        [lL][oO][oO][pP]
POOL        [pP][oO][oO][lL]
THEN        [tT][hH][eE][nN]
WHILE       [wW][hH][iI][lL][eE]
CASE        [cC][aA][sS][eE]
ESAC        [eE][sS][aA][cC]
OF          [oO][fF]
NEW         [nN][eE][wW]
ISVOID      [iI][sS][vV][oO][iI][dD]
TRUE        t[rR][uU][eE]
FALSE       f[aA][lL][sS][eE]
NOT         [nN][oO][tT]

TYPEID      [A-Z][_0-9a-zA-Z]*
OBJECTID    [a-z][_0-9a-zA-Z]*

INT_CONST   [0-9]*

%%

 /* White Space */
[ \f\r\t\v]     {}
\n              {curr_lineno++;}

 /* Comments */

 /* Single line comment(until the next '\n') */
--.*/\n         {}

 /* multline comment */
 /* may be nested!!! */
"(*"            {
                  //cout << "***Comment Begin***" << curr_lineno << endl;
                  yy_push_state(COMMENT);
                  //CALLER_CONDITION = INITIAL;
                  //BEGIN(COMMENT);
                }
"*)"            {
                  //cout << "***Comment End***" << curr_lineno << endl;
                  //BEGIN(CALLER_CONDITION);
                  yy_pop_state();
                  cool_yylval.error_msg = "Unmatched *)";
                  return (ERROR);
                }
<COMMENT>"(*"   {
                  yy_push_state(COMMENT);
                }                
<COMMENT>"*)"   {
                  yy_pop_state();
                  //BEGIN(CALLER_CONDITION);
                }
<COMMENT><<EOF>> {
                  yy_pop_state();
                  //BEGIN(CALLER_CONDITION);
                  cool_yylval.error_msg = "EOF in comment";
                  return (ERROR);
                }
<COMMENT>\n     {curr_lineno++;}
<COMMENT>.      {}


 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

 /*the case insensitive function is not supported in flex version 2.5.4
  *so I do it in this way
  */
{CLASS}                   {return (CLASS);}
{ELSE}                    {return (ELSE);}
{FI}                      {return (FI);}
{IF}                      {return (IF);}
{IN}                      {return (IN);}
{INHERITS}                {return (INHERITS);}
{LET}                     {return (LET);}
{LOOP}                    {return (LOOP);}
{POOL}                    {return (POOL);}
{THEN}                    {return (THEN);}
{WHILE}                   {return (WHILE);}
{CASE}                    {return (CASE);}
{ESAC}                    {return (ESAC);}
{OF}                      {return (OF);}
{NEW}                     {return (NEW);}
{ISVOID}                  {return (ISVOID);}
{NOT}                     {return (NOT);}

{DARROW}                  {return (DARROW);}
{ASSIGN}                  {return (ASSIGN);}
LE                        {return (LE);}

{TRUE}                    {
                            cool_yylval.boolean = 1;
                            return (BOOL_CONST);
                          }
{FALSE}                   {
                            cool_yylval.boolean = 0;
                            return (BOOL_CONST);
                          }


 /* Type identifiers */
{TYPEID}                  {
                            cool_yylval.symbol = idtable.add_string(yytext,yyleng);
                            return (TYPEID);
                          }


 /* Object identifiers */
{OBJECTID}                {
                            cool_yylval.symbol = idtable.add_string(yytext,yyleng);
                            return (OBJECTID);
                          }


 /* Integer constants */
{INT_CONST}               {
                            cool_yylval.symbol = inttable.add_string(yytext,yyleng);
                            return (INT_CONST);
                          }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

\"                        {
                            CALLER_CONDITION = INITIAL;
                            string_buf_ptr = string_buf;
                            BEGIN(STRING);
                          }
<STRING>\\                {
                            STRING_CALLER = STRING;
                            //cout << "ESCAPE MODE" << endl;
                            BEGIN(STRING_ESC);
                          }
<STRING_ESC><<EOF>>       {
                            BEGIN(STRING_CALLER);
                            cool_yylval.error_msg = "EOF in string constant";
                            return (ERROR);
                          }
<STRING_ESC>[ntbf]        {
                            BEGIN(STRING_CALLER);
                            char c;
                            switch(yytext[0]){
                              case 'n':
                                c = '\n';
                                break;
                              case 't':
                                c = '\t';
                                break;
                              case 'b':
                                c = '\b';
                                break;
                              case 'f':
                                c = '\f';
                                break;
                            }
                            *string_buf_ptr++ = c;
                          }
<STRING_ESC>\n            {
                            BEGIN(STRING_CALLER);
                            curr_lineno++;
                            *string_buf_ptr++ = yytext[0];
                          }
<STRING_ESC>.             {
                            BEGIN(STRING_CALLER);
                            *string_buf_ptr++ = yytext[0];
                          }
<STRING><<EOF>>           {
                            BEGIN(CALLER_CONDITION);
                            cool_yylval.error_msg = "EOF in string constant";
                            return (ERROR);
                          }
<STRING>\n                {
                            BEGIN(CALLER_CONDITION);
                            curr_lineno++;
                            cool_yylval.error_msg = "Unterminated string constant";
                            //cool_yylval.error_msg = "A not escaped new line!";
                            return (ERROR);
                          }
<STRING>\0                {
                            cool_yylval.error_msg = "String contains null character";
                            return (ERROR);
                          }                         
<STRING>\"                {
                            BEGIN(CALLER_CONDITION);
                            int str_len = string_buf_ptr - string_buf;
                            if(str_len > MAX_STR_CONST){
                              cool_yylval.error_msg = "String constant too long";
                              return (ERROR);
                            }
                          
                            *string_buf_ptr = '\0';
                            cool_yylval.symbol = stringtable.add_string(string_buf);
                            BEGIN(CALLER_CONDITION);
                            return (STR_CONST);
                          }
<STRING>.                 {
                            *string_buf_ptr++ = yytext[0];
                          }


 /* Single Character */
[+/\-*=<.~,;:()@{}]       {
                            return yytext[0];
                          }

.                         {
                            cool_yylval.error_msg = yytext;
                            return (ERROR);
                          }
%%
