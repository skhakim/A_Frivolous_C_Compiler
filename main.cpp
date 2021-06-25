#include <iostream>
#include <string>

int main() {
    std::string x = "Hello, %d, world";

    printf(x.c_str(), 5);

    return 0;
}
