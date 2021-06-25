//
// Created by fahim_hakim_15 on 09/03/2021.
//

#ifndef TS_SYMBOL_TABLE_SYMBOL_INFO_H
#define TS_SYMBOL_TABLE_SYMBOL_INFO_H

#include <string>
#include <ostream>
#include <vector>
#include <queue>
#include <map>
#include <cxxabi.h>
#include "my_dtype.h"

using namespace std;

int __func_OFFSET = static_cast<int>(_FUNC_OFFSET);
int __arr_OFFSET = static_cast<int>(_ARR_OFFSET);

int get_ascii_sum(const string &str) {
    int i = 0;
    for (auto &c:str) {
        i += c;
    }
    return i;
}

class symbol_info {
private:
    string name, info;
    symbol_info *next_in_chain;

    string code;
protected:
    symbol_info(const string &name) : name(name) {
        next_in_chain = nullptr;
    }


public:
    void set_code(const string& code) {
        this->code = code;
    }

    string get_code() {
        return code;
    }

    symbol_info(const string &name, const string &info) : name(name), info(info) {
        next_in_chain = nullptr;
    }

    int get_ascii_sum_of_name() {
        return get_ascii_sum(name);
    }

    //chain to this symbol_info
    bool add(symbol_info *s_info, int *pos) {
        //multiplicities are not allowed
        if (name == s_info->get_name()) {
            *pos = -1;
            return false;
        }
        //pos counter incremented
        ++(*pos);
        //if there exists s_info objects after this one, call from there
        if (next_in_chain) {
            return next_in_chain->add(s_info, pos);
        }
        //this is the last object in the chain
        //so add after this
        next_in_chain = s_info;
        return true;
    }

    //lookup
    symbol_info *lookup(const string &key_name, int *pos) {
        if (name == key_name)
            return this;
        ++(*pos);
        if (next_in_chain)
            return next_in_chain->lookup(key_name, pos);
        return nullptr;
    }

    //remove
    bool remove(const string &key_name, symbol_info *prev_in_chain, int *pos) {
        if (name == key_name) {
            prev_in_chain->next_in_chain = next_in_chain;
            return true;
        }
        ++(*pos);
        if (next_in_chain)
            return next_in_chain->remove(key_name, this, pos);
        *pos = -1;
        return false;
    }


    bool match_name(const string &key_name) {
        return name == key_name;
    }

    //check
    friend ostream &operator<<(ostream &os, const symbol_info *s_info) {
        os << " < " << s_info->name << " , " << s_info->info << " , " << s_info->code << " >";
        if (s_info->next_in_chain)
            os << s_info->next_in_chain;
        return os;
    }

    virtual string declaration () {
        return code + " DW 0\r\n";
    }


    void print_as_token(ostream &os) {
        os << "<" << info << ", " << name << ">";
    }

    // Getters, setters and destructor
    const string &get_name() const {
        return name;
    }

    void setName(const string &name) {
        this->name = string(name);
    }

    const string &getInfo() const {
        return info;
    }

    void setInfo(const string &info) {
        this->info = string(info);
    }

    symbol_info *getNextInChain() const {
        return next_in_chain;
    }

    void setNextInChain(symbol_info *nextInChain) {
        next_in_chain = nextInChain;
    }

    ~symbol_info() {
        name.clear();
        info.clear();
        if (next_in_chain)
            delete next_in_chain;
    }

    template<typename T>
    bool is_identical(const symbol_info &s_info) {
        return info == s_info.info && typeid(*this) == typeid(s_info);
    }

    virtual string type_id() {
        // cout << "type_id in class symbol_info should never be called.\n";
        return "INVALID";
    }

    virtual string type() {
        return "INVALID TYPE";
    }

    virtual int dtype() {
        return _ERRONEOUS; // should never be called
    }

};

template<typename T>
class variable_info : public symbol_info {
private:
    // string _dtype;
    T value;
public:
    int _dtype;

    variable_info(const string &name) : symbol_info(name, "ID") {
        //setInfo(abi::__cxa_demangle(((string)typeid(T).name()).c_str(), nullptr, nullptr, nullptr));
        string s = abi::__cxa_demangle(((string) typeid(T).name()).c_str(), nullptr, nullptr, nullptr);
        if (s == "int")
            _dtype = _INT;
        else if (s == "float")
            _dtype = _FLOAT;
        else if (s == "bool")
            _dtype = _BOOLEAN;
        else
            _dtype = _UNKNOWN;
    }

    T operator()() const {
        return value;
    }

    T operator+(const T &rhs) {
        return value + rhs;
    }

    T operator+(const variable_info<T> &rhs) {
        return value + rhs.value;
    }

    T operator-(const T &rhs) {
        return value - rhs;
    }

    T operator-(const variable_info<T> &rhs) {
        return value - rhs.value;
    }

    T operator*(const T &rhs) {
        return value * rhs;
    }

    T operator*(const variable_info<T> &rhs) {
        return value * rhs.value;
    }

    T operator/(const T &rhs) {
        assert(rhs != 0);
        return value / rhs;
    }

    T operator/(const variable_info<T> &rhs) {
        assert(rhs.value != 0);
        return value / rhs.value;
    }

    bool operator<(const variable_info<T> &rhs) const {
        return value < rhs.value;
    }

    bool operator>(const variable_info<T> &rhs) const {
        return rhs < *this;
    }

    bool operator<=(const variable_info<T> &rhs) const {
        return !(rhs < *this);
    }

    bool operator>=(const variable_info<T> &rhs) const {
        return !(*this < rhs);
    }

