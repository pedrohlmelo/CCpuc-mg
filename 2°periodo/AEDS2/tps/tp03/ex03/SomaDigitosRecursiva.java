import java.util.Scanner;

public class SomaDigitosRecursiva {

    // Soma os dígitos recursivamente a partir do índice i
    public static int somaDigitos(String numero, int i) {
        if (i >= numero.length()) {
            return 0; // caso base, chegou ao fim da string
        }

        char c = numero.charAt(i);

        if (c >= '0' && c <= '9') {
            return (c - '0') + somaDigitos(numero, i + 1);
        }

        return somaDigitos(numero, i + 1); // ignora se não for dígito
    }

    // Processa cada linha recursivamente até ler "FIM"
    public static void processaEntrada(Scanner sc) {
        String linha = sc.nextLine();

        if (linha.equals("FIM")) {
            return; // caso base
        }

        int soma = somaDigitos(linha, 0);
        System.out.println(soma);

        processaEntrada(sc); // chamada recursiva
    }

    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        processaEntrada(sc);
        sc.close();
    }
}


