#include <stdio.h>
#include <stdlib.h>

int main()
{
    char *letras = (char*)malloc(26*sizeof(char));
    int letra = 'A';

    for(int i=0; i<26; i++)
    {
        *(letras+i)=letra;
        letra++;
        printf("%c ",*(letras+i));
    }
    return 0;
}
