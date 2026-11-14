import java.util.ArrayList;
import java.util.List;

public class Pontes {
    private final Grafo g;

    private final int[] visitado;
    private int rodada = 0;

    private final int[] fila;

    private final int[] pilha;
    private final int[] proximo;
    private final int[] ordem;
    private final int[] pre;
    private final int[] nd;
    private final int[] baixo;
    private final int[] alto;
    private final int[] arestaPai;
    private final int[] marcaPonte;
    private int rodadaPonte = 0;

    long prazo = Long.MAX_VALUE;

    public Pontes(Grafo g) {
        this.g = g;
        int n = g.n;
        visitado = new int[n + 1];
        fila = new int[n + 1];
        pilha = new int[n + 1];
        proximo = new int[n + 1];
        ordem = new int[n + 1];
        pre = new int[n + 1];
        nd = new int[n + 1];
        baixo = new int[n + 1];
        alto = new int[n + 1];
        arestaPai = new int[n + 1];
        marcaPonte = new int[g.m];
    }

    public int componentes() {
        rodada++;
        int c = 0;
        for (int v = 1; v <= g.n; v++) {
            if (visitado[v] != rodada) {
                c++;
                largura(v);
            }
        }
        return c;
    }

    private void largura(int s) {
        int ini = 0;
        int fim = 0;
        fila[fim++] = s;
        visitado[s] = rodada;
        while (ini < fim) {
            int v = fila[ini++];
            int[] lista = g.adj[v];
            for (int i = 0; i < g.grau[v]; i++) {
                int w = g.outro(lista[i], v);
                if (visitado[w] != rodada) {
                    visitado[w] = rodada;
                    fila[fim++] = w;
                }
            }
        }
    }

    public List<Integer> naive() {
        List<Integer> pontes = new ArrayList<>();
        int c0 = componentes();
        for (int e = 0; e < g.m; e++) {
            if (!g.ativa[e]) {
                continue;
            }
            if (System.nanoTime() > prazo) {
                throw new TempoEsgotado();
            }
            g.remover(e);
            if (componentes() > c0) {
                pontes.add(e);
            }
            g.inserir(e);
        }
        return pontes;
    }

    public boolean ehPonteNaive(int e) {
        int u = g.origem[e];
        int v = g.destino[e];
        g.remover(e);
        rodada++;
        largura(u);
        boolean ponte = visitado[v] != rodada;
        g.inserir(e);
        return ponte;
    }

    public List<Integer> tarjan() {
        rodada++;
        rodadaPonte++;
        for (int v = 1; v <= g.n; v++) {
            if (visitado[v] != rodada) {
                tarjanComponente(v);
            }
        }
        List<Integer> pontes = new ArrayList<>();
        for (int e = 0; e < g.m; e++) {
            if (g.ativa[e] && marcaPonte[e] == rodadaPonte) {
                pontes.add(e);
            }
        }
        return pontes;
    }

    public void tarjanDaComponente(int r) {
        rodada++;
        rodadaPonte++;
        tarjanComponente(r);
    }

    public boolean ehPonteMarcada(int e) {
        return marcaPonte[e] == rodadaPonte;
    }

    private void tarjanComponente(int r) {
        int cont = 0;
        int topo = 0;
        pilha[0] = r;
        visitar(r, -1, ++cont);
        ordem[0] = r;
        while (topo >= 0) {
            int v = pilha[topo];
            if (proximo[v] < g.grau[v]) {
                int e = g.adj[v][proximo[v]++];
                int w = g.outro(e, v);
                if (visitado[w] != rodada) {
                    ordem[cont] = w;
                    visitar(w, e, ++cont);
                    pilha[++topo] = w;
                }
            } else {
                topo--;
            }
        }

        if (System.nanoTime() > prazo) {
            throw new TempoEsgotado();
        }

        for (int i = cont - 1; i >= 0; i--) {
            int v = ordem[i];
            int ev = arestaPai[v];
            int[] lista = g.adj[v];
            for (int j = 0; j < g.grau[v]; j++) {
                int e = lista[j];
                int w = g.outro(e, v);
                boolean arestaDaArvore = (e == ev) || (arestaPai[w] == e);
                if (!arestaDaArvore) {
                    if (pre[w] < baixo[v]) {
                        baixo[v] = pre[w];
                    }
                    if (pre[w] > alto[v]) {
                        alto[v] = pre[w];
                    }
                }
            }
            if (ev != -1) {
                if (baixo[v] == pre[v] && alto[v] < pre[v] + nd[v]) {
                    marcaPonte[ev] = rodadaPonte;
                }
                int p = g.outro(ev, v);
                nd[p] += nd[v];
                if (baixo[v] < baixo[p]) {
                    baixo[p] = baixo[v];
                }
                if (alto[v] > alto[p]) {
                    alto[p] = alto[v];
                }
            }
        }
    }

    private void visitar(int v, int e, int numero) {
        visitado[v] = rodada;
        proximo[v] = 0;
        arestaPai[v] = e;
        pre[v] = numero;
        nd[v] = 1;
        baixo[v] = numero;
        alto[v] = numero;
    }

    public static class TempoEsgotado extends RuntimeException {
        private static final long serialVersionUID = 1L;

        public TempoEsgotado() {
            super("tempo limite excedido", null, false, false);
        }
    }
}