    bool operator<(const T &rhs) const {
        return value < rhs.value;
    }

    bool operator>(const T &rhs) const {
        return rhs < value;
    }

    bool operator<=(const T &rhs) const {
        return !(rhs < value);
    }

    bool operator>=(const T &rhs) const {
        return !(value < rhs);
    }

    string type_id() override {
        return string(typeid(value).name());
    }

    string type() override {
        return abi::__cxa_demangle(((string) typeid(T).name()).c_str(), nullptr, nullptr, nullptr);
    }

    int dtype() override {
        return _dtype;
    }
};

template<typename T>
class arr_info : public symbol_info {
private:
    T *arr;
    int size;
public:
    int _dtype;
    arr_info(const string &name, const int &size) : symbol_info(name, "ID"), size(size) {
        //setInfo(abi::__cxa_demangle(((string)typeid(T).name()).c_str(), nullptr, nullptr, nullptr));
        //arr = new T[size];
        string s = abi::__cxa_demangle(((string) typeid(T).name()).c_str(), nullptr, nullptr, nullptr);
        if (s == "int")
            _dtype = _INT;
        else if (s == "float")
            _dtype = _FLOAT;
        else if (s == "bool")
            _dtype = _BOOLEAN;
        else
            _dtype = _UNKNOWN;
    }

    T operator[](int x) {
        return arr[x];
    }

    string type_id() override {
        return string(typeid(arr).name());
    }

    string type() override {
        return abi::__cxa_demangle(((string) typeid(T *).name()).c_str(), nullptr, nullptr, nullptr);
    }

    bool valid_index(int x) {
        return (x < size) && (x >= 0);
    }

    int dtype() {
        return _dtype+__arr_OFFSET;
    }

    string declaration() {
        return get_code() + " DW " + to_string(size) + " (0)\r\n";
    }
};


struct func_info : public symbol_info {
    int ret_type, i = 0;
    map<string /* name */, int> parameters;  // map[name] = type
    //queue<int /* type */> *temp_types, *temp; // temporary queue to keep types
    vector<int> temp_vec;
    bool is_defined;
public:
    func_info(const int &ret_type, const string &name) : symbol_info(name, "ID") {
        //temp_types = new queue<int>;
        this->ret_type = ret_type;
    }

    ~func_info() {
        //delete temp_types;
        //delete temp;
        parameters.clear();
        temp_vec.clear();
    }

    int size() {
        return temp_vec.size();
    }

    void reset_count() { i = 0; }

    void print_basics() {

        cout << "In function " << get_name() << " size " << temp_vec.size() << " "  << parameters.size() << " " << endl;
        for(auto& p : parameters){
            cout << p.first << " " << p.second << endl;
        }
        cout << is_defined << endl << endl;
    }

    void mark_defined() {
        //delete temp_types;
        is_defined = true;
    }

    string declaration() {
        return "";
    }
    /*template<typename T1>
    void add_variable(const string &name) {
        parameters.emplace_back(typeid(T1).name(), name);
    }*/

    bool add_variable(const int &type_int, const string &name) {
        //temp_types->push(type_int);
        temp_vec.push_back(type_int);
        // if(name.size())
        return name.empty() || parameters.emplace(name, type_int).second;
    }
    /*
     * plan of action 1: rewrite the function
     */
    bool match_and_add_variable(const int &type_int, const string &name) {
        if(name.empty() || temp_vec.empty())
            return false;
        // cout << name << " ; temp_types " << temp_types << endl;
        /*if(!temp){
            temp = new queue<int>;
        }
        if (!temp_types || temp_types->empty() || name.empty())
            return false;*/
        int ref = temp_vec[i]; // temp_types->front();
        i++; // temp_types->pop();
        //assert(temp != nullptr);
        //printf("%p %p  ... ", temp, temp_types);
        //cout << "In match and add :3 : " << get_name() << " " << ret_type << " " << __LINE__ << endl;
        //printf("%p %p  ... ", temp, temp_types);
        //temp->push(ref);
        //cout << __LINE__ << endl;
        //if(temp_types->empty())
        //    temp_types = temp;
        if (ref == type_int){
            parameters.emplace(name, type_int);
            return true;
        }
        return false;
    }

    int of_similar_type(queue<int> *args) {
        /*cout << "In " << get_name() << " : ";
        printf("Size of this and given: %d %d\n", temp_types->size(), args->size());*/
        if(temp_vec.size() != args->size())
            return _SIZE_MISMATCH;
        for(int j=0, arg; j<temp_vec.size(); ++j){
            arg = args->front();
            args->pop();
            if(temp_vec[j] < arg){
                return j+1+_TYPE_MISMATCH;
            }
        }
        return _MATCH;
    }

    /*auto add_var_iter(const string& type, const string& name) {
        return parameters.emplace(name, type).first;
    }*/

    /*template<typename T1>
    void add__array(const string &name, const int &size) {
        parameters.emplace_back(typeid(T1*).name(), name);
    }*/



    bool operator==(func_info &rhs) {
        if (ret_type == rhs.ret_type && parameters.size() == rhs.parameters.size()) {
            for (auto it1 = parameters.begin(), it2 = rhs.parameters.begin();
                 it1 != parameters.end(); ++it1, ++it2) {
                if (it1->first != it2->first)
                    return false;
            }
            return true;
        }
        return false;
    }

    int dtype() override {
        return ret_type + _FUNC_OFFSET;
    }
};


#endif //TS_SYMBOL_TABLE_SYMBOL_INFO_H

