//
// Created by fahim_hakim_15 on 04/07/2021.
//

#include <bits/stdc++.h>
using namespace std;

bool is_register(const string &x) {
    return (x == "AX") || (x == "BX") || (x == "CX") || (x == "DX");
}

bool is_alu_op(const string &x) {
    return (x == "AND") || (x == "OR") || (x == "XOR") || (x == "ADD") || (x == "SUB");
}

bool is_number(const std::string& s)
{
    if(s.empty())
        return false;
    for(auto x : s) {
        if(!isdigit(x))
            return false;
    }
    return true;
}

class optimizer {
    string outFileName = "optimized_code.asm";
    string input;
    vector<vector<string>>tokens;

public:
    void printToFile() {
        ofstream os(outFileName);
        for(auto token:tokens) {
            switch(token.size()) {
                case 1:
                    os << token[0];
                    break;
                case 2:
                    os << token[0] << " " << token[1];
                    break;
                case 3:
                    os << token[0] << " " << token[1];
                    //cout << "usual " << token[1] << endl;
                    if(token[1] != "DW" && token[1] != "EQU") {
                        os << ",";
                        //cout << token[1] << endl;
                    }
                    os << " " << token[2];
                    break;
                case 4:
                    os << token[0] << " " << token[1] << " " << token[2] << " " << token[3];
                    break;
                case 5:
                    os << token[0] << " " << token[1] << " " << token[2] << " " << token[3];
                    os << " " << token[4];
                    break;
                case 6:
                    os << token[0] << " " << token[1] << " " << token[2] << " " << token[3];
                    os << " " << token[4] << " " << token[5];
                    break;

            }
            os << endl;
        }
        os.close();
    }

