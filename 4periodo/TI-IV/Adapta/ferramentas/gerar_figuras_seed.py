"""Gera as figuras das questões do seed em assets/questoes/ (JPG até 200 KB).

Uso, a partir da raiz do projeto Flutter:
    python3 -m pip install matplotlib pillow
    python3 ferramentas/gerar_figuras_seed.py
"""
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon

SAIDA = Path(__file__).resolve().parent.parent / "assets" / "questoes"
INDIGO = "#4F46E5"


def salvar(fig, nome):
    SAIDA.mkdir(parents=True, exist_ok=True)
    caminho = SAIDA / nome
    fig.savefig(caminho, dpi=130, format="jpg", pil_kwargs={"quality": 85})
    plt.close(fig)
    tamanho = caminho.stat().st_size // 1024
    assert tamanho <= 200, f"{nome} passou de 200 KB"
    print(f"{nome}: {tamanho} KB")


def grafico_funcao_afim():
    fig, ax = plt.subplots(figsize=(5, 4))
    xs = [-1, 5]
    ax.plot(xs, [2 * x + 2 for x in xs], color=INDIGO, linewidth=2.5)
    ax.scatter([0, 4], [2, 10], color=INDIGO, zorder=3)
    ax.annotate("(0, 2)", (0, 2), textcoords="offset points", xytext=(8, -14))
    ax.annotate("(4, 10)", (4, 10), textcoords="offset points", xytext=(-46, 4))
    ax.axhline(0, color="black", linewidth=0.8)
    ax.axvline(0, color="black", linewidth=0.8)
    ax.set_xlim(-1, 5)
    ax.set_ylim(-1, 12)
    ax.set_xlabel("x")
    ax.set_ylabel("f(x)")
    ax.grid(alpha=0.3)
    fig.tight_layout()
    salvar(fig, "grafico_funcao_afim.jpg")


def tabela_vendas():
    fig, ax = plt.subplots(figsize=(5, 2.4))
    ax.axis("off")
    tabela = ax.table(
        cellText=[
            ["1º trimestre", "200"],
            ["2º trimestre", "250"],
            ["3º trimestre", "300"],
            ["4º trimestre", "240"],
        ],
        colLabels=["Período", "Unidades vendidas"],
        loc="center",
        cellLoc="center",
    )
    tabela.auto_set_font_size(False)
    tabela.set_fontsize(12)
    tabela.scale(1, 1.7)
    for coluna in range(2):
        celula = tabela[0, coluna]
        celula.set_facecolor(INDIGO)
        celula.set_text_props(color="white", weight="bold")
    salvar(fig, "tabela_vendas.jpg")


def figura_trapezio():
    fig, ax = plt.subplots(figsize=(5, 3.4))
    pontos = [(0, 0), (10, 0), (8, 4), (2, 4)]
    ax.add_patch(
        Polygon(pontos, facecolor="#E0E7FF", edgecolor=INDIGO, linewidth=2.5)
    )
    ax.plot([2, 2], [0, 4], color="gray", linestyle="--")
    ax.text(5, -0.7, "10 m", ha="center", fontsize=13)
    ax.text(5, 4.3, "6 m", ha="center", fontsize=13)
    ax.text(2.25, 1.9, "4 m", fontsize=13)
    ax.set_xlim(-1, 11)
    ax.set_ylim(-1.3, 5)
    ax.set_aspect("equal")
    ax.axis("off")
    salvar(fig, "figura_trapezio.jpg")


if __name__ == "__main__":
    grafico_funcao_afim()
    tabela_vendas()
    figura_trapezio()
