#include <stdio.h>
#include <string.h>
#include <stdbool.h>

bool verificaPalindromo(char frase[], int inicio, int fim) {
    if (inicio >= fim) return true;
    if (frase[inicio] != frase[fim]) return false;
    return verificaPalindromo(frase, inicio + 1, fim - 1);
}

int main() {
    char texto[300];

    
    while (fgets(texto, sizeof(texto), stdin)) {
        
        size_t len = strlen(texto);
        if (len > 0 && texto[len - 1] == '\n') {
            texto[len - 1] = '\0';
        }

        
        if (strcmp(texto, "FIM") == 0) {
            break;
        }

        int tam = strlen(texto);

        if (verificaPalindromo(texto, 0, tam - 1)) {
            printf("SIM\n");
        } else {
            printf("NAO\n");
        }
    }

    return 0;
}


