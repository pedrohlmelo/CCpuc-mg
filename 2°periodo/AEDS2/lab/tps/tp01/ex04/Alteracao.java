import java.util.Scanner;
import java.util.Random;

public class Alteracao {

    public static void altera(String palavra, char l1, char l2) { //Método que altera de acordo com o random
        String npalavra = "";

        for (int i = 0; i < palavra.length(); i++) {
            char c = palavra.charAt(i);
            if (c == l1) { //Verificacao para a troca
                npalavra += l2;
            } else {
                npalavra += c;
            }
        }

        System.out.println(npalavra);
    }

    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        Random gerador = new Random();
        gerador.setSeed(4);

        String texto = sc.nextLine();
        while (!texto.equals("FIM")) {
            char letra1 = ((char)('a' + (Math.abs(gerador.nextInt()) % 26)));
      		char letra2 = ((char)('a' + (Math.abs(gerador.nextInt()) % 26)));

            altera(texto, letra1, letra2);
            texto = sc.nextLine();
        }

        sc.close();
    }
}
