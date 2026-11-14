public class Fleury {
    public static final int NAIVE = 0;
    public static final int TARJAN = 1;

    public static final int EULERIANO = 0;
    public static final int SEMI_EULERIANO = 1;
    public static final int NAO_EULERIANO = 2;

    public static final String[] NOME_METODO = {"naive", "tarjan"};
    public static final String[] NOME_CLASSE = {"euleriano", "semi-euleriano", "nao euleriano"};

    public static int classificar(Grafo g) {
        int impares = 0;
        int inicio = -1;
        for (int v = 1; v <= g.n; v++) {
            if (g.grau[v] % 2 == 1) {
                impares++;
            }
            if (inicio == -1 && g.grau[v] > 0) {
                inicio = v;
            }
        }
        if (impares != 0 && impares != 2) {
            return NAO_EULERIANO;
        }
        if (inicio != -1) {
            boolean[] vis = new boolean[g.n + 1];
            int[] fila = new int[g.n + 1];
            int ini = 0;
            int fim = 0;
            fila[fim++] = inicio;
            vis[inicio] = true;
            while (ini < fim) {
                int v = fila[ini++];
                for (int i = 0; i < g.grau[v]; i++) {
                    int w = g.outro(g.adj[v][i], v);
                    if (!vis[w]) {
                        vis[w] = true;
                        fila[fim++] = w;
                    }
                }
            }
            for (int v = 1; v <= g.n; v++) {
                if (g.grau[v] > 0 && !vis[v]) {
                    return NAO_EULERIANO;
                }
            }
        }
        return impares == 0 ? EULERIANO : SEMI_EULERIANO;
    }

    public static int[] caminho(Grafo original, int metodo, long prazo) {
        int classe = classificar(original);
        if (classe == NAO_EULERIANO) {
            return null;
        }

        int inicio = 1;
        for (int v = 1; v <= original.n; v++) {
            if (original.grau[v] > 0) {
                inicio = v;
                break;
            }
        }
        if (classe == SEMI_EULERIANO) {
            for (int v = 1; v <= original.n; v++) {
                if (original.grau[v] % 2 == 1) {
                    inicio = v;
                    break;
                }
            }
        }

        Grafo g = original.copia();
        Pontes pontes = new Pontes(g);
        pontes.prazo = prazo;

        int total = g.arestasAtivas;
        int[] caminho = new int[total + 1];
        int u = inicio;
        caminho[0] = u;

        for (int k = 1; k <= total; k++) {
            if (System.nanoTime() > prazo) {
                throw new Pontes.TempoEsgotado();
            }
            int escolhida = escolherAresta(g, pontes, u, metodo);
            int w = g.outro(escolhida, u);
            g.remover(escolhida);
            caminho[k] = w;
            u = w;
        }
        return caminho;
    }

    private static int escolherAresta(Grafo g, Pontes pontes, int u, int metodo) {
        int[] lista = g.adj[u];
        if (g.grau[u] == 1) {
            return lista[0];
        }
        if (metodo == TARJAN) {
            pontes.tarjanDaComponente(u);
            for (int i = 0; i < g.grau[u]; i++) {
                if (!pontes.ehPonteMarcada(lista[i])) {
                    return lista[i];
                }
            }
        } else {
            int[] candidatas = java.util.Arrays.copyOf(lista, g.grau[u]);
            for (int e : candidatas) {
                if (!pontes.ehPonteNaive(e)) {
                    return e;
                }
            }
        }
        return lista[0];
    }

    public static boolean valido(Grafo g, int[] caminho) {
        if (caminho == null || caminho.length != g.arestasAtivas + 1) {
            return false;
        }
        java.util.HashMap<Long, Integer> restantes = new java.util.HashMap<>();
        for (int e = 0; e < g.m; e++) {
            if (g.ativa[e]) {
                restantes.merge(Grafo.chave(g.origem[e], g.destino[e], g.n), 1, Integer::sum);
            }
        }
        for (int i = 0; i + 1 < caminho.length; i++) {
            long c = Grafo.chave(caminho[i], caminho[i + 1], g.n);
            Integer q = restantes.get(c);
            if (q == null || q == 0) {
                return false;
            }
            restantes.put(c, q - 1);
        }
        return true;
    }
}
