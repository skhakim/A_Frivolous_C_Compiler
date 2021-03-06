%require "3.2"
%locations
%{
#include <bits/stdc++.h>
#include "symbol_table.h"

#include "lex.yy.c"
//#define YYSTYPE symbol_info*

using namespace std;

// ofstream error, log; 

int yyparse(void);
int yylex(void);
extern FILE *yyin;
FILE *fp;

extern string _temp; 
symbol_table table(30);
string est(""), _var("var");

FILE *lf, *ef, *cf; 
char c; 

stringstream var_decs; 
unordered_map<string, stringstream> func_codes; 

int no_errors;
int error_line_no;  //this global variable to pass info to yyerror 
int prev_error_line_no; 

void yyerror(char *s)
{
    //yyerror_multiple(s); return; 

    if(prev_error_line_no == error_line_no) {
        // informal instruction :: no two errors in the same line 
        return; 
    }
	//write your code
	++no_errors; 
	prev_error_line_no = error_line_no; 
	fprintf(ef, "Error at line %d: %s\n\n", error_line_no, s); 
	fprintf(lf, "Error at line %d: %s\n\n", error_line_no, s); 
}

void yyerror_multiple(char *s)  // two errors in the same line
{
	//write your code
	++no_errors; 
	prev_error_line_no = error_line_no; 
	fprintf(ef, "Error at line %d: %s\n\n", error_line_no, s); 
	fprintf(lf, "Error at line %d: %s\n\n", error_line_no, s);
}

void yyerror_lexical(char *s)  // two errors in the same line
{
    //printf("Hello from yyerror_lexical!!!\n%s\n", s); 
	//write your code
	++no_errors; 
	prev_error_line_no = error_line_no; 
	fprintf(ef, "%s\n\n", s); 
	fprintf(lf, "%s\n\n", s); 
}

int i_par_list; 
bool name_mentioned = true; 


%}
%define parse.trace 

%code requires {

    typedef pair<string, int> _info; 

    typedef union mu {
        bool bval; 
        int ival; 
        uintmax_t mval; 
        float fval; 
        double dval; 
        char cval;
        string* sptr; 
        symbol_info* infoptr; 
        queue<_info*>* decs; 
        queue<int>* args;

    } my_union;

    // string my_dtype_str[5] = {string("int"), string("float"), string("bool"), string("string"), string("void")};
    
    typedef struct ms {
        my_union val; 
        my_dtype type = _UNKNOWN; 
        string text; 
        
        string code;
        string temp;
        string idx; 
    } YYSTYPE; 

    #define MAX(a, b) (((a) > (b)) ? (a) : (b))
    
    int iLabel = 0; 
    int iTemp = -2, iTmax = 0; 
    
    string new_label() {
        iLabel++;
        return "LABEL" + to_string(iLabel); 
    }
    
    string new_temp() {
        iTemp+=2;
        iTmax = MAX(iTemp, iTmax);
        return "TEMP+" + to_string(iTemp); 
    }
    
    /*string pushn(int n) {
        string ret = "";
        for(int i=0; i<n; ++i){
            ret += "\tPUSH " + to_string(i<<1) + '\n'; 
        }   
        return ret; 
    }
    
    string popn(int n) {
        string ret = "";
        for(int i=n-1; i>-1; i--){
            ret += "\tPOP: " + to_string(i<<1) + '\n'; 
        }
        return ret; 
    }*/
    
    
}

%code {
    queue<_info*> *res_q = new queue<_info*>;
    string res_func; 
    bool func_call = false; 
    string insert_res_q() {
        // printf("\tsizeof res_q: %d\n", res_q->size());
        /*if(res_func.size()){
            table.func_insert(_TBdef, res_func, _temp); 
        }*/
        
        string res_func = ""; 
        
        while(res_q->size()) {
            _info *x = res_q->front();
            res_q->pop(); 
            if(x->second == _INT) {
                    if(table.var_insert<int>(x->first, _temp)){
                        //yyerror_multiple((char*)((est + "Multiple definition of " + x->first).c_str()));
                        symbol_info* temp = table.lookup(x->first, _temp);
                        res_func += "\tPOP " + temp->get_code() + "\n"; 
                        
                    }
            }
            else if(x->second == _FLOAT) {
                if(!table.var_insert<float>(x->first, _temp)){
                    //yyerror_multiple((char*)((est + "Multiple definition of " + x->first).c_str()));
                }
            }
            else{
                yyerror("Variable declared void!!"); 
            }
        }
        
        return res_func; 
    }
    
    extern int yylineno; 
    
    string push_temp_vars(int m) {
        string ret = "";
        for(int i=0; i<=m; i+=2)
            ret += "\tPUSH TEMP+" + to_string(i) + "\n"; 
        return ret; 
    }    
    
    string pop_temp_vars(int m) {
        string ret = "";
        for(int i=0; i<=m; i+=2)
            ret += "\tPOP TEMP+" + to_string(m-i) + "\n"; 
        return ret; 
    }    
}

%code {         //stores the file things 
    string _asm = ".MODEL SMALL\n"
    "\n"
    "\n"
    ".STACK 100H\n"
    "\n"
    "\n"
    ".DATA\n"
    "CR EQU 0DH\n"
    "LF EQU 0AH\n"
    "CF EQU 0\n"
    "PF EQU 2\n"
    "ZF EQU 6\n"
    "SF EQU 7\n"
    "OF EQU 11\n"
    "\nTEMP DW %d DUP (0)\nFUNC DW 20 DUP(0)\n" // no of temp variables & func parameters 
    "%s" // the declarations 
    ".CODE\n"
    "\n"
    /*"MAIN PROC\n"
    "\t;DATA SEGMENT INITIALIZATION\n"
    "    MOV AX, @DATA\n"
    "    MOV DS, AX\n\n"*/
    "%s" // the codes of main function 
    /*"\t;DOS EXIT\n"
    "    MOV AH, 4CH\n"
    "    INT 21H\n"
    "\n" 
    "MAIN ENDP\n"*/
    "%s" // other functions
    "\n"
    "OUTDEC PROC \n"
    "; PRINTS AX AS A SIGNED DECIMAL INTEGER \n"
    "; INPUT : AX \n"
    "; OUTPUT : NONE \n"
    "\n"
    "    ; ALWAYS START PROC BY STORING REGISTERS\n"
    "    PUSH AX\n"
    "    PUSH BX\n"
    "    PUSH CX\n"
    "    PUSH DX \n"
    "    \n"
    "    ; TEST AX FOR ZERO \n"
    "    TEST AX, AX\n"
    "    JGE @END_IF1 \n"
    "    \n"
    "    ; AX IS NEGATIVE  \n"
    "    \n"
    "        ; SAVE THE NUMBER \n"
    "        PUSH AX\n"
    "        \n"
    "        ; PRINT '-' \n"
    "        MOV DL, '-'\n"
    "        MOV AH, 2\n"
    "        INT 21H \n"
    "        \n"
    "        ; RESTORE AX\n"
    "        POP AX\n"
    "        ; AX = -AX \n"
    "        ; THIS OPERATION KEEPS |VAL| IN AX \n"
    "        NEG AX \n"
    "        \n"
    "    ; AX IS NONNEGATIVE \n"
    "    @END_IF1:\n"
    "    \n"
    "        ; CLEAR CX  \n"
    "        AND CX, 0 \n"
    "        ; BX IS OUR DIVISOR WHICH HOLDS 10D \n"
    "        MOV BX, 10D \n"
    "        \n"
    "    ; A REPEAT LOOP\n"
    "    @REPEAT_1:\n"
    "        \n"
    "        AND DX, 0 \n"
    "        ; NOW (DX AX) EQUALS OUR DIVIDEND \n"
    "        DIV BX \n"
    "        ; PUSH THE REMAINDER\n"
    "        PUSH DX\n"
    "        ; ONE DIGIT MORE \n"
    "        INC CX\n"
    "        ; CHECKING WHETHER THE RESULT IS ZERO \n"
    "        OR AX, AX\n"
    "        ; IF NOT ZERO, REPEAT THE LOOP \n"
    "        JNZ @REPEAT_1\n"
    "                       \n"
    "    ; FOR PRINTING CHARS, SET AH = 2\n"
    "    MOV AH, 2\n"
    "    \n"
    "    ; FOR COUNT=CX TIMES \n"
    "    @PRINT_LOOP:\n"
    "    \n"
    "    \n"
    "        ; DL SHOULD CONTAIN THE RESULT \n"
    "        POP DX\n"
    "        ; ADD 48 TO GET THE DIGIT ASCII \n"
    "        ADD DX, 48     \n"
    "        INT 21H \n"
    "        LOOP @PRINT_LOOP \n"
    "        \n\n"
    "    ; THE LOOP IS OVER\n"
    "    MOV DL, CR\n"
    "    INT 21H \n"
    "    MOV DL, LF \n"
    "    INT 21H\n\n"
    "    ; REGISTERS SHOULD BE POPPED IN THE REVERSE ORDER OF THEIR INSERTION\n"
    "    POP DX\n"
    "    POP CX\n"
    "    POP BX\n"
    "    POP AX       \n"
    "    \n"
    "    ; RETURN TO THE CALLER \n"
    "    RET                    \n"
    "    \n"
    "OUTDEC ENDP   "
    "\nEND MAIN"; 
}

