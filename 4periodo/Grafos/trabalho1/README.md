# Trabalho Prático 01 – Teoria dos Grafos e Computabilidade

Pontes (método naïve e Tarjan, 1974) e caminho euleriano pelo método de Fleury.

Grupo: Bernardo Barbosa Heronville, Luiz Felipe Volpi, Pedro Henrique Lopes de Melo.

| Pasta | Conteúdo |
|---|---|
| `codigo/` | Fontes Java: `Grafo`, `Pontes` (naïve e Tarjan), `Fleury`, `GeradorGrafos`, `Main`, `Experimentos`, `Testes` |
| `exemplos/` | `figura1.txt`, o grafo da Figura 1 do enunciado (A=1 … I=9) |
| `resultados/` | `tempos.csv` (todas as medições) e `resumo.txt` |
| `relatorio/` | `relatorio.tex` + `resultados.tex` + `discussao.tex` (fontes TeX) e `relatorio.pdf` |

```
cd codigo
javac *.java
java Testes
java Main ../exemplos/figura1.txt
java Experimentos 1800 4 ../resultados/tempos.csv

cd ../relatorio
python3 gerar_resultados.py
tectonic relatorio.tex        # ou pdflatex relatorio.tex
```
