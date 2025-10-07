import java.util.Scanner;

public class Espelho {
    
    
    public static String inverterNumero(int n) {
        if (n == 0) return "0";

        String resultado = "";
        while (n > 0) {
            int digito = n % 10;
            resultado += (char)(digito + '0');
            n /= 10;
        }
        return resultado;
    }

    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        while (sc.hasNextInt()) {
            int inicio = sc.nextInt();
            int fim = sc.nextInt();

            String crescente = "";
            String espelhada = "";

            
            for (int i = inicio; i <= fim; i++) {
                
                int num = i;
                if (num == 0) {
                    crescente += "0";
                } else {
                    String numero = "";
                    int[] digitos = new int[10]; 
                    int count = 0;
                    while (num > 0) {
                        digitos[count++] = num % 10;
                        num /= 10;
                    }
                    for (int j = count - 1; j >= 0; j--) {
                        crescente += (char)(digitos[j] + '0');
                    }
                }
            }

           
            for (int i = fim; i >= inicio; i--) {
                espelhada += inverterNumero(i);
            }

            System.out.println(crescente + espelhada);
        }

        sc.close();
    }
}


