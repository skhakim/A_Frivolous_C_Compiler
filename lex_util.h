#include <bits/stdc++.h>
#include "symbol_table.h"
using namespace std;

#define BUCKET_SIZE 7
#define _CHAR_CONST "CHAR_CONST"
#define _CONST_CHAR "CONST_CHAR"

string temp, empt_st("");
string replace_escape_chars(const string& str)
{
    string out = "";
    for(auto it=str.begin(); it!=str.end(); ++it)
    {
        if(*it == '\\')
        {
            ++it;
            if(it == str.end())
                break;
            switch(*it)
            {
            case 'a':
                out += '\a';
                break;
            case 'b':
                out += '\b';
                break;
            case 'f':
                out += '\f';
                break;
            case 'n':
                out += "\n";
                break;
            case 'r':
                out += '\r';
                break;
            case 't':
                out += '\t';
                break;
            case 'v':
                out += '\v';
                break;
            case '\'':
                out += '\'';
                break;
            case '\\':
                out += '\\';
                break;
            case '0':
                out += '\0';
                break;

            ///I am uncertain on this
            case '\r':
            case '\n':
                break;
            default:
                out += *it;
            }
            if(*it == '\r' && *(it+1) == '\n')
                ++it;
        }
        else
        {
            out += *it;
        }
    }
    return out;
}

inline string without_last(const string& y){
  if(*(y.end()-1) == '\n'){
      if(*(y.end()-2) == '\r'){
        return string(y.begin(), y.end()-2);
      }
      return string(y.begin(), y.end()-1);
  }
  return y;
}


class lex_util
{

    // symbol_table table;
    ofstream log;
    ofstream token;
    int _line;
    int _err;
    string _comment, _string;

public:

    lex_util() : _line(1), _err(0)
    {
        log = ofstream("1705002_lexical_log.txt");
        token = ofstream("1705002_lexical_token.txt");
        // error = ofstream
    }

    void reset_line_count(int x)
    {
        //if(x<_line) return;
        _line = x;
    }

    void keyword(const string& str)
    {
        string t(str);
        for(auto& x:t)
            x = toupper(x);
        token << "<" << t << "> ";
        usual_log(str, t);
    }

    void identifier(const string& str)
    {
        token << "<ID, " << str << "> ";
        usual_log(str, "ID");


        // if(!table.insert(str, "ID", temp))
        {
            log << endl << temp << endl;
            return;
        }

        log << endl;
        // table.print_active_tables(log);
        //log << endl;
    }

    ///operators

    void addop(const string& str)
    {
        token << "<ADDOP, " << str << "> ";
        usual_log(str, "ADDOP");
    }

    void mulop(const string& str)
    {
        token << "<MULOP, " << str << "> ";
        usual_log(str, "MULOP");
    }

    void incop(const string& str)
    {
        token << "<INCOP, " << str << "> ";
        usual_log(str, "INCOP");
    }

    void relop(const string& str)
    {
        token << "<RELOP, " << str << "> ";
        usual_log(str, "RELOP");
    }

    void logicop(const string& str)
    {
        token << "<LOGICOP, " << str << "> ";
        usual_log(str, "LOGICOP");
    }

    void assignop()
    {
        token << "<ASSIGNOP, => ";
        usual_log("=", "ASSIGNOP");
    }

    void notop()
    {
        token << "<NOT, !> ";
        usual_log("!", "NOT");
    }

    /// numbers
    void integer(const string& str)
    {
        token << "<CONST_INT, " << str << "> ";
        usual_log(str, "CONST_INT");
        // if(!table.insert(str, "CONST_INT", temp))
        {
            log << endl << temp << endl;
            return;
        }
        log << endl;
        // table.print_active_tables(log);
    }

    void floating(const string& str)
    {
        token << "<CONST_FLOAT, " << str << "> ";
        usual_log(str, "CONST_FLOAT");
        // if(!table.insert(str, "CONST_FLOAT", temp))
        {
            log << endl << temp << endl;
            return;
        }
        log << endl;
        // table.print_active_tables(log);
    }


    /// char
    void def_char(const string& str)  //  --> <CHAR_CONST, 	>
    {
        token << "<" << _CHAR_CONST << ", " << str[1] << "> ";
        log << endl << "Line no " << _line << ": Token <" << _CONST_CHAR
            << "> Lexeme " << str << "found --> <" << _CHAR_CONST << ", " << str[1] << "> " << endl;
        // if(!table.insert(str, _CONST_CHAR, temp))
        {
            log << endl << temp << endl;
            return;
        }
        log << endl;
        // table.print_active_tables(log);
    }


    void esc_char(const string& str)
    {
        string rep = replace_escape_chars(str);
        token << "<" << _CHAR_CONST << ", " << string(rep.begin()+1, rep.end()-1) << "> ";
        log << endl << "Line no " << _line << ": Token <" << _CONST_CHAR
            << "> Lexeme " << str << "found --> <" << _CHAR_CONST << ", " << rep.c_str()[1] << "> " << endl;
        // if(!table.insert(str, _CONST_CHAR, temp))
        {
            log << endl << temp << endl;
            return;
        }
        log << endl;
        // table.print_active_tables(log);
    }

