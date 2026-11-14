import csv
import sys
from collections import defaultdict

entrada = sys.argv[1] if len(sys.argv) > 1 else "../resultados/tempos.csv"
saida = sys.argv[2] if len(sys.argv) > 2 else "resultados.tex"

CLASSES = ["euleriano", "semi-euleriano", "nao euleriano"]
NOME_CLASSE = {"euleriano": "Euleriano", "semi-euleriano": "Semi-euleriano", "nao euleriano": "Não euleriano"}
MEDIDAS = ["pontes_naive", "pontes_tarjan", "fleury_naive", "fleury_tarjan"]
ESTILO = {
    "pontes_naive": "color=red, mark=square*",
    "pontes_tarjan": "color=blue, mark=*",
    "fleury_naive": "color=orange, mark=triangle*, dashed",
    "fleury_tarjan": "color=teal, mark=diamond*, dashed",
}
LEGENDA = {
    "pontes_naive": "Pontes -- naïve",
    "pontes_tarjan": "Pontes -- Tarjan",
    "fleury_naive": "Fleury + naïve",
    "fleury_tarjan": "Fleury + Tarjan",
}

tempos = defaultdict(list)
esgotado = set()
arestas = defaultdict(list)
for linha in csv.DictReader(open(entrada)):
    chave = (int(linha["n"]), linha["classe"], linha["medida"])
    if linha["status"] == "ok":
        tempos[chave].append(float(linha["tempo_ms"]))
    else:
        esgotado.add(chave)
    if linha["medida"] == "pontes_tarjan":
        arestas[(int(linha["n"]), linha["classe"])].append(int(linha["m"]))

tamanhos = sorted({k[0] for k in tempos} | {k[0] for k in esgotado})


def media(chave):
    if chave in esgotado or not tempos[chave]:
        return None
    return sum(tempos[chave]) / len(tempos[chave])


def fmt(ms):
    if ms is None:
        return "$>$ limite"
    if ms < 0.01:
        texto = f"{ms:.4f}"
    elif ms < 1:
        texto = f"{ms:.3f}"
    elif ms < 100:
        texto = f"{ms:.2f}"
    else:
        texto = f"{ms:,.0f}"
    return texto.replace(",", "_").replace(".", ",").replace("_", ".")


out = []
out.append("\\begin{table}[H]\n\\centering\n\\small\n\\setlength{\\tabcolsep}{4pt}")
out.append("\\caption{Tempo médio (ms) de cada estratégia. $\\bar m$ é o número médio de arestas e $r$ o número de grafos.}")
out.append("\\label{tab:resultados}")
out.append("\\begin{tabular}{llrrrrrr}\n\\toprule")
out.append("Classe & $n$ & $\\bar m$ & $r$ & Pontes naïve & Pontes Tarjan & Fleury+naïve & Fleury+Tarjan \\\\\n\\midrule")
presentes = [c for c in CLASSES if any((n, c) in arestas for n in tamanhos)]
for c in presentes:
    for i, n in enumerate(tamanhos):
        ms = arestas.get((n, c), [])
        if not ms:
            continue
        mbar = sum(ms) / len(ms)
        celulas = [fmt(media((n, c, md))) for md in MEDIDAS]
        rotulo = NOME_CLASSE[c] if i == 0 else ""
        out.append(f"{rotulo} & {n:,} & {mbar:,.0f} & {len(ms)} & ".replace(",", ".") + " & ".join(celulas) + " \\\\")
    if c != presentes[-1]:
        out.append("\\midrule")
out.append("\\bottomrule\n\\end{tabular}\n\\end{table}\n")

for c in presentes:
    out.append("\\begin{figure}[H]\n\\centering\n\\begin{tikzpicture}")
    out.append("\\begin{loglogaxis}[width=0.85\\textwidth, height=6.2cm, xlabel={Número de vértices $n$}, "
               "ylabel={Tempo médio (ms)}, grid=major, legend pos=north west, legend style={font=\\footnotesize}, "
               "xtick={100,1000,10000,100000}]")
    for md in MEDIDAS:
        pts = [(n, media((n, c, md))) for n in tamanhos]
        pts = [(n, v) for n, v in pts if v is not None and v > 0]
        if not pts:
            continue
        coords = " ".join(f"({n},{v:.6g})" for n, v in pts)
        out.append(f"\\addplot[{ESTILO[md]}] coordinates {{{coords}}};")
        out.append(f"\\addlegendentry{{{LEGENDA[md]}}}")
    out.append("\\end{loglogaxis}\n\\end{tikzpicture}")
    out.append(f"\\caption{{Tempo médio em escala log-log -- grafos da classe {NOME_CLASSE[c].lower()}.}}")
    out.append(f"\\label{{fig:{c.replace(' ', '-')}}}\n\\end{{figure}}\n")

open(saida, "w").write("\n".join(out))
print("gerado", saida)
