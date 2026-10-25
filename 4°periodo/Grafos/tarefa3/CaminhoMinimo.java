import java.io.File;
import java.util.PriorityQueue;
import java.util.Scanner;

public class CaminhoMinimo {

    static final long INFINITO = Long.MAX_VALUE;

    public static void main(String[] args) throws Exception {
        Scanner teclado = new Scanner(System.in);

        System.out.println("Nome do arquivo do grafo:");
        String nomeArquivo = teclado.nextLine().trim();
        System.out.println("Vertice de origem:");
        int s = teclado.nextInt();
        System.out.println("Vertice de destino:");
        int t = teclado.nextInt();

        Scanner leitor = new Scanner(new File(nomeArquivo));
        int n = leitor.nextInt();
        int m = leitor.nextInt();

        int[] orig = new int[m];
        int[] dest = new int[m];
        int[] pes = new int[m];
        for (int i = 0; i < m; i++) {
            orig[i] = leitor.nextInt();
            dest[i] = leitor.nextInt();
            pes[i] = leitor.nextInt();
        }
        leitor.close();

        int[] inicio = new int[n + 2];
        for (int i = 0; i < m; i++) {
            inicio[orig[i] + 1]++;
        }
        for (int v = 1; v <= n; v++) {
            inicio[v + 1] = inicio[v + 1] + inicio[v];
        }

        int[] proxima = new int[n + 2];
        for (int v = 0; v <= n + 1; v++) {
            proxima[v] = inicio[v];
        }

        int[] destino = new int[m];
        int[] peso = new int[m];
        for (int i = 0; i < m; i++) {
            int p = proxima[orig[i]];
            destino[p] = dest[i];
            peso[p] = pes[i];
            proxima[orig[i]]++;
        }

        long[] dist = new long[n + 1];
        int[] arestas = new int[n + 1];
        int[] pred = new int[n + 1];

        long tempoInicio = System.nanoTime();
        dijkstra(n, inicio, destino, peso, s, t, dist, arestas, pred);
        long tempoFim = System.nanoTime();

        System.out.println();
        if (dist[t] == INFINITO) {
            System.out.println("Nao existe caminho de " + s + " para " + t);
        } else {
            System.out.println("Comprimento do caminho minimo: " + dist[t]);
            System.out.println("Numero de arestas: " + arestas[t]);

            int[] caminho = new int[arestas[t] + 1];
            int v = t;
            for (int i = arestas[t]; i >= 0; i--) {
                caminho[i] = v;
                v = pred[v];
            }

            System.out.print("Vertices do caminho: ");
            for (int i = 0; i < caminho.length; i++) {
                System.out.print(caminho[i]);
                if (i < caminho.length - 1) {
                    System.out.print(" -> ");
                }
            }
            System.out.println();
        }
        System.out.println("Tempo da busca: " + (tempoFim - tempoInicio) / 1000000.0 + " ms");
    }

    static void dijkstra(int n, int[] inicio, int[] destino, int[] peso, int s, int t,
                         long[] dist, int[] arestas, int[] pred) {
        boolean[] maduro = new boolean[n + 1];
        for (int v = 1; v <= n; v++) {
            dist[v] = INFINITO;
            arestas[v] = Integer.MAX_VALUE;
            pred[v] = 0;
        }
        dist[s] = 0;
        arestas[s] = 0;

        PriorityQueue<long[]> fila = new PriorityQueue<long[]>((a, b) -> {
            if (a[0] != b[0]) {
                return Long.compare(a[0], b[0]);
            }
            return Long.compare(a[1], b[1]);
        });
        fila.add(new long[] {0, 0, s});

        while (!fila.isEmpty()) {
            long[] atual = fila.poll();
            int v = (int) atual[2];

            if (maduro[v]) {
                continue; 
            }
            if (v == t) {
                break; 
            }

            for (int k = inicio[v]; k < inicio[v + 1]; k++) {
                int w = destino[k];
                long novaDist = dist[v] + peso[k];
                int novasArestas = arestas[v] + 1;

                boolean tenso = novaDist < dist[w]
                        || (novaDist == dist[w] && novasArestas < arestas[w]);

                if (!maduro[w] && tenso) {
                    dist[w] = novaDist;
                    arestas[w] = novasArestas;
                    pred[w] = v;
                    fila.add(new long[] {novaDist, novasArestas, w});
                }
            }
            maduro[v] = true;
        }
    }
}