    optimizer(string inFileName) {
        ifstream t(inFileName);
        input = string((istreambuf_iterator<char>(t)),
                        istreambuf_iterator<char>());
        input = regex_replace(input, regex(";.*\n*"), "\n");
        input = regex_replace(input, regex("(\n[ \t]*)+"), "\n");
        //cout << input << endl;
        istringstream inputs(input);
        string x;
        while(getline(inputs, x, '\n')) {
            vector<string> y;
            char* tok = strtok((char *)x.c_str(), ", \t");
            do{
                y.emplace_back(tok);
            } while ((tok = strtok(nullptr, ", \t:\n")));
            tokens.push_back(y);
        }
        /*for(auto z : tokens) {
            for (auto zz : z) {
                cout << zz << " ttt ";
            }
            cout << "\nNL\n";
        }*/

        for(int i=0, j; i<tokens.size()-1; ++i){
            j = i+1;
            while(tokens[j].empty() && j<tokens.size())
                ++j;
            if(tokens[j].size() == 1)
                continue;
            if(tokens[i][0] == "MOV" && tokens[j][0] == "MOV") {
                //cout << tokens[i][1] << to;
                if(tokens[i][1] == tokens[j][2] && tokens[i][2] == tokens[j][1]) {
                    /*
                     * MOV AX, BX
                     * MOV BX, AX
                     *
                     * --->
                     * MOV AX, BX
                     *
                     * the second instruction is redundant
                     */
                    tokens[j].clear();
                }
            }
            if((tokens[i][0] == "MOV" || is_alu_op(tokens[i][0])) && tokens[j][0] == "MOV"){
                // a MOV or ALU operation immediately followed by a MOV
                if(tokens[i][1] == tokens[j][1]) {
                    /*
                     * MOV S, P || ADD S, P || SUB S, P || ...
                     * MOV S, Q
                     *
                     * -->
                     * MOV S, Q
                     *
                     * the result of the first operation never used
                     */
                    tokens[i].clear();
                }
            }
            if((tokens[j][0] == "MOV" || is_alu_op(tokens[j][0])) && tokens[i][0] == "MOV"){
                // a MOV or ALU operation immediately preceded by a MOV
                if(!is_register(tokens[j][2]) && tokens[i][1] == tokens[j][2]) {
                    if(is_register(tokens[i][2])) {
                        /*
                         * MOV P, AX
                         * MOV DX, P || ADD DX, P || ...
                         *
                         * -->
                         * MOV P, AX
                         * MOV DX, AX || ADD DX, AX || ...
                         *
                         * REG-TO-REG OPERATIONS ARE FASTER
                         */
                        tokens[j][2] = tokens[i][2];
                    }
                    else if(is_number(tokens[i][2]) && is_register(tokens[j][1])) {
                        /*
                         * MOV P, 15
                         * ADD DX, P
                         *
                         * -->
                         * MOV P, 15
                         * ADD DX, 15
                         *
                         * IMMEDIATES ARE FASTER TO WORK WITH THEN MEMORIES
                         * BUT ONE OPERAND HAS TO BE A REGISTER ANYWAY
                         */
                        tokens[j][2] = tokens[i][2];
                    }
                }
            }
            if(tokens[i][0] == "PUSH" && tokens[j][0] == "POP") {
                if(tokens[i][1] == tokens[j][1]){
                    /*
                     * PUSH CX
                     * POP CX
                     *
                     * -->
                     *
                     * NO NEED TO PUSH AND POP THE SAME THING
                     */
                    tokens[i].clear();
                    tokens[j].clear();
                }
                else {
                    if(is_register(tokens[i][1]) || is_register(tokens[j][1])) {
                        /*
                         * PUSH CX
                         * POP P
                         *
                         * -->
                         * MOV P, CX
                         *
                         * MOV IS MUCH CHEAPER THAN A PUSH AND A POP
                         */
                         tokens[j][0] = "MOV";
                         tokens[j].emplace_back(tokens[i][1]);
                         tokens[i].clear();
                    }
                    else {
                        /*
                         * PUSH Q
                         * POP P
                         *
                         * -->
                         * MOV AX, Q
                         * MOV P, AX
                         *
                         * MOV IS MUCH CHEAPER THAN A PUSH AND A POP
                         */
                        tokens[i][0] = "MOV";
                        tokens[i].emplace_back(tokens[i][1]);
                        tokens[i][1] = "AX";
                        tokens[j][0] = "MOV";
                        tokens[j].emplace_back("AX");
                        tokens[i].clear();
                    }
                }
            }
            if(tokens[i][0] == "ADD" && tokens[i][1] == tokens[i][2]) {
                if(tokens[i][1] == tokens[i][2]) {
                    /*
                     * ADD BX, BX
                     *
                     * -->
                     * SAL BX, 1
                     *
                     * SHIFT OPERATIONS ARE FASTER
                     */
                    tokens[i][0] = "SAL";
                    tokens[i][2] = "1";
                }
                else if(tokens[i][2] == "1") {
                    /*
                     * ADD P, 1
                     *
                     * -->
                     * INC P
                     */
                    tokens[i][0] = "INC";
                    tokens[i].pop_back();
                }
                else if(tokens[i][2] == "-1") {
                    /*
                     * ADD P, -1
                     *
                     * -->
                     * DEC P
                     */
                    tokens[i][0] = "DEC";
                    tokens[i].pop_back();
                }
                else if(tokens[i][2] == "0") {
                    /*
                     * ADD P, 0
                     *
                     * -->
                     *
                     * DOESN'T MATTER
                     */
                    tokens[i].clear();
                }
            }
            if(tokens[i][0] == "SUB" && tokens[i][1] == tokens[i][2]) {
                if(tokens[i][2] == "-1") {
                    /*
                     * ADD P, 1
                     *
                     * -->
                     * INC P
                     */
                    tokens[i][0] = "INC";
                    tokens[i].pop_back();
                }
                else if(tokens[i][2] == "1") {
                    /*
                     * ADD P, -1
                     *
                     * -->
                     * DEC P
                     */
                    tokens[i][0] = "DEC";
                    tokens[i].pop_back();
                }
                else if(tokens[i][2] == "0") {
                    /*
                     * ADD P, 0
                     *
                     * -->
                     *
                     * DOESN'T MATTER
                     */
                    tokens[i].clear();
                }
            }

            //if(tokens[i][0] == "MOV" && tokens[j][0] == "MUL" && tokens[])
            if(tokens[i][1] == tokens[j][1]) {
                /*
                 * XXX lab YYY
                 * ZZZ lab AAA
                 */
                if(tokens[i][0] == "MOV" && tokens[j][0] == "MUL") {
                    if(tokens[i][2] == "0") {
                        /*
                         * MOV L, 0
                         * MUL L
                         *
                         * -->
                         * MOV L, 0
                         * XOR DX, DX
                         * XOR AX, AX
                         *
                         * MUL IS QUITE COSTLY
                         */
                        tokens[j].clear();
                        tokens[j].emplace_back("\tXOR AX, AX\n\tXOR DX, DX");
                    }
                    else if(tokens[i][2] == "1") {
                        /*
                         * MOV L, 1
                         * MUL L
                         *
                         * -->
                         * MOV L, 1
                         *
                         * MULTIPLYING BY 1 IS REDUNDANT
                         */
                        tokens[j].clear();
                    }
                }
            }
        }

        printToFile();
    }



};

int main() {
    optimizer d("opt1.asm");
}