    /// strings
    void sl_str(const string& str){
        string rep = replace_escape_chars(str);
        rep = string(rep.begin()+1, rep.end()-1);
        token << "<" << "STRING" << ", \"" << rep << "\"> ";
        log << endl << "Line no " << _line << ": Token <" << "STRING"
            << "> Lexeme " << str << "found --> <" << "STRING" << ", \"" << rep.c_str() << "\"> " << endl;
        //table.insert(str, "STRING", temp);
    }

    ///punctuations
    void comma()
    {
        token << "<COMMA ,,> ";
        usual_log(",", "COMMA");
    }

    void semicolon()
    {
        token << "<SEMICOLON, ;> ";
        usual_log(";", "SEMICOLON");
    }

    void lcurl()
    {
        // table.enter_scope();
        usual_log("{", "LCURL");
        token << "<LCURL, {> ";
    }

    void rcurl()
    {
        // table.exit_scope();
        usual_log("}","RCURL");
        token << "<RCURL, }> ";
    }

    void lparen()
    {
        usual_log("(", "LPAREN");
        token << "<LPAREN, (> ";
    }

    void rparen()
    {
        usual_log(")","RPAREN");
        token << "<RPAREN, )> ";
    }

    void lthird()
    {
        usual_log("[","LTHIRD");
        token << "<LTHIRD, [> ";
    }

    void rthird()
    {
        usual_log("]","RTHIRD");
        token << "<RTHIRD, ]> ";
    }

    void newline()
    {
        //_line++;
    }

    /// Comments
    void comment(const string& str)
    {
        usual_log(without_last(str), "COMMENT");
    }

    void begin_mlc()
    {
        // printf("Comment started: /* ");
        _comment = "/*";
    }

    void begin_str()
    {
        _string = "\"";
    }

    void add_mlc(const string& str)
    {
        // printf(" %s ", str.c_str());
        _comment += str;
    }

    void add_str(const string& str)
    {
        //printf(" %s ", str.c_str());
        _string += str;
    }

    void end_mlc(int x)
    {
        // printf(" : ended.\n");
        _comment += "*/";
        usual_log(_comment, "COMMENT");
        _line = x;
    }

    void end_str()
    {
        _string += "\"";
        sl_str(_string);
    }

    /// Errors

    /// Numeric Errors
    string multiple_radices(const string& str)
    {
        ++_err;
        temp = empt_st + "Error at line no " + to_string(_line) + ": Too many decimal points " + str + "\n";
        log << endl << temp;
        return temp;
    }

    string ill_formed_number(const string& str)
    {

        ++_err;
        temp = empt_st + "Error at line no " + to_string(_line) + ": Ill formed number " + str + "\n";
        log << endl << temp;
        return temp;
    }

    string invalid_id_prefix(const string& str)
    {
        //cout << "The str that came : " << str << endl;
        ++_err;
        temp = empt_st + "Error at line no " + to_string(_line)
            + ": Invalid prefix on ID or invalid suffix on Number "  + str + "\n";
        log << endl << temp;
        return temp;
    }

    /// char and string errors
    string multichar(const string& str)
    {
        ++_err;
        temp = empt_st + "Error at line no " + to_string(_line) + ": Multi character constant error " + str + "\n";
        log << endl << temp;
        return temp;
    }

    string empchar(const string& str)
    {
        ++_err;
        temp = empt_st + "Error at line no " + to_string(_line) + ": Empty character constant error " + str + "\n";
        log << endl << temp;
        return temp;
    }

    string unfchar(const string& str)
    {
        ++_err;
        temp = empt_st + "Error at line no " + to_string(_line) + ": Unterminated character " + without_last(str) + "\n";
        log << endl << temp;
        return temp;
    }

    string unfstr(const string& str)
    {
        ++_err;
        temp = empt_st + "Error at line no " + to_string(_line) + ": Unterminated String " + without_last(str) + "\n";
        log << endl << temp;
        return temp;
    }/**/

    string unfstring()
    {
        ++_err;
        temp = empt_st + "Error at line no " + to_string(_line) + ": Unterminated String " + _string + "\n";
        log << endl << temp;
        return temp;
    }/**/

    /// comment error
    string unfcmnt(int x)
    {
        ++_err;
        temp = empt_st + "Error at line no " + to_string(_line) + ": Unterminated Comment " + without_last(_comment) + "\n";
        _line = x-1;
        log << endl << temp;
        return temp;
    }

    /// unrecognized char error
    string unrecognized(const string& str)
    {
        ++_err;
        temp = empt_st + "Error at line no " + to_string(_line) + ": Unrecognized character " + str + "\n";
        log << endl << temp;
        return temp;
    }

    /// Default log output format
    void usual_log(const string& lexeme, const string& tok)
    {
        log << endl << "Line no " << _line << ": Token <" << tok << "> Lexeme " << lexeme << " found" << endl;
    }


    /// The destructor reports _line and _err before closing the file streams.
    ~lex_util()
    {
        log << endl;
        // table.print_active_tables(log);
        log << endl << "Total lines: " << _line;
        log << endl << "Total errors: " << _err;
        log.close();
        token.close();
    }

};
