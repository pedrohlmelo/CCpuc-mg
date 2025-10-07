import java.util.Scanner;

public class InversaoRecursiva{

    // Função auxiliar recursiva para imprimir a string invertida
    public static void inverteRecursiva(String texto, int index) {
        if (index < 0) return; // caso base

        System.out.print(texto.charAt(index));
        inverteRecursiva(texto, index - 1); // chamada recursiva
    }

    // Método principal que chama a recursiva
    public static void inverte(String texto) {
        inverteRecursiva(texto, texto.length() - 1);
        System.out.println(); // pular linha após imprimir invertido
    }

    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        String palavra = sc.nextLine();

        while (!palavra.equals("FIM")) {
            inverte(palavra); // chamada recursiva
            palavra = sc.nextLine();
        }

        sc.close();
    }
}

