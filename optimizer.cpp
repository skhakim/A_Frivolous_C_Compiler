//
// Created by fahim_hakim_15 on 04/07/2021.
//

#include <bits/stdc++.h>
using namespace std;

bool is_register(const string &x) {
    return (x == "AX") || (x == "BX") || (x == "CX") || (x == "DX");
}

class optimizer {
    string outFileName = "optimized_code.asm";
    string input;
    vector<vector<string>>tokens;

public:
    optimizer(string inFileName) {
        ifstream t(inFileName);
        input = string((istreambuf_iterator<char>(t)),
                        istreambuf_iterator<char>());
        input = regex_replace(input, regex(";.*\n*"), "\n");
        input = regex_replace(input, regex("(\n[ \t]*)+"), "\n");
        cout << input << endl;
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

        for(int i=0; i<tokens.size()-1; ++i){
            if(tokens[i][0] == "MOV" && tokens[i+1][0] == "MOV") {
                //cout << tokens[i][1] << to;
                if(tokens[i][1] == tokens[i+1][2]) {
                    //tokens[i].clear();
                    if (tokens[i][2] == tokens[i + 1][1]) {
                        tokens[++i].clear();
                    }
                    else if(is_register(tokens[i][2]) || is_register(tokens[i + 1][1])){
                        tokens[i+1][2] = tokens[i][2];
                        tokens[i].clear();
                    }
                }
            }
            if(tokens[i][0] == "PUSH" && tokens[i+1][0] == "POP") {
                if(tokens[i][1] == tokens[i+1][1]){
                    tokens[i].clear();
                    tokens[++i].clear();
                }
            }
            if(tokens[i][0] == "ADD" && tokens[i][1] == tokens[i][2]) {
                tokens[i][0] = "SAL";
                tokens[i][2] = "1";
            }
        }


        for(auto z : tokens) {
            for (auto zz : z) {
                cout << zz << "  ";
            }
            cout << "\n\n";
        }
    }

};

int main() {
    optimizer d("check.asm");
}