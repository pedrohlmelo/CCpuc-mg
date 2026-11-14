import java.util.HashSet;
import java.util.List;
import java.util.Random;

public class Testes {
    static int falhas = 0;

    public static void main(String[] args) {
        figura1();
        aleatoriosComPontes();
        fleuryGerados();
        System.out.println(falhas == 0 ? "TODOS OS TESTES PASSARAM" : falhas + " FALHA(S)");
        if (falhas > 0) {
            System.exit(1);
        }
    }

    static void figura1() {
        int[][] arestas = {{1, 2}, {1, 4}, {1, 5}, {2, 3}, {2, 4}, {2, 5}, {3, 4}, {3, 5},
                {3, 6}, {4, 6}, {6, 7}, {7, 8}, {7, 9}, {8, 9}};
        Grafo g = montar(9, arestas);
        Pontes p = new Pontes(g);
        List<Integer> naive = p.naive();
        List<Integer> tarjan = p.tarjan();
        verificar("figura 1: naive acha so F-G", naive.size() == 1 && ehAresta(g, naive.get(0), 6, 7));
        verificar("figura 1: Tarjan acha so F-G", tarjan.size() == 1 && ehAresta(g, tarjan.get(0), 6, 7));
        verificar("figura 1: nao euleriano (4 vertices impares)", Fleury.classificar(g) == Fleury.NAO_EULERIANO);
        verificar("figura 1: Fleury retorna null", Fleury.caminho(g, Fleury.TARJAN, Long.MAX_VALUE) == null);

        int[][] semi = {{1, 2}, {1, 4}, {2, 3}, {2, 4}, {2, 5}, {3, 4}, {3, 5},
                {4, 6}, {6, 7}, {7, 8}, {7, 9}, {8, 9}};
        Grafo s = montar(9, semi);
        verificar("figura 1 modificada: semi-euleriano", Fleury.classificar(s) == Fleury.SEMI_EULERIANO);
        for (int metodo = 0; metodo <= 1; metodo++) {
            int[] c = Fleury.caminho(s, metodo, Long.MAX_VALUE);
            verificar("figura 1 modificada: caminho " + Fleury.NOME_METODO[metodo], Fleury.valido(s, c));
        }
    }

    static void aleatoriosComPontes() {
        Random r = new Random(42);
        int erros = 0;
        for (int t = 0; t < 3000; t++) {
            int n = 2 + r.nextInt(30);
            HashSet<Long> vistas = new HashSet<>();
            int[] o = new int[n * 3];
            int[] d = new int[n * 3];
            int m = 0;
            for (int v = 2; v <= n; v++) {
                if (r.nextInt(10) < 8) {
                    int u = 1 + r.nextInt(v - 1);
                    o[m] = u;
                    d[m] = v;
                    vistas.add(Grafo.chave(u, v, n));
                    m++;
                }
            }
            int extras = r.nextInt(n);
            for (int i = 0; i < extras; i++) {
                int u = 1 + r.nextInt(n);
                int v = 1 + r.nextInt(n);
                if (u != v && vistas.add(Grafo.chave(u, v, n))) {
                    o[m] = u;
                    d[m] = v;
                    m++;
                }
            }
            Grafo g = new Grafo(n, java.util.Arrays.copyOf(o, m), java.util.Arrays.copyOf(d, m));
            Pontes p = new Pontes(g);
            if (!new HashSet<>(p.naive()).equals(new HashSet<>(p.tarjan()))) {
                erros++;
            }
        }
        verificar("naive == Tarjan em 3000 grafos aleatorios", erros == 0);
    }

    static void fleuryGerados() {
        Random r = new Random(7);
        int erros = 0;
        for (int t = 0; t < 300; t++) {
            int n = 10 + r.nextInt(200);
            for (int tipo = 0; tipo <= 2; tipo++) {
                Grafo g = GeradorGrafos.gerar(n, tipo, 2 + 2 * r.nextInt(3), r);
                if (Fleury.classificar(g) != tipo) {
                    erros++;
                    continue;
                }
                for (int metodo = 0; metodo <= 1; metodo++) {
                    int[] c = Fleury.caminho(g, metodo, Long.MAX_VALUE);
                    boolean ok = tipo == Fleury.NAO_EULERIANO ? c == null : Fleury.valido(g, c);
                    if (ok && tipo == Fleury.EULERIANO) {
                        ok = c[0] == c[c.length - 1];
                    }
                    if (!ok) {
                        erros++;
                    }
                }
            }
        }
        verificar("gerador + Fleury (naive e Tarjan) em 900 grafos", erros == 0);
    }

    static Grafo montar(int n, int[][] arestas) {
        int[] o = new int[arestas.length];
        int[] d = new int[arestas.length];
        for (int i = 0; i < arestas.length; i++) {
            o[i] = arestas[i][0];
            d[i] = arestas[i][1];
        }
        return new Grafo(n, o, d);
    }

    static boolean ehAresta(Grafo g, int e, int u, int v) {
        return Grafo.chave(g.origem[e], g.destino[e], g.n) == Grafo.chave(u, v, g.n);
    }

    static void verificar(String nome, boolean ok) {
        System.out.println((ok ? "[ok]    " : "[FALHA] ") + nome);
        if (!ok) {
            falhas++;
        }
    }
}