%token IF ELSE FOR WHILE INT FLOAT DOUBLE CHAR RETURN VOID MAIN PRINTLN ID NL

%token LPAREN LCURL LTHIRD RPAREN RCURL RTHIRD COMMA SEMICOLON 

%token CONST_INT
%token CONST_FLOAT

%nonassoc fdec_embd
%nonassoc fdef_embd

%right ELSE DUMMY_THEN

%right ASSIGNOP 
%left RELOP 
%left LOGICOP
%left ADDOP
%left MULOP
%left NOT 
%left INCOP DECOP 




%%


start : program
	{
        $<text>$ = $<text>1 ; 
        fprintf(lf, "\n\nLine %d: start : program\n\n", @1.last_line);
        table.print_active_tables(lf);
        
        fprintf(lf, "Total lines: %d\nTotal errors: %d\n\n", @1.last_line, no_errors); 
        
		//write your code in this block in all the similar blocks below
		printf("\nParsing finished.\n");
		//cout << table.declaration();  
		
		//fseek(cf, 0x45, )
		if(!no_errors)
            fprintf(cf, _asm.c_str(), 1+iTmax/2, table.declaration().c_str(), $<code>[program].c_str(), ""); 
		
		
		
		break; 
		//printf("\nShould not get printed!\n");
	}
	;

