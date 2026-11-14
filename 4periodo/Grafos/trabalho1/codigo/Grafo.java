import java.io.File;
import java.util.HashSet;
import java.util.Scanner;

public final class Grafo {
    int n;
    int m;
    int[] origem;
    int[] destino;
    int[][] adj;
    int[] grau;
    int[] posOrigem;
    int[] posDestino;
    boolean[] ativa;
    int arestasAtivas;

    public Grafo(int n, int[] origem, int[] destino) {
        this.n = n;
        this.m = origem.length;
        this.origem = origem;
        this.destino = destino;

        int[] capacidade = new int[n + 1];
        for (int e = 0; e < m; e++) {
            capacidade[origem[e]]++;
            capacidade[destino[e]]++;
        }
        adj = new int[n + 1][];
        for (int v = 0; v <= n; v++) {
            adj[v] = new int[capacidade[v]];
        }
        grau = new int[n + 1];
        posOrigem = new int[m];
        posDestino = new int[m];
        ativa = new boolean[m];
        for (int e = 0; e < m; e++) {
            inserir(e);
        }
    }

    public Grafo copia() {
        Grafo g = new Grafo(n, origem.clone(), destino.clone());
        for (int e = 0; e < m; e++) {
            if (!ativa[e]) {
                g.remover(e);
            }
        }
        return g;
    }

    public int outro(int e, int v) {
        return origem[e] == v ? destino[e] : origem[e];
    }

    public void remover(int e) {
        tirarDaLista(origem[e], posOrigem[e]);
        tirarDaLista(destino[e], posDestino[e]);
        ativa[e] = false;
        arestasAtivas--;
    }

    public void inserir(int e) {
        int u = origem[e];
        int v = destino[e];
        posOrigem[e] = grau[u];
        adj[u][grau[u]++] = e;
        posDestino[e] = grau[v];
        adj[v][grau[v]++] = e;
        ativa[e] = true;
        arestasAtivas++;
    }

    private void tirarDaLista(int v, int p) {
        int ultima = adj[v][grau[v] - 1];
        adj[v][p] = ultima;
        if (origem[ultima] == v) {
            posOrigem[ultima] = p;
        } else {
            posDestino[ultima] = p;
        }
        grau[v]--;
    }

    public static Grafo ler(String nomeArquivo) throws Exception {
        Scanner leitor = new Scanner(new File(nomeArquivo));
        int n = leitor.nextInt();
        int m = leitor.nextInt();
        int[] o = new int[m];
        int[] d = new int[m];
        HashSet<Long> vistas = new HashSet<>();
        int k = 0;
        int descartadas = 0;
        for (int i = 0; i < m && leitor.hasNextInt(); i++) {
            int u = leitor.nextInt();
            int v = leitor.nextInt();
            if (u < 1 || u > n || v < 1 || v > n) {
                throw new IllegalArgumentException("Aresta (" + u + ", " + v + ") fora da faixa 1.." + n);
            }
            if (u == v || !vistas.add(chave(u, v, n))) {
                descartadas++;
                continue;
            }
            o[k] = u;
            d[k] = v;
            k++;
        }
        leitor.close();
        if (descartadas > 0) {
            System.out.println("Aviso: " + descartadas + " laco(s)/aresta(s) repetida(s) descartado(s) (grafo simples).");
        }
        return new Grafo(n, java.util.Arrays.copyOf(o, k), java.util.Arrays.copyOf(d, k));
    }

    public static long chave(int u, int v, int n) {
        int a = Math.min(u, v);
        int b = Math.max(u, v);
        return (long) a * (n + 1) + b;
    }
}
