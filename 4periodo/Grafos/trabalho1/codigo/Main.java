import java.io.PrintWriter;
import java.util.List;
import java.util.Scanner;

public class Main {
    static final int LIMITE_IMPRESSAO = 200;

    public static void main(String[] args) throws Exception {
        String nomeArquivo;
        if (args.length > 0) {
            nomeArquivo = args[0];
        } else {
            Scanner teclado = new Scanner(System.in);
            System.out.println("Nome do arquivo do grafo:");
            nomeArquivo = teclado.nextLine().trim();
        }

        Grafo g = Grafo.ler(nomeArquivo);
        System.out.println("Grafo com " + g.n + " vertices e " + g.m + " arestas");

        Pontes pontes = new Pontes(g);

        long t0 = System.nanoTime();
        List<Integer> pontesNaive = pontes.naive();
        long t1 = System.nanoTime();
        List<Integer> pontesTarjan = pontes.tarjan();
        long t2 = System.nanoTime();

        System.out.println();
        System.out.printf("Pontes (naive):  %d encontradas em %.3f ms%n", pontesNaive.size(), (t1 - t0) / 1e6);
        System.out.printf("Pontes (Tarjan): %d encontradas em %.3f ms%n", pontesTarjan.size(), (t2 - t1) / 1e6);
        if (pontesTarjan.size() <= LIMITE_IMPRESSAO) {
            for (int e : pontesTarjan) {
                System.out.println("  (" + g.origem[e] + ", " + g.destino[e] + ")");
            }
        }
        if (!new java.util.HashSet<>(pontesNaive).equals(new java.util.HashSet<>(pontesTarjan))) {
            System.out.println("ATENCAO: os dois metodos encontraram conjuntos de pontes diferentes!");
        }

        int classe = Fleury.classificar(g);
        System.out.println();
        System.out.println("Classificacao: " + Fleury.NOME_CLASSE[classe]);
        if (classe == Fleury.NAO_EULERIANO) {
            System.out.println("Nao existe caminho euleriano neste grafo.");
            return;
        }

        for (int metodo = Fleury.NAIVE; metodo <= Fleury.TARJAN; metodo++) {
            long a = System.nanoTime();
            int[] caminho = Fleury.caminho(g, metodo, Long.MAX_VALUE);
            long b = System.nanoTime();
            System.out.println();
            System.out.printf("Fleury + %s: %.3f ms, caminho %s%n", Fleury.NOME_METODO[metodo], (b - a) / 1e6,
                    Fleury.valido(g, caminho) ? "valido" : "INVALIDO");
            if (caminho.length <= LIMITE_IMPRESSAO) {
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < caminho.length; i++) {
                    sb.append(caminho[i]);
                    if (i + 1 < caminho.length) {
                        sb.append(" -> ");
                    }
                }
                System.out.println(sb);
            } else {
                String saida = "caminho-" + Fleury.NOME_METODO[metodo] + ".txt";
                PrintWriter pw = new PrintWriter(saida);
                for (int v : caminho) {
                    pw.println(v);
                }
                pw.close();
                System.out.println("Caminho com " + caminho.length + " vertices salvo em " + saida);
            }
        }
    }
}