program : program unit {
            $<text>$ = $<text>1 + '\n' + $<text>2; 
            fprintf(lf, "Line %d: program : program unit\n\n%s\n\n", @2.last_line, $<text>$.c_str());
            
            //cout << "Done with unit : " << $<text>2 << endl; 
            
            $<code>$ = $<code>1 + $<code>2; 
        }

	| unit{
            $<text>$ = $<text>1 ; 
            fprintf(lf, "Line %d: program : unit\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            
            $<code>$ = $<code>1; 
        }
	;
	
unit : var_declaration {
            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: unit : var_declaration\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            
            $<code>$ = $<code>1; 
        }

     | func_declaration{
            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: unit : func_declaration\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            
            $<code>$ = ""; 
        }

     | func_definition{
            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: unit : func_definition\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            //cout << "Did you get this? " << __LINE__ << " " << $<text>$ << endl; 
            
            $<code>$ = $<code>1; 
        }  
        | error  {
            $<text>$ = "";
            printf("Error unit getting discarded\n");
            error_line_no = @1.last_line; 
            yyerror("Syntax Error");
            //yyclearin;
        }
        
     ;
     



func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON{
            func_info* temp_func = table.func_insert($<type>1, $<text>2, _temp);
            if(!temp_func){ // nullptr returned 
                error_line_no = @1.last_line; 
                yyerror_multiple((char*)((est + "Multiple declaration of " + $<text>2).c_str()));
                yyerrok; 
            }
            else { // function actually inserted 
                // *res_q = queue<_info*>(*$<val.decs>4);
                
                while($<val.decs>4->size()) {
                    _info* x = $<val.decs>4->front(); 
                    //cout << endl << x->first << " " << x->second << endl; 
                    if(x->second != _VOID && !temp_func->add_variable(x->second, x->first) && x->first.size()){
                        error_line_no = @[RPAREN].last_line; 
                        yyerror_multiple((char*)((est + "Multiple declaration of " + x->first + " in parameter").c_str()));
                        yyerrok; 
                    }
                    $<val.decs>4->pop(); 
                }
                // printf("Size from %s func_declaration %d\n", ($<text>2).c_str(), res_q->size());
            }
            //temp_func->print_basics();
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3 + ' ' + $<text>4 + ' ' + $<text>5 + ' ' + $<text>6; 
            fprintf(lf, "Line %d: func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n%s\n\n", @1.last_line, $<text>$.c_str()); 
            
            // remove this later 
            table.enter_scope(); table.exit_scope(); 
        }

		| type_specifier ID LPAREN RPAREN SEMICOLON{
            if(!table.func_insert($<type>1, $<text>2, _temp)){
                error_line_no = @1.last_line; 
                yyerror_multiple((char*)((est + "Multiple declaration of " + $<text>2).c_str()));
                yyerrok; 
            }
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3 + ' ' + $<text>4 + ' ' + $<text>5; 
            fprintf(lf, "Line %d: func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            
            // remove this later 
            table.enter_scope(); table.exit_scope(); 
        }
        
        | type_specifier MAIN LPAREN RPAREN SEMICOLON{ 
            if(!table.func_insert($<type>1, $<text>2, _temp)){
                error_line_no = @1.last_line; 
                yyerror_multiple((char*)((est + "Multiple declaration of " + $<text>2).c_str()));
                yyerrok; 
            }
            // another rule added for main 
            // int argc, char** argv --> not kept, since no pointer in our language
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3 + ' ' + $<text>4 + ' ' + $<text>5; 
            fprintf(lf, "Line %d: func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            
            // remove this later 
            table.enter_scope(); table.exit_scope(); 
        }

		;
		 

		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN 
{ 
            $<code>[ID] = "\n\n" + $<text>[ID] + " PROC \n";
            $<code>[ID] += "; TAKES 16-BIT INTEGER INPUT(S) IN THE STACK\n";
            $<code>[ID] += ($<type>1 == _INT) ? "; OUTPUTS AN 16-BIT INTEGER IN DX\n" : "; PRODUCES NO OUTPUT\n";
            $<code>[ID] += "\tPOP CX\n\n";
            

            *res_q = queue<_info*>(*$<val.decs>[parameter_list]);/* }  compound_statement { */ 
            func_info* cur_func; 
            symbol_info* prev = table.lookup($<text>2, _temp); 
            if(prev){       // something of this name exists 
                func_info* prev_func = dynamic_cast<func_info*>(prev); 
                if(prev_func && prev_func->ret_type != _TBdef) {  // a function exists having same name. now match list 
                    // table.remove($<text>2, _temp);
                    cur_func = prev_func; 
                    if(prev_func->ret_type != $<type>1) {
                        error_line_no = @1.last_line; 
                        yyerror((char*)((est + "Return type mismatch with function declaration in function " + $<text>2).c_str()));
                        yyerrok; 
                        cur_func->ret_type = $<type>1; 
                    } 
                    else if(prev_func->size() != $<val.decs>4->size()) {
                        error_line_no = @1.last_line; 
                        yyerror_multiple((char*)((est + "Total number of arguments mismatch with declaration in function  " + $<text>2).c_str()));
                        yyerrok; 
                    } 
                    i_par_list = 0; 
                    //*res_q = queue<_info*>(*$<val.decs>4);
                    // cout << $<text>2;
                    //printf("\tSize from %s func_definition %d\n", ($<text>2).c_str(), $<val.decs>4->size());
                    //cur_func->print_basics(); 
                    //printf("\n----------------------------------------\n");
                    while($<val.decs>4->size()) {
                        ++i_par_list;
                        _info* x = $<val.decs>4->front(); 
                        $<val.decs>4->pop();
                        if(x->second != _VOID && !cur_func->match_and_add_variable(x->second, x->first)){
                            error_line_no = @1.last_line; 
                            yyerror_multiple((char*)((est + to_string(i_par_list) + "th argument mismatch in function " + $<text>2).c_str()));
                            yyerrok; 
                        }
                    }
                    cur_func->mark_defined(); 
                    cur_func->reset_count();
                    //cur_func->print_basics(); 
                    // printf("Size from %s func_definition %d\n", ($<text>2).c_str(), res_q->size());
                }
                else {  // a var perhaps of the same name. denote error. 
                    error_line_no = @1.last_line; 
                    yyerror_multiple((char*)((est + "Multiple declaration of " + $<text>2).c_str()));
                    yyerrok; 
                }
            } 
            else {  // nothing of this name exists 
                cur_func = table.func_insert($<type>1, $<text>2, _temp);
                //*res_q = queue<_info*>(*$<val.decs>4);
                //printf("\tSize from %s func_definition (ELSE) %d\n", ($<text>2).c_str(), res_q->size());

                while($<val.decs>4->size()) {
                    _info* x = $<val.decs>4->front(); 
                    if(x->second != _VOID && !cur_func->add_variable(x->second, x->first)){
                        error_line_no = @1.last_line; 
                        yyerror_multiple((char*)((est + "Multiple declaration of " + x->first + " in parameter").c_str()));
                        yyerrok; 
                    }
                    $<val.decs>4->pop(); 
                }
                cur_func->mark_defined(); 
                //printf("Size from %s func_definition (ELSE) %d %d\n", ($<text>2).c_str(), res_q->size(), cur_func->temp_types->size());
            }
            func_call = true; 
            table.enter_scope(); 
            $<code>[ID] += insert_res_q();
            //cout << $<code>[func_definition]; 
            yyerrok; 
        } compound_statement {
            //cout << "Did you get this? " << __LINE__ << endl; 
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3 + ' ' + $<text>4 + ' ' + $<text>5 + ' ' + $<text>[compound_statement]; 
            //fprintf(lf, "\n%s\n%s\n", $<text>6.c_str(), $<text>[compound_statement].c_str() );
            fprintf(lf, "Line %d: func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n%s\n\n", @[compound_statement].last_line, $<text>$.c_str());
            //cout << "Did you get this? " << __LINE__ << " " << $<text>$ << endl; 
            
            // cout << "LATER :" ;
            $<code>[func_definition] = $<code>[ID];
            $<code>[ID] = ""; 
            $<code>[func_definition] += $<code>[compound_statement]; 
            $<code>[func_definition] += "\tPUSH CX\n\tRET\nENDP " + $<text>[ID] + "\n\n\n"; 
        }

		| type_specifier ID LPAREN RPAREN { /* compound_statement{
             //cout << "Did you get this? " << __LINE__ << " " << $<text>2 << endl; 
            table.insert($<text>1, $<text>1, _temp);
            table.print_all_tables(lf); */ 
            symbol_info* prev = table.lookup($<text>2, _temp); 
            
            //cout << "Did you get this? " << __LINE__ << " " << $<text>$ << endl; 
            
             //printf("%p\n", prev); 
                
            //cout << "Did you get this? " << __LINE__ << " " << $<text>$ << endl; 
            if(prev){       // something of this name exists 
                func_info* prev_func = dynamic_cast<func_info*>(prev); 
                
                //cout << "Did you get this? " << __LINE__ << " " << $<text>$ << endl; 
                cout << prev_func << endl; 
                if(prev_func) {  // a function exists having same name. now match list 
                    table.remove($<text>2, _temp); // you might get another seg fault 
                    func_info* cur_func = table.func_insert($<type>1, $<text>2, _temp); 
                    if(prev_func->ret_type != cur_func->ret_type) {
                        error_line_no = @1.last_line; 
                        yyerror((char*)((est + "Return type mismatch with function declaration in function " + $<text>2).c_str()));
                        yyerrok; 
                    } 
                    else cur_func->mark_defined(); 
                }
                else {  // a var perhaps of the same name. denote error. 
                    error_line_no = @1.last_line; 
                    yyerror_multiple((char*)((est + "Multiple declaration of " + $<text>2).c_str()));
                    yyerrok; 
                }
            }  
            else {  // nothing of this name exists 
                func_info* cur_func = table.func_insert($<type>1, $<text>2, _temp); 
                if(!cur_func){
                    error_line_no = @1.last_line; 
                    yyerror_multiple((char*)((est + "Multiple declaration of " + $<text>2).c_str()));
                    yyerrok; 
                }
                else cur_func->mark_defined(); 
            }    
            func_call = true; 
            table.enter_scope(); 
                } compound_statement { 
            //cout << "Did you get this? " << __LINE__ << " " << $<text>$ << endl; 
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3 + ' ' + $<text>4 + ' ' + $<text>[compound_statement]; 
            fprintf(lf, "Line %d: func_definition : type_specifier ID LPAREN RPAREN compound_statement\n\n%s\n\n", @[compound_statement].last_line, $<text>$.c_str());
            
            $<code>$ = "\n\n" + $<text>[ID] + " PROC \n";
            $<code>$ += "; TAKES NO INPUT\n";
            $<code>$ += ($<type>1 == _INT) ? "; OUTPUTS AN 16-BIT INTEGER IN DX\n" : "; PRODUCES NO OUTPUT\n";
            $<code>$ += "\tPOP CX\n\n";
            
            
            $<code>$ += $<code>[compound_statement]; 
            $<code>$ += "\tPUSH CX\n\tRET\nENDP " + $<text>[ID] + "\n\n\n"; 
        }
        
        | type_specifier MAIN LPAREN RPAREN 
        {
            symbol_info* prev = table.lookup($<text>2, _temp); 
            if(prev){       // something of this name exists 
                func_info* prev_func = dynamic_cast<func_info*>(prev); 
                if(prev_func) {  // a function exists having same name. now match list 
                    table.remove($<text>2, _temp); // you might get another seg fault 
                    func_info* cur_func = table.func_insert($<type>1, $<text>2, _temp); 
                    if(prev_func->ret_type != cur_func->ret_type) {
                        error_line_no = @1.last_line; 
                        yyerror((char*)((est + "Return type mismatch with function declaration in function " + $<text>2).c_str()));
                        yyerrok; 
                    } 
                    else cur_func->mark_defined(); 
                }
                else {  // a var perhaps of the same name. denote error. 
                    error_line_no = @1.last_line; 
                    yyerror_multiple((char*)((est + "Multiple declaration of " + $<text>2).c_str()));
                    yyerrok; 
                }
            }   
            else {  // nothing of this name exists 
                func_info* cur_func = table.func_insert($<type>1, $<text>2, _temp); 
                if(!cur_func){
                    error_line_no = @1.last_line; 
                    yyerror_multiple((char*)((est + "Multiple declaration of " + $<text>2).c_str()));
                    yyerrok; 
                }
                else cur_func->mark_defined(); 
            }  
            func_call = true; 
            table.enter_scope(); 
                } compound_statement {
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3 + ' ' + $<text>4 + ' ' + $<text>[compound_statement]; 
            fprintf(lf, "Line %d: func_definition : type_specifier ID LPAREN RPAREN compound_statement\n\n%s\n\n", @[compound_statement].last_line, $<text>$.c_str());
            
            
            $<code>$ = est + "MAIN PROC\n"
                        +"\t;DATA SEGMENT INITIALIZATION\n"
                        +"    MOV AX, @DATA\n"
                        +"    MOV DS, AX\n\n"
                        + regex_replace($<code>[compound_statement]
                                            , regex("RET .*\n"), "JMP DOS_EXIT\n\n") // the codes of main function 
                        +"\t;DOS EXIT\n"
                        +"DOS_EXIT: \n"
                        +"    MOV AH, 4CH\n"
                        +"    INT 21H\n"
                        +"\n" 
                        +"MAIN ENDP\n";  
        }

 		;		



parameter_list : parameter_list COMMA type_specifier ID{
            
        
            if($<type>3 != _VOID)
                $<val.decs>$->push(new _info($<text>4, $<type>3)); 
            else{
                error_line_no = @1.last_line;
                yyerror((char *)(est + "Argument cannot be of type VOID").c_str());
                yyerrok;
            }
            
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3 + ' ' + $<text>4; 
            fprintf(lf, "Line %d: parameter_list : parameter_list COMMA type_specifier ID\n\n%s\n\n", @1.last_line, $<text>$.c_str());
        }

		| parameter_list COMMA type_specifier{
            if($<type>3 != _VOID)
                $<val.decs>$->push(new _info(est, $<type>3));
            else{
                error_line_no = @1.last_line;
                yyerror((char *)(est + "VOID must be the only parameter").c_str());
                yyerrok;
            }
            // $<val.decs>$ = $<val.decs>1;
            
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3; 
            fprintf(lf, "Line %d: parameter_list : parameter_list COMMA type_specifier\n\n%s\n\n", @1.last_line, $<text>$.c_str());
        }

 		| type_specifier ID{
            $<val.decs>$ = new queue<_info*>();  
            if($<type>1 != _VOID)
                $<val.decs>$->push(new _info($<text>2, $<type>1)); 
            else{
                error_line_no = @1.last_line;
                yyerror((char *)(est + "Argument cannot be of type VOID").c_str());
                yyerrok;
            }
            $<text>$ = $<text>1 + ' ' + $<text>2; 
            fprintf(lf, "Line %d: parameter_list : type_specifier ID\n\n%s\n\n", @1.last_line, $<text>$.c_str());
        }

		| type_specifier{
            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: parameter_list : type_specifier\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            $<val.decs>$ = new queue<_info*>();  
            
            if($<type>1 != _VOID)
                $<val.decs>$->push(new _info(est, $<type>1));
            
            
            //i_par_list = 0; //this should be the first parameter 
            //name_mentioned = false; //name NOT mentioned 
        } 
        
        | error { printf("Error to begin parameter_list."); 
                    error_line_no = @[error].last_line; 
                    yyerror("Syntax error in parameter_list.");  }
        | parameter_list error { printf("Error in parameter_list."); error_line_no = @[error].last_line;  yyerror("Syntax error in parameter_list.");  }

 		;

 		
compound_statement : LCURL { if(!func_call) {
                                table.enter_scope();  
                            } 
                                func_call = false; } statements RCURL{
            $<text>$ = $<text>1 + '\n' + $<text>[statements] + '\n' + $<text>[RCURL]; 
            fprintf(lf, "ine %d: compound_statement : LCURL statements RCURL\n\n%s\n\n", @[RCURL].last_line, $<text>$.c_str());
            table.print_active_tables(lf); 
            
            
            //cout << table.push_current_scope();
            //cout << table.pop_current_scope();
            
            
            table.exit_scope(); 
            
            $<code>$ = $<code>[statements]; 
            
            
        }

 		    | LCURL { if(!func_call) {
                                table.enter_scope(); 
                            }
                                func_call = false;  } RCURL{
            $<text>$ = $<text>1 + ' ' + $<text>[RCURL]; 
            fprintf(lf, "Line %d: compound_statement : LCURL RCURL\n\n%s\n\n", @[RCURL].last_line, $<text>$.c_str()); 
            table.print_current_table(lf); 
            table.exit_scope(); 
            
        }
 		    ;
 		    

var_declaration : type_specifier declaration_list SEMICOLON{
            
            // printf("Printing queue.............\n");
            while($<val.decs>2->size()) {
                _info* x = $<val.decs>2->front(); 
                $<val.decs>2->pop();
                //printf("%s %d\n", x->first.c_str(), x->second);
                // printf("Error after thos");
                if(x->second + 1) { // array 
                    //cout << "var_dec got an array ... " << x->first << " " << x->second << endl; 
                    if($<type>1 == _INT) {
                        if(!table.arr_insert<int>(x->first, x->second, _temp)){
                            error_line_no = @1.last_line; 
                            yyerror_multiple((char*)((est + "Multiple declaration of " + x->first).c_str()));
                            yyerrok; 
                        }
                    }
                    else if($<type>1 == _FLOAT) {
                        if(!table.arr_insert<float>(x->first, x->second, _temp)){
                            error_line_no = @1.last_line; 
                            yyerror_multiple((char*)((est + "Multiple declaration of " + x->first).c_str()));
                            yyerrok; 
                        }
                    }
                    else{
                        error_line_no = @1.last_line;
                        yyerror("Arrray declared void!!"); 
                        yyerrok; 
                    }
                }
                else { // variable 
                    if($<type>1 == _INT) {
                        if(!table.var_insert<int>(x->first, _temp)){
                            error_line_no = @1.last_line; 
                            yyerror_multiple((char*)((est + "Multiple declaration of " + x->first).c_str()));
                            yyerrok; 
                        }
                    }
                    else if($<type>1 == _FLOAT) {
                        if(!table.var_insert<float>(x->first, _temp)){
                            error_line_no = @1.last_line; 
                            yyerror_multiple((char*)((est + "Multiple declaration of " + x->first).c_str()));
                            yyerrok; 
                        }
                    }
                    else{
                        error_line_no = @1.last_line; 
                        yyerror("Variable declared void!!"); 
                        yyerrok; 
                    }
                }
            }
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3; 
            fprintf(lf, "Line %d: var_declaration : type_specifier declaration_list SEMICOLON\n\n%s\n\n", @3.last_line, $<text>$.c_str());
        }

 		 ;
 		

type_specifier	: INT {
            $<text>$ = $<text>1; 
            $<type>$ = _INT; 
            fprintf(lf, "Line %d: type_specifier : INT\n\n%s\n\n", @1.last_line, $<text>$.c_str());
        }

 		| FLOAT{
            $<text>$ = $<text>1; 
            $<type>$ = _FLOAT;  
            fprintf(lf, "Line %d: type_specifier : FLOAT\n\n%s\n\n", @1.last_line, $<text>$.c_str());
        }

 		| VOID{
            $<text>$ = $<text>1; 
            $<type>$ = _VOID; 
            fprintf(lf, "Line %d: type_specifier	: VOID\n\n%s\n\n", @1.last_line, $<text>$.c_str());
        }
 		;
 		


declaration_list : declaration_list COMMA ID{
            $<val.decs>$->push(new _info($<text>3, -1)); // -1 means it's a variable, not an array  
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3; 
            fprintf(lf, "Line %d: declaration_list : declaration_list COMMA ID\n\n%s\n\n", @1.last_line, $<text>$.c_str());
        }

 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD{
 		    $<val.decs>$->push(new _info($<text>[ID], $<val.ival>5));
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3 + ' ' + $<text>4 + ' ' + $<text>5 + ' ' + $<text>6; 
            fprintf(lf, "Line %d: declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n%s\n\n", @6.last_line, $<text>$.c_str());
        }

 		  | ID {
            $<val.decs>$ = new queue<_info*>();  
            $<val.decs>$->push(new _info($<text>1, -1)); // -1 means it's a variable, not an array 
            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: declaration_list : ID\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            
            // now a variable should be inserted 
        }

 		  | ID LTHIRD CONST_INT RTHIRD{
 		    $<val.decs>$ = new queue<_info*>();  
            $<val.decs>$->push(new _info($<text>1, $<val.ival>3));
 		    
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3 + ' ' + $<text>4; 
            // printf("Hurray!\n");
            fprintf(lf, "Line %d: declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n%s\n\n", @4.last_line, $<text>$.c_str());
        } 
            | error { error_line_no = @[error].last_line; yyerror("Syntax error in declaration_list"); }
            | declaration_list error { error_line_no = @[error].last_line; yyerror("Syntax error in declaration_list"); }

 		  ;
 		  
statements : statement{
            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: statements : statement\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            $<code>$ = $<code>1; 
            
            iTemp = -2; 
        }

	   | statements statement{
            $<text>$ = $<text>1 + '\n' + $<text>2; 
            fprintf(lf, "Line %d: statements : statements statement\n\n%s\n\n", @2.last_line, $<text>$.c_str());
            $<code>$ = $<code>1 + $<code>2; 
            
            iTemp = -2; 
        } 
        
        | error  {
            $<text>$ = "";
            printf("First line getting discarded\n");
            error_line_no = @1.last_line; 
            yyerror("Syntax Error");
            //yyerrok;
            //yyclearin; 
        }
        
        | statements error  {
            $<text>$ = "";
            printf("Consec line getting discarded\n");
            error_line_no = @2.last_line; 
            yyerror("Syntax Error");
            //yyerrok;
            //yyclearin; 
        }
        
	   ;
	   
statement : var_declaration{
            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: statement : var_declaration\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            $<code>$ = "; " + $<text>1 + '\n' + $<code>1; 
        }

	  | expression_statement{
            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: statement : expression_statement\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            $<code>$ = "; " + $<text>1 + '\n' + $<code>1; 
        }

	  | compound_statement{
            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: statement : compound_statement\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            
            $<code>$ = $<code>1; 
        }

	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement{
            if($<type>[expression] == _VOID) {
                error_line_no = @3.last_line; 
                yyerror((char*)((est + "Void function used in expression").c_str()));
                yyerrok; 
            }
            
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3 + ' ' + $<text>4 + ' ' + $<text>5 + ' ' + $<text>6 + ' ' + $<text>7; 
            fprintf(lf, "Line %d: statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n%s\n\n", @7.last_line, $<text>$.c_str());
            
            string beg = new_label(), aft = new_label(); 
            
            $<code>$ =  $<code>3 
                        + beg + ":\n" 
                        + $<code>4
                        + "\tCMP " + $<temp>4 + ", 0\n"
                        + "\tJZ " + aft + " ; !!line no " + to_string(@4.last_line) + "\n"
                        + $<code>7 // for's statement
                        + $<code>5 
                        + "\tJMP " + beg + "\n"
                        + aft + ":\n";
        }

      | IF LPAREN expression RPAREN statement %prec DUMMY_THEN{
            if($<type>[expression] == _VOID) {
                error_line_no = @3.last_line; 
                yyerror((char*)((est + "Void function used in expression").c_str()));
                yyerrok; 
            }
            
            $<text>$ = $<text>1 + $<text>2 + $<text>3 + $<text>4 + $<text>5; 
            fprintf(lf, "At line no. %d statement : IF LPAREN expression RPAREN statement\n\n%s\n\n", @5.last_line, $<text>$.c_str());
            
            string aft = new_label(); 
            
            $<code>$ = $<code>[expression] 
                        + "\tCMP " + $<temp>[expression] + ", 0\n"
                        + "\tJZ " + aft + " ; line no " + to_string(@[expression].last_line) + "\n"
                        + $<code>5
                        + aft + ":\n";
        }

	  | IF LPAREN expression RPAREN statement ELSE statement{
            if($<type>[expression] == _VOID) {
                error_line_no = @3.last_line; 
                yyerror((char*)((est + "Void function used in expression").c_str()));
                yyerrok; 
            }
            
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3 + ' ' + $<text>4 + ' ' + $<text>5 + ' ' + $<text>6 + ' ' + $<text>7; 
            fprintf(lf, "Line %d: statement : IF LPAREN expression RPAREN statement ELSE statement\n\n%s\n\n", @7.last_line, $<text>$.c_str());
            
            string aft = new_label(), else_stmt = new_label(); 
            
            $<code>$ = $<code>[expression] 
                        + "\tCMP " + $<temp>[expression] + ", 0\n"
                        + "\tJZ " + else_stmt + " ; line no " + to_string(@[expression].last_line) + "\n"
                        + $<code>5 // if's statement
                        + "\tJMP " + aft + "\n"
                        + else_stmt + ":\n"
                        + $<code>7 // else's statement
                        + aft + ":\n";
        }

	  | WHILE LPAREN expression RPAREN statement{
            if($<type>[expression] == _VOID) {
                error_line_no = @3.last_line; 
                yyerror((char*)((est + "Void function used in expression").c_str()));
                yyerrok; 
            }
            
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3 + ' ' + $<text>4 + ' ' + $<text>5; 
            fprintf(lf, "Line %d: statement : WHILE LPAREN expression RPAREN statement\n\n%s\n\n", @5.last_line, $<text>$.c_str());
            
            string beg = new_label(), aft = new_label(); 
            
            $<code>$ =  beg + ":\n" + $<code>[expression]
                        + "\tCMP " + $<temp>[expression] + ", 0\n"
                        + "\tJZ " + aft + " ; line no " + to_string(@[expression].last_line) + "\n"
                        + $<code>5 // while's statement
                        + "\tJMP " + beg + "\n"
                        + aft + ":\n";
        }

	  | PRINTLN LPAREN variable RPAREN SEMICOLON { // changed ID to variable 
            /*if(!table.lookup($<text>3, _temp)) {
                error_line_no = @3.last_line; 
                yyerror((char*)((est + "Undeclared variable " + $<text>3).c_str()));
                yyerrok; 
            }*/
            
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3 + ' ' + $<text>4 + ' ' + $<text>5; 
            fprintf(lf, "Line %d: statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n%s\n\n", @4.last_line, $<text>$.c_str());
            
            $<code>$ = ""; 
            $<temp>$ = $<val.infoptr>[variable]->get_code(); 
            
            if($<temp>$.find('@') != string::npos) { //an array 
                $<code>$ += $<idx>3; 
                $<temp>$ += "[BX]";
            }
            
            $<code>$ += "\tMOV AX, " + $<temp>$
                        + "\n\tCALL OUTDEC ; line no: " + to_string(@4.last_line) + '\n'; 
        }

	  | RETURN expression SEMICOLON {
            if($<type>[expression] == _VOID) {
                error_line_no = @3.last_line; 
                yyerror((char*)((est + "Void function used in expression").c_str()));
                yyerrok; 
            }
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3; 
            fprintf(lf, "Line %d: statement : RETURN expression SEMICOLON\n\n%s\n\n", @3.last_line, $<text>$.c_str());
        
            $<code>$ = $<code>2;
            $<code>$ += "\n\tMOV DX, " + $<temp>2 
                        + "\n\tPUSH CX"
                        + "\n\tRET ; line no: " + to_string(@3.last_line) + "\n"; 
        }
        
        | RETURN SEMICOLON {
            $<text>$ = $<text>1 + ' ' + $<text>2; // + ' ' + $<text>3; 
            fprintf(lf, "Line %d: statement : RETURN SEMICOLON\n\n%s\n\n", @2.last_line, $<text>$.c_str());
            
            $<code>$ = "\n\tRET ; line no: " + to_string(@2.last_line) + "\n"; 
        }
        
        | func_definition {
            $<text>$ = ""; 
            error_line_no = @1.last_line; 
            yyerror("Illegal scoping of function definition."); 
            yyerrok;
        }
        
        | func_declaration {
            $<text>$ = ""; 
            error_line_no = @1.last_line; 
            yyerror("Illegal scoping of function declaration."); 
            yyerrok;
        }
        
	  ;
	  

	  
expression_statement 	: SEMICOLON	{
            $<type>$ = _UNKNOWN; 
            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: expression_statement : SEMICOLON	\n\n%s\n\n", @1.last_line, $<text>$.c_str());
        }
	
			| expression SEMICOLON {
            $<type>$ = _UNKNOWN; 
            $<text>$ = $<text>1 + ' ' + $<text>2; 
            fprintf(lf, "Line %d: expression_statement : expression SEMICOLON	\n\n%s\n\n", @2.last_line, $<text>$.c_str());
            
            $<code>$ = $<code>1; 
            $<temp>$ = $<temp>1; 
            //iTemp = -2; //reset iTemp 
        }

			;
	
variable : ID { 

            symbol_info* id = table.lookup($<text>1, _temp); 
            
            if(!id){
                error_line_no = @1.last_line; 
                yyerror((char*)((est + "Undeclared variable " + $<text>1).c_str()));
                yyerrok; 
            }
            else{
                $<type>$ = id ? static_cast<my_dtype>(id->dtype()) : _UNKNOWN; 
                $<val.infoptr>$ = id; 

                // cout << "Hello id: " << (int) $<type>$ << endl;
                if($<type>$ >= _FUNC_OFFSET){
                    error_line_no = @1.last_line; 
                    yyerror((char*)((est + "Type mismatch, " + $<text>1 + " is a function").c_str()));
                    yyerrok; 
                } 
                else if($<type>$ >= _ARR_OFFSET){
                    error_line_no = @1.last_line; 
                    yyerror((char*)((est + "Type mismatch, " + $<text>1 + " is an array").c_str()));
                    yyerrok; 
                } 
            }
            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: variable : ID\n\n%s\n\n", @1.last_line, $<text>$.c_str()); 
            
            $<val.infoptr>$ = id; 
            $<temp>$ = new_temp(); 
            
            $<code>$  = "\tMOV AX, " + id->get_code() + " ;\n";
            $<code>$ += "\tMOV " + $<temp>$ + ", AX ; line no: " + to_string(@1.last_line) + "\n";  
        }

        | ID LTHIRD expression RTHIRD {
        
            symbol_info* id = table.lookup($<text>1, _temp);
            
            if(!id){
                error_line_no = @1.last_line; 
                yyerror((char*)((est + "Undeclared array " + $<text>1).c_str()));
                yyerrok; 
            } 
            else{
                $<type>$ = id ? static_cast<my_dtype>(id->dtype()) : _UNKNOWN; 
                $<val.infoptr>$ = id; 
                
                if($<type>3 != _INT){
                    error_line_no = @3.last_line; 
                    yyerror_multiple((char*)((est + "Expression inside third brackets not an integer").c_str()));
                    yyerrok; 
                }
                if($<type>$ < _ARR_OFFSET) { 
                    error_line_no = @1.last_line; 
                    yyerror_multiple((char*)(($<text>[ID] + " not an array").c_str()));
                    yyerrok; 
                }
                else if($<type>$ >= _FUNC_OFFSET) { 
                    error_line_no = @1.last_line; 
                    yyerror_multiple((char*)(($<text>[ID] + " not an array").c_str()));
                    yyerrok; 
                }
                
                $<type>$ = static_cast<my_dtype>($<type>$ - _ARR_OFFSET);
            }
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3 + ' ' + $<text>4; 
            fprintf(lf, "Line %d: variable : ID LTHIRD expression RTHIRD\n\n%s\n\n", @4.last_line, $<text>$.c_str()); 
            
            $<code>$ = $<code>[expression]; 
            
            $<val.infoptr>$ = id; 
            $<temp>$ = new_temp(); 
            
            $<code>$ += "\tMOV BX, " + $<temp>[expression] + " ;\n";
            $<code>$ += "\tADD BX, BX ;\n";
            $<code>$ += "\tMOV AX, " + id->get_code() + "[BX]\n";
            $<code>$ += "\tMOV " + $<temp>$ + ", AX; line no: " + to_string(@1.last_line) + "\n"; 
            
            $<idx>$ = $<code>[expression] + "\tMOV BX, " + $<temp>[expression] + " ;\n\tADD BX, BX ;\n";
            
        }

	 ;
	 
expression : logic_expression 	{
            //cout << __LINE__ << " " << $<text>1 << endl; 
            /*if($<type>1 == _VOID) {
                error_line_no = @1.last_line; 
                yyerror((char*)((est + "Void function used in expression").c_str()));
                yyerrok; 
            }*/
            $<type>$ = $<type>1; 
            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: expression : logic expression\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            
            $<temp>$ = $<temp>1;
            $<code>$ = $<code>1; 
        }

	   | variable ASSIGNOP logic_expression {
            if($<type>3 == _VOID) {
                error_line_no = @3.last_line; 
                yyerror((char*)((est + "Void function used in expression").c_str()));
                yyerrok; 
            }
            $<type>$ = $<type>1; 
            // cout << $<text>1 << " " << "var = l_exp type " << $<type>1 << " = " << $<type>3  << endl; 
            if($<type>1 < $<type>3) {
                error_line_no = @2.last_line; 
                yyerror((char*)((est + "Type Mismatch").c_str()));
                yyerrok; 
            }
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3; 
            fprintf(lf, "Line %d: expression : variable ASSIGNOP logic_expression\n\n%s\n\n", @3.last_line, $<text>$.c_str());
            
            //cout << "LINE " << 1067 << endl; 
            $<temp>$ = $<val.infoptr>1->get_code();
            $<code>$ = $<code>3;  
            
            //cout << "LINE " << 1071 << endl; 
            
            if($<temp>$.find('@') != string::npos) { //an array 
                $<code>$ += $<idx>1; 
                $<temp>$ += "[BX]";
            }
            
            //cout << "LINE " << __LINE__ << endl; 
            
            /// beware of AX's use 
            $<code>$ += "\tMOV AX, " + $<temp>3 + "\n\tMOV " + $<temp>$ + ", AX ; line no: " + to_string(@3.last_line) + "\n"; 
        }

	   ;
			
logic_expression : rel_expression 	{ 
            //cout << __LINE__ << " " << $<text>1 << endl; 
            $<type>$ = $<type>1; 
            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: logic_expression : rel_expression\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            //cout << __LINE__ << " " << $<text>1 << endl; 
            
            $<temp>$ = $<temp>1;
            $<code>$ = $<code>1; 
        }

		 | logic_expression /* rel_expression */ LOGICOP rel_expression 	{
            $<type>$ = ($<type>1 == _VOID || $<type>3 == _VOID) ? _VOID : _INT; 
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3; 
            fprintf(lf, "Line %d: logic_expression : rel_expression LOGICOP rel_expression\n\n%s\n\n", @3.last_line, $<text>$.c_str());
            
            $<temp>$ = $<temp>1;
            string temp = ($<val.cval>[LOGICOP] == '|') ? "OR" : "AND"; 
            $<code>$ = $<code>1 + $<code>3;
            
            $<code>$ += "\tMOV AX, " + $<temp>3 + " ;\n"; 
            //$<code>$ += "\tMOV " + $<temp>$ + ", AX ;\n";
            //$<code>$ += "\tMOV AX, " + $<temp>1 + " ;\n"; 
            $<code>$ += "\t" + temp + " " + $<temp>1 + ", AX ; line no: " + to_string(@3.last_line) + "\n"; 
        }

		 ;
			
rel_expression	: simple_expression {
            //cout << __LINE__ << " " << $<text>1 << endl; 
            $<type>$ = $<type>1; 
            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: rel_expression	: simple_expression\n\n%s\n\n", @1.last_line, $<text>$.c_str());  
            
            $<temp>$ = $<temp>1;
            $<code>$ = $<code>1; 
        }

		| simple_expression RELOP simple_expression	{
            $<type>$ = ($<type>1 == _VOID || $<type>3 == _VOID) ? _VOID : _INT; 
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3; 
            fprintf(lf, "Line %d: rel_expression	: simple_expression RELOP simple_expression\n\n%s\n\n", @3.last_line, $<text>$.c_str());            
            
            $<temp>$ = $<temp>1;
            
            string label = new_label(); 
            
            $<code>$ = $<code>1 + $<code>3
                    + "\tMOV AX, " + $<temp>3 
                    + "\n\tCMP " + $<temp>1 + ", AX"
                    + "\n\tMOV " + $<temp>$ + ", 0"
                    + "; line no: " + to_string(@3.last_line) + "\n";  
                    
            if($<text>2 == "==") 
                $<code>$ += "\tJNE " + label + "\n"; 
            else if($<text>2 == "!=") 
                $<code>$ += "\tJE " + label + "\n"; 
            else if($<text>2 == "<=") 
                $<code>$ += "\tJNLE " + label + "\n"; 
            else if($<text>2 == ">=") 
                $<code>$ += "\tJNGE " + label + "\n"; 
            else if($<text>2 == "<") 
                $<code>$ += "\tJNL " + label + "\n"; 
            else if($<text>2 == ">") 
                $<code>$ += "\tJNG " + label + "\n"; 
            
            
            $<code>$ += "\n\tMOV " + $<temp>$ + ", 1 ; line no: " + to_string(@3.last_line) + "\n\n" + label + ":\n"; 
        }

		;
				
simple_expression : term {
            ////cout << __LINE__ << endl; 
            $<type>$ = $<type>1; 
            ////cout << __LINE__ << endl; 

            $<text>$ = $<text>1; 
            ////cout << __LINE__ << endl; 
            fprintf(lf, "Line %d: simple_expression : term\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            ////cout << __LINE__ << endl; 
            
            $<temp>$ = $<temp>1;
            $<code>$ = $<code>1; 
        }

		  | simple_expression ADDOP term {
            $<type>$ = MAX($<type>1, $<type>3); 
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3; 
            fprintf(lf, "Line %d: simple_expression : simple_expression ADDOP term\n\n%s\n\n", @3.last_line, $<text>$.c_str());
            
            $<temp>$ = $<temp>1;
            $<code>$ = $<code>1 + $<code>[term];
            
            string temp = ($<val.cval>[ADDOP] == '-') ? "SUB" : "ADD"; 
            
            $<code>$ += "\tMOV AX, " + $<temp>[term] + " ;\n"; 
            //$<code>$ += "\tMOV " + $<temp>$ + ", AX ;\n";
            //$<code>$ += "\tMOV AX, " + $<temp>1 + " ;\n"; 
            $<code>$ += "\t" + temp + " " + $<temp>$ + ", AX ; line no: " + to_string(@3.last_line) + "\n"; 
        }

		  ;
					
term :	unary_expression {
            $<type>$ = $<type>1; 
            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: term : unary_expression\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            
            $<temp>$ = $<temp>1; 
            $<code>$ = $<code>[unary_expression]; 
        }

     |  term MULOP unary_expression  { 
            $<type>$ = MAX($<type>1, $<type>3);  // _INT < _FLOAT 
            
            if($<val.cval>2 == '%' && $<type>$ != _INT){  // MAX(_INT, _INT) would be _INT 
                error_line_no = @2.last_line; 
                yyerror_multiple((char*)((est + "Non-Integer operand on modulus operator").c_str()));
                yyerrok; 
                $<type>$ = _INT; 
            } 
            try{
                double exp_val = stod($<text>3); 
                error_line_no = @2.last_line;
                if(!exp_val){
                    switch($<val.cval>2){
                        case '%':
                            yyerror_multiple((char*)((est + "Modulus by zero").c_str()));
                            break; 
                        case '/':
                            yyerror_multiple((char*)((est + "Division by zero").c_str()));
                    }
                }
                yyerrok; 
            }
            catch (const std::invalid_argument& z) {
                // cout << "An exception caught " << z.what() << endl; 
            }
            // if(!$<val.ival>3 )
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3; 
            fprintf(lf, "Line %d: term : term MULOP unary_expression\n\n%s\n\n", @3.last_line, $<text>$.c_str());
            
            $<code>$ = $<code>1 + $<code>3;
            $<temp>$ = $<temp>1; 
            
            if($<val.cval>2 == '*') {
                $<code>$ += "\tMOV AX, " + $<temp>1 + "\n";
                $<code>$ += "\tIMUL " + $<temp>3 + "\n"; 
                $<code>$ += "\tMOV " + $<temp>$ + ", AX"; 
            }
            else {
                $<code>$ += "\tXOR DX, DX\n";
                $<code>$ += "\tMOV AX, " + $<temp>1 + "\n";
                $<code>$ += "\tIDIV " + $<temp>3 + "\n"; 
                if($<val.cval>2 == '/')
                    $<code>$ += "\tMOV " + $<temp>$ + ", AX";
                else if($<val.cval>2 == '%')
                    $<code>$ += "\tMOV " + $<temp>$ + ", DX";
            }
            
            $<code>$ += " ; line no: " + to_string(@3.last_line) + "\n"; 
        }
     ;

unary_expression : ADDOP unary_expression  { 
            if($<type>2 == _VOID){
                error_line_no = @2.last_line; 
                yyerror((char*)((est + "Void function used in expression").c_str()));
                yyerrok; 
                $<type>$ = _INT; // so that the error does not propagate
            }
            else
                $<type>$ = $<type>2; 
            $<text>$ = $<text>1 + ' ' + $<text>2; 
            fprintf(lf, "Line %d: unary_expression : ADDOP unary_expression\n\n%s\n\n", @2.last_line, $<text>$.c_str()); 
            
            if($<val.cval>[ADDOP] == '-') {
                $<temp>$ = $<temp>2; 
                $<code>$ = $<code>2 + "\tNEG " + $<temp>$ + " ; line no: " + to_string(@$.last_line) + "\n"; 
            }
        }
        | NOT unary_expression {
            $<text>$ = $<text>1 + ' ' + $<text>2; 
            fprintf(lf, "Line %d: unary_expression : NOT unary_expression\n\n%s\n\n", @2.last_line, $<text>$.c_str());
            $<type>$ = _INT; // to comply with specs  
            
            switch($<type>1){
                case _VOID:
                    error_line_no = @2.last_line; 
                    yyerror((char*)((est + "Void function used in expression").c_str()));
                    yyerrok; 
                    $<type>$ = _INT; // why propagate the void error ??   
                    break;
                case _INT: 
                    $<val.bval>$ = ($<val.ival>1==0); 
                    break; 
                case _FLOAT:
                    $<val.bval>$ = ($<val.fval>1==0); 
                    break; 
                case _BOOLEAN:
                    $<val.bval>$ = !$<val.bval>1;
                    break; 
                default:
                    break;
            }
            
            $<temp>$ = $<temp>2; 
            $<code>$ = $<code>2 + "\tNOT " + $<temp>$ + " ; line no: " + to_string(@$.last_line) + "\n"; 
            
		 }
        | factor {
            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: unary_expression : factor\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            switch($<type>1){
                case _INT: 
                    $<val.ival>$ = $<val.ival>1; 
                    break; 
                case _FLOAT:
                    $<val.fval>$ = $<val.fval>1; 
                    break; 
                default:
                    break;
            }
            
            $<type>$ = $<type>1; 
            
            $<temp>$ = $<temp>[factor];
            
            
		 }
		 ;
	

factor	: variable {
            $<type>$ = $<type>1; 

            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: factor	: variable\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            
            $<code>$ = $<code>1; 
            $<temp>$ = $<temp>[variable]; 
        }
        | ID LPAREN argument_list RPAREN{
        
            symbol_info* s_id = table.lookup($<text>1, _temp);
            func_info* id = dynamic_cast<func_info*> (s_id); 
            if(id){
                if(id->is_defined) {
                    if (($<type>$ = id ? static_cast<my_dtype>(id->dtype()) : _UNKNOWN) >= _FUNC_OFFSET){
                        $<val.infoptr>$ = id;
                        // cout << "In ID " << $<text>1 << ", the match value is : " << id->of_similar_type($<val.args>3) << '\n';
                        int _switch = (id->of_similar_type($<val.args>3));
                        if(_switch == _SIZE_MISMATCH) { 
                            error_line_no = @3.last_line; 
                            yyerror_multiple((char*)((est + "Total number of arguments mismatch in function " + $<text>1).c_str()));
                            yyerrok; 
                        }
                        else if(_switch > _TYPE_MISMATCH) { 
                            _switch -= _TYPE_MISMATCH; 
                            error_line_no = @3.last_line; 
                            yyerror_multiple((char*)((to_string(_switch) + "th argument mismatch in function " + $<text>1).c_str()));
                            yyerrok;
                            // break; 
                        }
                    }
                }
                else{
                    $<type>$ = static_cast<my_dtype>(id->dtype());
                    error_line_no = @1.last_line; 
                    yyerror_multiple((char*)((est + "Declared but undefined function " + $<text>1).c_str()));
                    yyerrok;  
                }
            }
            else{
                error_line_no = @1.last_line; 
                yyerror_multiple((char*)((est + "Undeclared function " + $<text>1).c_str()));
                yyerrok; 
            } 
            $<type>$ = static_cast<my_dtype>($<type>$ - _FUNC_OFFSET);

            $<text>$ = $<text>1+$<text>2+$<text>3+$<text>4; 
            fprintf(lf, "Line %d: factor : ID LPAREN argument_list RPAREN\n\n%s\n\n", @4.last_line, $<text>$.c_str());
            int legTemp = iTemp;
        
            /*if($<text>[ID] == "fibo") {
                cout << table.push_current_scope(); 
                table.print_active_tables(cout); 
            }*/
        
            $<code>$ = $<code>[argument_list]; 
            $<code>$ += "\tPUSH CX ; save ret address"; 
            $<code>$ += table.push_current_scope(); 
            $<code>$ += push_temp_vars(legTemp); 
            $<code>$ += $<idx>[argument_list];
            $<code>$ += "\tCALL " + $<text>[ID] + "\n"; 
            if($<type>$ == _INT){
                $<temp>$ = new_temp(); 
                $<code>$ += "\tMOV " + $<temp>$ + ", DX\n";
            }
            $<code>$ += pop_temp_vars(legTemp); 
            $<code>$ += table.pop_current_scope();
            $<code>$ += "\tPOP CX ; retrieve ret address\n"; 
        }
        | LPAREN expression RPAREN {
            $<type>$ = $<type>2; 
            $<text>$ = $<text>1+$<text>2+$<text>3; 
            fprintf(lf, "Line %d: factor : LPAREN expression RPAREN\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            
            $<temp>$ = $<temp>[expression];  
            $<code>$ = $<code>[expression]; 
        }
        | CONST_INT {
            $<text>$ = $<text>1; 
            //printf("%d %d\n", @1.first_line, $1); 
            //printf("\n\t%s\n", yytext); 
            fprintf(lf, "Line %d: factor : CONST_INT\n\n%d\n\n", @1.last_line, $<val>1.ival); 
        
            $<val.ival>$ = $<val.ival>1;
            $<type>$ = _INT; 
            
            
            $<temp>$ = new_temp(); 
            $<code>$ = "\tMOV " + $<temp>$ + ", " + $<text>$ + " ; line no: " + to_string(@$.last_line) + "\n"; 
            
        }
        | CONST_FLOAT {
            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: factor : CONST_FLOAT\n\n%g\n\n", @1.last_line, $<val.fval>1); 
            
            $<val.fval>$ = $<val.fval>1;
            $<type>$ = _FLOAT;  
        }
        | variable INCOP {
            $<type>$ = $<type>1; 
            
            $<text>$ = $<text>1 + ' ' + $<text>2; 
            fprintf(lf, "Line %d: factor : variable INCOP\n\n%s\n\n", @$.last_line, $<text>$.c_str());
            
            $<temp>$ = $<temp>[variable]; 
            $<code>$ = "\tMOV AX, " + $<val.infoptr>1->get_code(); 
            $<code>$ += "\n\tMOV " + $<temp>$ + ", AX";  
            $<code>$ += "\n\tINC " + $<val.infoptr>1->get_code() + " ; line no: " + to_string(@$.last_line) + "\n"; 
        }
        | variable DECOP{ 
            $<type>$ = $<type>1; 
            
            $<text>$ = $<text>1 + ' ' + $<text>2; 
            fprintf(lf, "Line %d: factor : variable DECOP\n\n%s\n\n", @$.last_line, $<text>$.c_str());
            
            $<temp>$ = $<temp>[variable];  
            $<code>$ = "\tMOV AX, " + $<val.infoptr>1->get_code(); 
            $<code>$ += "\n\tMOV " + $<temp>$ + ", AX";  
            $<code>$ += "\n\tDEC " + $<val.infoptr>1->get_code() + " ; line no: " + to_string(@$.last_line) + "\n"; 
        }
        ;
	
argument_list : arguments{
            $<val.args>$ = $<val.args>1; 
            
            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: argument_list : arguments\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            
            $<code>$ = $<code>1 + " ; line no " + to_string(@1.last_line) + "\n"; 
            $<idx>$ = $<idx>1; 
	      } 
	      | %empty {
            $<val.args>$ = new queue<int>;
            $<text>$ = "";
            fprintf(lf, "Line %d: argument_list : %%empty\n\n%s\n\n", @$.last_line, $<text>$.c_str());
          } 
          
          | error {error_line_no = @[error].last_line;  yyerror("Syntax error in argument_list."); }
          | arguments error {error_line_no = @[error].last_line;  yyerror("Syntax error in argument_list."); }
          ;
	
arguments : arguments COMMA logic_expression {

            $<val.args>$->emplace($<type>1); 
            
            $<text>$ = $<text>1 + ' ' + $<text>2 + ' ' + $<text>3; 
            fprintf(lf, "Line %d: arguments : arguments COMMA logic_expression\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            
            $<code>$ = $<code>1 + $<code>3; 
            $<idx>$ = "\tPUSH " + $<temp>3 + "\n" + $<idx>1; 
	      }
	      | logic_expression { 
	      
            $<val.args>$ = new queue<int>; /* val.args keeps the argument types */
            $<val.args>$->emplace($<type>1); 
            
	      
            $<text>$ = $<text>1; 
            fprintf(lf, "Line %d: arguments : logic_expression\n\n%s\n\n", @1.last_line, $<text>$.c_str());
            
            $<code>$ = $<code>1; 
            $<idx>$ = "\tPUSH " + $<temp>1 + "\n"; 
	      } 
	      ;


%%
int main(int argc, char *argv[])
{

	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	/*fp2= fopen(argv[2],"w");
	fclose(fp2);
	fp3= fopen(argv[3],"w");
	fclose(fp3);
	
	fp2= fopen(argv[2],"a");
	fp3= fopen(argv[3],"a");*/
	

	yyin=fp;
	
	//log = ofstream(string("my_log.txt"));
	
	//yyin = fopen("in.txt", "r"); 
	
	lf = fopen("log.txt", "w"); 
	//lf = stdout; 
	ef = fopen("error.txt", "w");
	//ef = stdout; 
	
	//FILE *temp = fopen("template.asm", "r"); 
	cf = fopen("code.asm", "w"); 
	
	/*while(temp && cf && (c = fgetc(temp)) != EOF) 
        fputc(c, cf); */
	
	yyparse();
	//yylex();
	
/*
	fclose(fp2);
	fclose(fp3);
	*/
	
	fclose(lf); 
	fclose(ef);
	fclose(cf); 
	return 0;
}

