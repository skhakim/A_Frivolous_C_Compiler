//
// Created by fahim_hakim_15 on 09/03/2021.
//

#ifndef TS_SYMBOL_TABLE_SCOPE_TABLE_H
#define TS_SYMBOL_TABLE_SCOPE_TABLE_H

#include <vector>
#include <ostream>
#include "symbol_info.h"

using namespace std;

class scope_table {

    int i_buckets;
    scope_table *parent;
    vector<symbol_info *> h_table;
    string id;
    static int i_scope;
    int child_scope;

public:
    explicit scope_table(int no_of_buckets) : i_buckets(no_of_buckets), child_scope(0) {
        ++i_scope;
        h_table = vector<symbol_info *>(no_of_buckets, nullptr);
        id = to_string(i_scope);
        parent = nullptr;
    }

    scope_table(int no_of_buckets, scope_table *parent_scope)
            : i_buckets(no_of_buckets), parent(parent_scope), child_scope(0) { /* new add */
        ++parent_scope->child_scope;
        h_table = vector<symbol_info *>(no_of_buckets, nullptr);
        id = parent_scope->id + "." + to_string(parent_scope->child_scope);
    }

    bool insert(symbol_info *s_info, string &message) {
        int i = s_info->get_ascii_sum_of_name() % i_buckets;
        int *pos = new int(0);
        if (h_table[i])
            h_table[i]->add(s_info, pos);
        else
            h_table[i] = s_info;
        if ((*pos) < 0) {
            message = s_info->getName() + " already exists in current ScopeTable";
            delete pos;
            return false;
        }
        message = "Inserted in scope_table #" + id + " at position: " + to_string(i) + ", ";
        message += to_string(*pos);
        delete pos;
        return true;
    }

    bool insert(const string &name, const string &type, string &message) {
        return insert(new symbol_info(name, type), message);
    }

    template<typename T>
    bool var_insert(const string &name, string &message) {
        return insert(new variable_info<T>(name), message);
    }

    template<typename T>
    bool arr_insert(const string &name, int size, string &message) {
        return insert(new arr_info<T>(name, size), message);
    }


    func_info* func_insert(const int &ret_type, const string &name, string &message) {
        func_info* temp = new func_info(ret_type, name);
        if(insert(temp, message))
            return temp;
        else
            return nullptr;
    }

    symbol_info *lookup(const string &name, string &message) {
        int i = get_ascii_sum(name) % i_buckets, *pos;
        pos = new int(0);
        if (h_table[i]) {
            symbol_info *temp = h_table[i]->lookup(name, pos);
            if (temp) {
                message = "Found in scope_table #" + id + " at position: " + to_string(i) + ", " + to_string(*pos);
                delete pos;
                return temp;
            }
        }
        message = "Not found in scope_table #" + id;
        delete pos;
        return nullptr;
    }

    bool remove(const string &name, string &message) {
        int i = get_ascii_sum(name) % i_buckets, *pos;
        pos = new int(0);
        if (h_table[i]) {
            message = "Deleted from scope_table #" + id + " at position: " + to_string(i) + ", ";
            if (h_table[i]->match_name(name)) {
                h_table[i] = h_table[i]->getNextInChain();
                message += "0";
                delete pos;
                return true;
            }
            ++(*pos);
            if (h_table[i]->getNextInChain()) {
                h_table[i]->getNextInChain()->remove(name, h_table[i], pos);
                if (*pos >= 0) {
                    message += to_string(*pos);
                    delete pos;
                    return true;
                }
            }
        }
        message = "Not found in (and hence could not be deleted from) scope_table #" + id;
        delete pos;
        return false;
    }

    // outstream
    friend ostream &operator<<(ostream &os, const scope_table &table) {
        os << "ScopeTable # " << table.id << endl;
        int j;
        for (j = 0; j < table.i_buckets; ++j) {
            if (table.h_table[j])
                os << " " << j << " -->" << table.h_table[j] << endl;
        }
        os << endl;
        return os;
    }

    //getters and setters and destructors
    [[nodiscard]] int getIBuckets() const {
        return i_buckets;
    }

    scope_table *getParent() const {
        return parent;
    }

    const vector<symbol_info *> &getHTable() const {
        return h_table;
    }

    const string &getId() const {
        return id;
    }

    int getIScope() {
        return i_scope;
    }

    void setIScope(int iScope) {
        i_scope = iScope;
    }

    ~scope_table() {
        if(parent)
            delete parent;
        for (auto &ptr : h_table)
            if (ptr)
                delete ptr;
        h_table.clear();
    }

};

int scope_table::i_scope = 0;


#endif //TS_SYMBOL_TABLE_SCOPE_TABLE_H

/*
 5
 i s1 int
 s
 i s1.1 int
 s
 i s1.1.1 int
 e
 s
 i s1.1.2 int
 e
 s
 p a


 */
