import java.io.PrintWriter;
import java.util.Random;
import java.util.Scanner;

public class Gerador {

    public static void main(String[] args) throws Exception {
        Scanner teclado = new Scanner(System.in);

        System.out.println("Tipo (1 = aleatorio, 2 = grade):");
        int tipo = teclado.nextInt();
        System.out.println("Numero de vertices (na grade, o lado k):");
        int tamanho = teclado.nextInt();
        System.out.println("Semente:");
        long semente = teclado.nextLong();
        System.out.println("Nome do arquivo de saida:");
        String nomeArquivo = teclado.next();

        Random sorteio = new Random(semente);
        PrintWriter saida = new PrintWriter(nomeArquivo);

        if (tipo == 1) {
            int n = tamanho;
            int m = 5 * n;
            saida.println(n + " " + m);
            for (int v = 1; v <= n; v++) {
                int w = v % n + 1;
                saida.println(v + " " + w + " " + (sorteio.nextInt(10) + 1));
            }
            for (int i = n; i < m; i++) {
                int v = sorteio.nextInt(n) + 1;
                int w = sorteio.nextInt(n) + 1;
                saida.println(v + " " + w + " " + (sorteio.nextInt(10) + 1));
            }
            System.out.println("Gerado grafo aleatorio com " + n + " vertices e " + m + " arestas");
        } else {
            int k = tamanho;
            int n = k * k;
            int m = 4 * k * (k - 1);
            saida.println(n + " " + m);
            for (int linha = 0; linha < k; linha++) {
                for (int coluna = 0; coluna < k; coluna++) {
                    int v = linha * k + coluna + 1;
                    if (coluna + 1 < k) {
                        saida.println(v + " " + (v + 1) + " " + (sorteio.nextInt(5) + 1));
                    }
                    if (coluna > 0) {
                        saida.println(v + " " + (v - 1) + " " + (sorteio.nextInt(5) + 1));
                    }
                    if (linha + 1 < k) {
                        saida.println(v + " " + (v + k) + " " + (sorteio.nextInt(5) + 1));
                    }
                    if (linha > 0) {
                        saida.println(v + " " + (v - k) + " " + (sorteio.nextInt(5) + 1));
                    }
                }
            }
            System.out.println("Gerado grafo em grade com " + n + " vertices e " + m + " arestas");
        }
        saida.close();
    }
} 
