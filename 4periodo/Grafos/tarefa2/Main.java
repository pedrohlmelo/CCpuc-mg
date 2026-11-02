import java.io.*;
import java.util.*;

public class Main {

    static List<Integer>[] sucessores;
    static int[] TD, TT, pai, prox, pilha;
    static int t = 0;
    static int vertice;
    static String classificacao = "";

    public static void main(String[] args) throws FileNotFoundException {
        Scanner sc = new Scanner(System.in);

        System.out.println("Digite o nome do arquivo");
        String arquivo = sc.next();

        System.out.println("Digite o numero do vertice");
        vertice = sc.nextInt();

        File arq = new File(arquivo);
        Scanner scf = new Scanner(arq);

        int n = scf.nextInt();
        int m = scf.nextInt();

        sucessores = new ArrayList[n + 1];
        for (int i = 0; i <= n; i++) {
            sucessores[i] = new ArrayList<>();
        }

        while (scf.hasNextInt()) {
            int origem = scf.nextInt();
            if (!scf.hasNextInt()) break;
            int destino = scf.nextInt();
            sucessores[origem].add(destino);
        }
        scf.close();

        if (vertice < 1 || vertice > n) {
            System.out.println("Vertice " + vertice + " nao existe no grafo (faixa valida: 1 a " + n + ").");
            sc.close();
            return;
        }

        for (int i = 1; i <= n; i++) {
            Collections.sort(sucessores[i]);
        }

        TD = new int[n + 1];
        TT = new int[n + 1];
        pai = new int[n + 1];
        prox = new int[n + 1];   
        pilha = new int[n + 1];

        System.out.println();
        System.out.println("Arestas de arvore:");
        for (int v = 1; v <= n; v++) {
            if (TD[v] == 0) {
                busca(v);
            }
        }

        System.out.println();
        System.out.println("Arestas que saem do vertice " + vertice + ":");
        System.out.print(classificacao);

        sc.close();
    }

    static void busca(int raiz) {
        int topo = 0;
        pilha[topo] = raiz;
        t++;
        TD[raiz] = t;

        while (topo >= 0) {
            int v = pilha[topo];

            if (prox[v] < sucessores[v].size()) {
                int w = sucessores[v].get(prox[v]);
                prox[v]++;

                String tipo;
                if (TD[w] == 0) {
                    tipo = "arvore";
                    pai[w] = v;
                    System.out.println("(" + v + ", " + w + ")");
                    t++;
                    TD[w] = t;
                    topo++;
                    pilha[topo] = w;
                } else if (TT[w] == 0) {
                    tipo = "retorno";
                } else if (TD[v] < TD[w]) {
                    tipo = "avanco";
                } else {
                    tipo = "cruzamento";
                }

                if (v == vertice) {
                    classificacao += "(" + v + ", " + w + ") - " + tipo + "\n";
                }
            } else {
                t++;
                TT[v] = t;
                topo--;
            }
        }
    }
}