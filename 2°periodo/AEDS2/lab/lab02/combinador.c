#include <stdio.h>
#include <string.h>

void combinador(char f1[], char f2[]) {
    char nova[401]; 
    int i = 0, j = 0, k = 0;

    
    while (f1[i] != '\0' && f2[j] != '\0') {
        nova[k++] = f1[i++];
        nova[k++] = f2[j++];
    }

    
    while (f1[i] != '\0') {
        nova[k++] = f1[i++];
    }

    while (f2[j] != '\0') {
        nova[k++] = f2[j++];
    }

    nova[k] = '\0';

    printf("%s\n", nova);
}

int main() {
    char frase1[200];
    char frase2[200];
   
         while (scanf(" %199s %199s", frase1, frase2) == 2) {
        combinador(frase1, frase2);
    }


    return 0;
}


