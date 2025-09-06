import java.util.Scanner;

public class palindromo {

    public static boolean verificaPalindromo(String letras) {//verifica palindromo
        String invertida = "";

        for (int i = letras.length() - 1; i >= 0; i--) {
            invertida += letras.charAt(i);//inverte string
        }

        return invertida.equals(letras);//retorna a string invertida
    }

    public static void main(String args[]) {
        Scanner sc = new Scanner(System.in);
        String texto = sc.nextLine();

        while (!texto.equals("FIM")) {

            if (verificaPalindromo(texto)) {
                System.out.println("SIM");
            } else {
                System.out.println("NAO");
            }

            texto = sc.nextLine();
        }

        sc.close(); 
    }
}

