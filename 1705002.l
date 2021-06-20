%option noyywrap
%option yylineno

%x MLC
%x MLS 
%x MLS_BS

%{
    #include <cstdlib>
    #include <cstdio>
    #include "lex_util.h"
    #include "symbol_table.h" 
    
    #include "1705002.tab.h"
    
    
    #define YY_USER_ACTION yylloc.first_line = yylloc.last_line = yylineno;
    
    using namespace std; 
    

    
    int chars = 0;
    int words = 0;
    int lines = 1; 

    
    lex_util util; 
    
    extern YYSTYPE yylval;
    extern symbol_table table;
    void yyerror_lexical(char *);
    void yyerror_multiple(char *);
    
    extern int error_line_no;  //this global variable to pass info to yyerror_lexical 
    extern int prev_error_line_no; 
    
    string _temp; 
%}

nl "\r"|"\n"|"\r\n"

keyword if|else|for|while|do|break|int|char|float|double|void|yylval.text = string(yytext);	return|switch|case|default|continue

dgt [0-9] 
dgts {dgt}* 
dgtp {dgt}+
ltr [A-Za-z] 
ltr_ "_"|{ltr}
dgt_ltr {dgt}|{ltr_} 
identifier {ltr_}{dgt_ltr}*

rdx "\."
rdx_flt {dgtp}{rdx}{dgts}|{dgts}{rdx}{dgtp}
flt ({rdx_flt}|{dgtp})[Ee][+-]?{dgtp}

e_12cd {dgtp}{ltr_}{dgt_ltr}*
e_1r2r3 {dgts}{rdx}+{dgts}({rdx}+{dgts})+
e_1E2r2 ({rdx_flt}|{dgtp})E[+-]?{rdx_flt}


