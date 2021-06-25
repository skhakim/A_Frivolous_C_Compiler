//
// Created by fahim_hakim_15 on 10/03/2021.
//

#ifndef TS_SYMBOL_TABLE_SYMBOL_TABLE_H
#define TS_SYMBOL_TABLE_SYMBOL_TABLE_H

#include <deque>
#include <sstream>
#include <cstdio>
#include "scope_table.h"

using namespace std;

class symbol_table {
    deque<scope_table *> scopes;
    scope_table *cur_scope;
    int def_buckets;

public:
    symbol_table(int buckets) : def_buckets(buckets) {
        scopes.push_front(new scope_table(def_buckets));
        cur_scope = scopes.front();
    }

    string enter_scope() {
        scopes.push_front(new scope_table(def_buckets, cur_scope));
        cur_scope = scopes.front();
        return "New scope_table with id = " + cur_scope->getId() + " created.\n";
    }

    string exit_scope() {
        string message = "Exited from scope_table with id = " + cur_scope->getId() + '\n';
        cur_scope = cur_scope->getParent();
        return message;
    }

    bool insert(const string& name, const string& type, string& message) {
        cout << "Hello from insert in sym_tab\n";
        printf("%p\n", cur_scope);
        return cur_scope->insert(name, type, message);
    }

    template<typename T>
    bool var_insert(const string& name, string& message) {

        //printf(" Var insery %p\n", cur_scope);
        return cur_scope->var_insert<T>(name, message);
    }

    template<typename T>
    bool arr_insert(const string& name, const int &size, string& message) {
        return cur_scope->arr_insert<T>(name, size, message);
    }

    func_info* func_insert(const int& ret_type, const string& name, string& message) {
        return cur_scope->func_insert(ret_type, name, message);
    }

    bool remove(string name, string& message) {
        return cur_scope->remove(name, message);
    }

    symbol_info *lookup(string name, string& message) {
        string str;
        message = "";
        auto temp_scope = cur_scope;
        while (temp_scope) {
            symbol_info* temp = temp_scope->lookup(name, str);
            if (temp) {
                message = str;
                return temp;
            }
            temp_scope = temp_scope->getParent();
        }
        message = "Not found in any scope table in the hierarchy.";
        return nullptr;
    }

    void print_current_table(FILE *fp) {
        ostringstream temp;
        print_current_table(temp);
        fprintf(fp, "%s", temp.str().c_str());
    }

    void print_all_tables(FILE *fp) {
        ostringstream temp;
        print_all_tables(temp);
        fprintf(fp, "%s", temp.str().c_str());
    }

    void print_active_tables(FILE *fp) {
        ostringstream temp;
        print_active_tables(temp);
        fprintf(fp, "%s", temp.str().c_str());
    }

    void print_current_table(ostream &os) {
        os << *cur_scope;
    }

    void print_all_tables(ostream &os) {
        for (scope_table *scope:scopes) {
            os << *scope;
            os << endl;
        }
    }

    void print_active_tables(ostream &os){
        auto temp = cur_scope;
        while(temp){
            os << *temp;
            temp = temp->getParent();
        }
        //os << endl;
    }

    string declaration() {
        string temp;
        for (scope_table *scope:scopes) {
            temp += scope->declaration();
        }
        return temp;
    }

    int get_no_buckets() const {
        return def_buckets;
    }

    ~symbol_table() {
        scopes.clear();
        if(cur_scope)
            delete cur_scope;
    }

};

#endif //TS_SYMBOL_TABLE_SYMBOL_TABLE_H
