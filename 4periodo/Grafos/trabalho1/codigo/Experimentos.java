import java.io.File;
import java.io.PrintWriter;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Random;

public class Experimentos {
    static final int[] TAMANHOS = {100, 1000, 10000, 100000};
    static final int[] REPETICOES = {10, 10, 3, 1};
    static final String[] MEDIDAS = {"pontes_naive", "pontes_tarjan", "fleury_naive", "fleury_tarjan"};

    public static void main(String[] args) throws Exception {
        double limiteSegundos = args.length > 0 ? Double.parseDouble(args[0]) : 600;
        int grauMedio = args.length > 1 ? Integer.parseInt(args[1]) : 4;
        String arquivo = args.length > 2 ? args[2] : "../resultados/tempos.csv";
        long limite = (long) (limiteSegundos * 1e9);

        new File(arquivo).getAbsoluteFile().getParentFile().mkdirs();
        PrintWriter csv = new PrintWriter(arquivo);
        csv.println("n,m,classe,repeticao,medida,tempo_ms,status");

        aquecer(grauMedio);

        System.out.printf(Locale.US, "Limite por medicao: %.0f s, grau medio %d%n", limiteSegundos, grauMedio);
        System.out.printf("%-8s %-15s %-14s %12s %8s%n", "n", "classe", "medida", "media (ms)", "rodadas");

        for (int classe = 0; classe <= 2; classe++) {
            boolean[] esgotou = new boolean[MEDIDAS.length];
            for (int t = 0; t < TAMANHOS.length; t++) {
                int n = TAMANHOS[t];
                double[] soma = new double[MEDIDAS.length];
                int[] cont = new int[MEDIDAS.length];
                for (int rep = 0; rep < REPETICOES[t]; rep++) {
                    Random sorteio = new Random(1000L * n + 10L * classe + rep);
                    Grafo g = GeradorGrafos.gerar(n, classe, grauMedio, sorteio);
                    if (Fleury.classificar(g) != classe) {
                        throw new IllegalStateException("gerador produziu classe errada");
                    }
                    List<Integer> referencia = null;
                    for (int k = 0; k < MEDIDAS.length; k++) {
                        if (esgotou[k]) {
                            continue;
                        }
                        long prazo = System.nanoTime() + limite;
                        String status = "ok";
                        long ini = System.nanoTime();
                        try {
                            Object r = medir(g, k, prazo);
                            if (k <= 1) {
                                @SuppressWarnings("unchecked")
                                List<Integer> pontes = (List<Integer>) r;
                                if (referencia == null) {
                                    referencia = pontes;
                                } else if (!new HashSet<>(referencia).equals(new HashSet<>(pontes))) {
                                    throw new IllegalStateException("naive e Tarjan discordam");
                                }
                            } else {
                                int[] caminho = (int[]) r;
                                boolean ok = classe == Fleury.NAO_EULERIANO ? caminho == null : Fleury.valido(g, caminho);
                                if (!ok) {
                                    throw new IllegalStateException("caminho invalido");
                                }
                            }
                        } catch (Pontes.TempoEsgotado ex) {
                            status = "tempo_esgotado";
                            esgotou[k] = true;
                        }
                        double ms = (System.nanoTime() - ini) / 1e6;
                        csv.printf(Locale.US, "%d,%d,%s,%d,%s,%.4f,%s%n", n, g.m, Fleury.NOME_CLASSE[classe],
                                rep, MEDIDAS[k], ms, status);
                        csv.flush();
                        if (status.equals("ok")) {
                            soma[k] += ms;
                            cont[k]++;
                        }
                    }
                }
                for (int k = 0; k < MEDIDAS.length; k++) {
                    if (cont[k] > 0 && !esgotou[k]) {
                        System.out.printf(Locale.US, "%-8d %-15s %-14s %12.3f %8d%n", n, Fleury.NOME_CLASSE[classe],
                                MEDIDAS[k], soma[k] / cont[k], cont[k]);
                    } else {
                        System.out.printf("%-8d %-15s %-14s %12s %8s%n", n, Fleury.NOME_CLASSE[classe], MEDIDAS[k],
                                "> limite", "-");
                    }
                }
            }
        }
        csv.close();
        System.out.println("Resultados em " + arquivo);
    }

    static Object medir(Grafo g, int medida, long prazo) {
        switch (medida) {
            case 0: {
                Pontes p = new Pontes(g);
                p.prazo = prazo;
                return p.naive();
            }
            case 1: {
                Pontes p = new Pontes(g);
                p.prazo = prazo;
                return p.tarjan();
            }
            case 2:
                return Fleury.caminho(g, Fleury.NAIVE, prazo);
            default:
                return Fleury.caminho(g, Fleury.TARJAN, prazo);
        }
    }

    static void aquecer(int grauMedio) {
        Random r = new Random(1);
        for (int i = 0; i < 30; i++) {
            for (int classe = 0; classe <= 2; classe++) {
                Grafo g = GeradorGrafos.gerar(300, classe, grauMedio, r);
                for (int k = 0; k < MEDIDAS.length; k++) {
                    medir(g, k, Long.MAX_VALUE);
                }
            }
        }
    }
}
