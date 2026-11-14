import java.io.PrintWriter;
import java.util.HashSet;
import java.util.Random;

public class GeradorGrafos {
    public static void main(String[] args) throws Exception {
        if (args.length < 4) {
            System.out.println("Uso: java GeradorGrafos n tipo(0=euleriano,1=semi,2=nao) semente arquivo [grauMedio]");
            return;
        }
        int n = Integer.parseInt(args[0]);
        int tipo = Integer.parseInt(args[1]);
        long semente = Long.parseLong(args[2]);
        int grauMedio = args.length > 4 ? Integer.parseInt(args[4]) : 4;
        Grafo g = gerar(n, tipo, grauMedio, new Random(semente));
        salvar(g, args[3]);
        System.out.println("Gerado grafo " + Fleury.NOME_CLASSE[tipo] + " com " + g.n + " vertices e "
                + g.m + " arestas em " + args[3]);
    }

    public static Grafo gerar(int n, int tipo, int grauMedio, Random sorteio) {
        if (n < 5) {
            throw new IllegalArgumentException("use n >= 5");
        }
        int alvo = Math.max(n, Math.min(grauMedio * n / 2, n * (n - 1) / 4));
        int capacidade = alvo + 16 + n / 25;
        int[] o = new int[capacidade];
        int[] d = new int[capacidade];
        HashSet<Long> existentes = new HashSet<>(capacidade * 2);
        int m = 0;

        int[] perm = new int[n];
        for (int i = 0; i < n; i++) {
            perm[i] = i + 1;
        }
        embaralhar(perm, sorteio);
        for (int i = 0; i < n; i++) {
            int u = perm[i];
            int v = perm[(i + 1) % n];
            o[m] = u;
            d[m] = v;
            existentes.add(Grafo.chave(u, v, n));
            m++;
        }

        int[] ciclo = new int[8];
        while (m < alvo) {
            int tamanho = 3 + sorteio.nextInt(Math.min(6, n - 2));
            if (!sortearDistintos(ciclo, tamanho, n, sorteio)) {
                continue;
            }
            boolean livre = true;
            for (int i = 0; i < tamanho && livre; i++) {
                if (existentes.contains(Grafo.chave(ciclo[i], ciclo[(i + 1) % tamanho], n))) {
                    livre = false;
                }
            }
            if (!livre) {
                continue;
            }
            for (int i = 0; i < tamanho; i++) {
                int u = ciclo[i];
                int v = ciclo[(i + 1) % tamanho];
                o[m] = u;
                d[m] = v;
                existentes.add(Grafo.chave(u, v, n));
                m++;
            }
        }

        if (tipo == Fleury.SEMI_EULERIANO) {
            int e = sorteio.nextInt(m);
            o[e] = o[m - 1];
            d[e] = d[m - 1];
            m--;
        } else if (tipo == Fleury.NAO_EULERIANO) {
            int k = Math.max(2, n / 50);
            boolean[] usado = new boolean[n + 1];
            int adicionadas = 0;
            while (adicionadas < k) {
                int u = sorteio.nextInt(n) + 1;
                int v = sorteio.nextInt(n) + 1;
                if (u == v || usado[u] || usado[v] || existentes.contains(Grafo.chave(u, v, n))) {
                    continue;
                }
                usado[u] = true;
                usado[v] = true;
                o[m] = u;
                d[m] = v;
                existentes.add(Grafo.chave(u, v, n));
                m++;
                adicionadas++;
            }
        }

        int[] idx = new int[m];
        for (int i = 0; i < m; i++) {
            idx[i] = i;
        }
        embaralhar(idx, sorteio);
        int[] oo = new int[m];
        int[] dd = new int[m];
        for (int i = 0; i < m; i++) {
            oo[i] = o[idx[i]];
            dd[i] = d[idx[i]];
        }
        return new Grafo(n, oo, dd);
    }

    private static boolean sortearDistintos(int[] v, int k, int n, Random sorteio) {
        for (int i = 0; i < k; i++) {
            v[i] = sorteio.nextInt(n) + 1;
            for (int j = 0; j < i; j++) {
                if (v[j] == v[i]) {
                    return false;
                }
            }
        }
        return true;
    }

    private static void embaralhar(int[] a, Random sorteio) {
        for (int i = a.length - 1; i > 0; i--) {
            int j = sorteio.nextInt(i + 1);
            int t = a[i];
            a[i] = a[j];
            a[j] = t;
        }
    }

    public static void salvar(Grafo g, String nomeArquivo) throws Exception {
        PrintWriter saida = new PrintWriter(nomeArquivo);
        saida.println(g.n + " " + g.arestasAtivas);
        for (int e = 0; e < g.m; e++) {
            if (g.ativa[e]) {
                saida.println(g.origem[e] + " " + g.destino[e]);
            }
        }
        saida.close();
    }
}
