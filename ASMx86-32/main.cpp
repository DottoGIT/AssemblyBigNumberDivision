#include <string>
#include <cstring>
#include <iostream>

extern "C" char* sdiv(unsigned int base, char *d, char *s1, char* s2); 

int main(int argc, char* argv[])
{
    int base = std::stoi(argv[1]);
    char* s1 = argv[2];
    char* s2 = argv[3];

    // unsigned int base = 10;
    // char s1[] = "6431933210";
    // char s2[] = "323";

    size_t size = std::strlen(s1)+1;
    char* buffer = new char[size];
    
    sdiv(base, buffer, s1, s2);
    std::cout << "Iloraz: " << buffer << std::endl;
    std::cout << "Reszta: " << s1 << std::endl;    

    delete buffer;
    return 0;
}