bs "\\"
sqt "\'"
dqt "\""
nbs  [^\\]
nsqt [^\']
ndqt [^\"]
escape {bs}({bs}|{sqt}|[ntafrbv0]) 

def_char {sqt}[^\\\r\n]{sqt} 
esc_char {sqt}{escape}{sqt}
e_mul_char {sqt}[^\'\r\n]+[^\'\r\n]{sqt}
e_emp_char {sqt}{2}
e_unf_char ({sqt}{bs}{sqt})|({sqt}[^\'\n\r]*{nl})

acc_sl ([^\\\"\n\r]*(\\[^\\\n\r])*)*
sl_str {dqt}({acc_sl})*{dqt} 
ml_str {dqt}({acc_sl}{bs}{nl})+({acc_sl}){dqt} 
e_unf_str ({dqt}{bs}{dqt})|({dqt}({acc_sl})*({bs}{nl}({acc_sl})*)*{nl})

slc "//"([^\\\r\n]((\\)+(.|[\r\n]))*)*[.\r\n]
mlc "/*"(.|[\r\n])*("*")+"/"

fs "/"
star "*" 

ws [ \t\r\n]

println "printf"|"println"


%%

"/*" {
    BEGIN MLC; 
    util.begin_mlc(); 
    util.reset_line_count(yylineno);
}

<MLC>"*/" {
    BEGIN INITIAL;
    util.end_mlc(yylineno); 
    util.reset_line_count(yylineno);
}

<MLC>.|{nl} {
    util.add_mlc(yytext);
}

<MLC><<EOF>> {
    util.unfcmnt(yylineno);
    util.reset_line_count(yylineno);
    yylval.text = string(yytext);	return 0; 
}

{dqt} {
    // printf("MLS began\n"); 
    BEGIN MLS;
    util.begin_str();
    
}

<MLS>{dqt} {
    // printf("MLS ended\n"); 
    BEGIN INITIAL;
    util.end_str(); 
    util.reset_line_count(yylineno);
}

<MLS>[^\"\\\n\r]+ {
    // printf("A token: %s at %d\n", yytext, yylineno);
    util.add_str(yytext);  
}

<MLS>{bs}({nl}|{dqt}) {
    //util.add_str("\\");
    // printf("A bs+nl/dqt token: %s at %d\n", yytext, yylineno);
    util.add_str(yytext); 
}

<MLS>{bs}. {
    // printf("A bs+. token: %s at %d\n", yytext, yylineno);
    util.add_str(yytext);  
}

<MLS>{nl} {
    // printf("An MLS nl at %d\n", yylineno);
    BEGIN INITIAL; 
    util.unfstring(); 
    util.reset_line_count(yylineno);
}

<MLS>. {
    // printf("Unrecognized in MLS: %s at %d" , yytext, yylineno);
}

<MLS><<EOF>> {
    BEGIN INITIAL; 
    util.unfstring(); 
    util.reset_line_count(yylineno);
    return 0;
}

"if"        { util.keyword(yytext); _temp = yytext;  yylval.val.sptr = &_temp;	    yylval.text = string(yytext);	return IF; }
"else"      { util.keyword(yytext); _temp = yytext;  yylval.val.sptr = &_temp;		yylval.text = string(yytext);	return ELSE; }
"for"       { util.keyword(yytext); _temp = yytext;  yylval.val.sptr = &_temp;		yylval.text = string(yytext);	return FOR; }
"while"     { util.keyword(yytext); _temp = yytext;  yylval.val.sptr = &_temp;		yylval.text = string(yytext);	return WHILE; }
"int"       { util.keyword(yytext); _temp = yytext;  yylval.val.sptr = &_temp;		yylval.text = string(yytext);	return INT; }
"float"     { util.keyword(yytext); _temp = yytext;  yylval.val.sptr = &_temp;		yylval.text = string(yytext);	return FLOAT; }
"double"    { util.keyword(yytext); _temp = yytext;  yylval.val.sptr = &_temp;		yylval.text = string(yytext);	return DOUBLE; }
"char"      { util.keyword(yytext); _temp = yytext;  yylval.val.sptr = &_temp;		yylval.text = string(yytext);	return CHAR; }
"return"    { util.keyword(yytext); _temp = yytext;  yylval.val.sptr = &_temp;		yylval.text = string(yytext);	return RETURN; }
"void"      { util.keyword(yytext); _temp = yytext;  yylval.val.sptr = &_temp;		yylval.text = string(yytext);	return VOID; }
"main"	    { util.keyword(yytext); _temp = yytext;  yylval.val.sptr = &_temp;		yylval.text = string(yytext);	return MAIN; }
{println} 	{ util.keyword(yytext); _temp = yytext;  yylval.val.sptr = &_temp;		yylval.text = string(yytext);	return PRINTLN; }

[+-] {
    util.addop(yytext); 
    util.reset_line_count(yylineno); 
    
    yylval.val.cval = yytext[0]; 
    yylval.text = string(yytext);	return ADDOP; 
}
[*/%] {
    util.mulop(yytext);
    util.reset_line_count(yylineno);
    
    yylval.val.cval = yytext[0]; 
    yylval.text = string(yytext);	return MULOP; 
}
"++" {
    util.incop(yytext); 
    util.reset_line_count(yylineno);
    
    yylval.text = string(yytext);	return INCOP; 
}
"--" {
    util.incop(yytext); 
    util.reset_line_count(yylineno);
    
    yylval.text = string(yytext);	return DECOP; 
}
[><]|[=!><]= {
    util.relop(yytext);
    util.reset_line_count(yylineno);
    
    _temp = yytext; 
    yylval.val.sptr = &_temp; 
    yylval.text = string(yytext);	return RELOP; 
}
"=" {
    util.assignop();
    util.reset_line_count(yylineno); 
    
    yylval.text = string(yytext);	return ASSIGNOP; 
}
"||"|"&&" {
    util.logicop(yytext);
    util.reset_line_count(yylineno);
    
    yylval.val.cval = yytext[0]; 
    yylval.text = string(yytext);	return LOGICOP; 
}
"!" {
    util.notop();
    util.reset_line_count(yylineno);
    
    yylval.text = string(yytext);	return NOT; 
}
"{" {
    util.lcurl();
    // printf("Left brace at %d\n", yylineno); 
    util.reset_line_count(yylineno);
    
    yylval.text = string(yytext);	return LCURL; 
}
"}" {
    util.rcurl(); 
    // printf("Right brace at %d\n", yylineno); 
    util.reset_line_count(yylineno); 
    
    yylval.text = string(yytext);	return RCURL; 
}
"(" {
    util.lparen();
    util.reset_line_count(yylineno);
    
    yylval.text = string(yytext);	return LPAREN; 
}
")" {
    util.rparen(); 
    util.reset_line_count(yylineno);
    
    yylval.text = string(yytext);	return RPAREN; 
}
"[" {
    util.lthird(); 
    util.reset_line_count(yylineno); 
    
    yylval.text = string(yytext);	return LTHIRD; 
}
"]" {
    util.rthird();
    util.reset_line_count(yylineno); 
    
    yylval.text = string(yytext);	return RTHIRD; 
}
"," {
    util.comma(); 
    util.reset_line_count(yylineno); 
    
    yylval.text = string(yytext);	return COMMA; 
}
";" {
    util.semicolon(); 
    util.reset_line_count(yylineno);
    
    yylval.text = string(yytext);	return SEMICOLON;
}
{dgtp} {
    util.integer(yytext); 
    util.reset_line_count(yylineno); 
    
    try{
        yylval.val.ival = stoi(string(yytext));
    }  catch (const std::logic_error& z) {
        yylval.val.ival = 0;
        yyerror_multiple("Integer number out of range."); 
    }
    yylval.text = string(yytext);	return CONST_INT; 
}
{flt}|{rdx_flt} {
    util.floating(yytext);
    util.reset_line_count(yylineno); 
    
    try{
        yylval.val.fval = stof(string(yytext));
    }  catch (const std::logic_error& z) {
        yylval.val.fval = 0;
        yyerror_multiple("Floating point number out of range."); 
    }
    yylval.text = string(yytext);	return CONST_FLOAT;
}
{def_char} {
    util.def_char(yytext); 
    util.reset_line_count(yylineno);
}
{esc_char} {
    util.esc_char(yytext); 
    util.reset_line_count(yylineno);
}

{identifier} { 
    words++; 
    chars += strlen(yytext); 
    util.identifier(yytext); 
    util.reset_line_count(yylineno);
    yylval.text = string(yytext); 
    return ID; 
}
{slc} {
    // printf("Forward slash comment\n%s\n", yytext);
    util.comment(yytext);
    util.reset_line_count(yylineno);
}
{e_1r2r3} {
    _temp = util.multiple_radices(yytext); 
    util.reset_line_count(yylineno);
    error_line_no = yylineno; 
    yyerror_lexical((char *)_temp.c_str()); 
}

{e_1E2r2} {
    _temp = util.ill_formed_number(yytext);
    util.reset_line_count(yylineno);
    error_line_no = yylineno; 
    yyerror_lexical((char *)_temp.c_str()); 
}
{e_12cd} {
    _temp = util.invalid_id_prefix(yytext);
    /*printf("%s\n", yytext); 
    cout << util.invalid_id_prefix(yytext); 
    cout << "Ill " << _temp << endl;*/
    util.reset_line_count(yylineno);
    error_line_no = yylineno; 
    yyerror_lexical((char *)_temp.c_str()); 
}
{e_mul_char} {
    _temp = util.multichar(yytext);
    util.reset_line_count(yylineno);
    error_line_no = yylineno; 
    yyerror_lexical((char *)_temp.c_str()); 
}
{e_emp_char} {
    _temp = util.empchar(yytext);
    util.reset_line_count(yylineno);
    error_line_no = yylineno; 
    yyerror_lexical((char *)_temp.c_str()); 
}
{e_unf_char} {
    _temp = util.unfchar(yytext);
    util.reset_line_count(yylineno);
    error_line_no = yylineno; 
    yyerror_lexical((char *)_temp.c_str()); 
}

{nl} { 
    chars++; lines++; 
    util.reset_line_count(yylineno);
    //return NL; 
}
[ \t]+ {
    //return NL;
}
. { chars++; _temp = util.unrecognized(yytext); 
    error_line_no = yylineno; 
    yyerror_lexical((char *)_temp.c_str()); }
%%
/*
int main(int argc, char **argv)
{
    yylineno = 1;
    
    if(argc > 1) {
        if(!(yyin = fopen(argv[1], "r"))) {
            perror(argv[1]);
            yylval.text = string(yytext);	return (1);
        }
    }


    yylex();
    printf("\n"); 
    // printf("%8d%8d%8d\n", yylineno, words, chars); 
    yylval.text = string(yytext);	return 0; 
}
*/
