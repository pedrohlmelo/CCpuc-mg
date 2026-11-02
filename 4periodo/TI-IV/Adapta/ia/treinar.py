"""Treina os dois modelos do Adapta e exporta os coeficientes para o app.

Uso, a partir da raiz do projeto Flutter (depois de ia/gerar_dataset.py):
    python3 ia/treinar.py

Saída:
  assets/modelos/esquecimento.json   regressão logística do esquecimento
  assets/modelos/dificuldades.json   dificuldade b de cada questão
  ia/relatorio.md, ia/roc.png, ia/calibracao.png
"""
import csv
import json
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from scipy import sparse
from sklearn.calibration import calibration_curve
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, brier_score_loss, roc_auc_score, roc_curve
from sklearn.model_selection import GroupShuffleSplit

PASTA = Path(__file__).resolve().parent
DADOS = PASTA / "dados"
MODELOS = PASTA.parent / "assets" / "modelos"
INDIGO = "#4F46E5"
CINZA = "#9CA3AF"


def ler_csv(nome):
    with open(DADOS / nome) as arquivo:
        linhas = list(csv.DictReader(arquivo))
    return {c: np.array([float(l[c]) for l in linhas]) for c in linhas[0]}


def treinar_esquecimento():
    d = ler_csv("eventos.csv")
    dias, qtd = d["dias_desde_ultimo_estudo"], d["qtd_revisoes"]
    X = np.column_stack(
        [np.log1p(dias), qtd, d["dificuldade"], d["taxa_acerto_aluno"]]
    )
    y = d["lembrou"].astype(int)

    # Separa por aluno: o teste só tem alunos que o modelo nunca viu.
    divisao = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=42)
    treino, teste = next(divisao.split(X, y, groups=d["id_aluno"]))

    modelo = LogisticRegression(max_iter=1000)
    modelo.fit(X[treino], y[treino])
    p_modelo = modelo.predict_proba(X[teste])[:, 1]
    p_fixa = np.exp(-dias[teste] / (1 + qtd[teste]))

    metricas = {
        nome: {
            "auc": roc_auc_score(y[teste], p),
            "acuracia": accuracy_score(y[teste], p >= 0.5),
            "brier": brier_score_loss(y[teste], p),
        }
        for nome, p in [("modelo", p_modelo), ("fixa", p_fixa)]
    }

    json.dump(
        {
            "modelo": "regressao_logistica",
            "intercepto": float(modelo.intercept_[0]),
            "coeficientes": dict(
                zip(
                    ["log1p_dias", "qtd_revisoes", "dificuldade", "taxa_acerto_aluno"],
                    map(float, modelo.coef_[0]),
                )
            ),
        },
        open(MODELOS / "esquecimento.json", "w"),
        indent=2,
    )
    graficos(y[teste], p_modelo, p_fixa, metricas)
    return metricas, len(y), len(teste)


def graficos(y, p_modelo, p_fixa, metricas):
    fig, ax = plt.subplots(figsize=(5, 4.4))
    for p, nome, cor, chave in [
        (p_modelo, "Regressão logística", INDIGO, "modelo"),
        (p_fixa, "Fórmula fixa", CINZA, "fixa"),
    ]:
        fpr, tpr, _ = roc_curve(y, p)
        ax.plot(fpr, tpr, color=cor, linewidth=2, label=f"{nome} (AUC {metricas[chave]['auc']:.3f})")
    ax.plot([0, 1], [0, 1], color="#E5E7EB", linestyle="--")
    ax.set_xlabel("Falsos positivos")
    ax.set_ylabel("Verdadeiros positivos")
    ax.set_title("Curva ROC: lembrar do assunto")
    ax.legend(loc="lower right", frameon=False)
    fig.tight_layout()
    fig.savefig(PASTA / "roc.png", dpi=150)
    plt.close(fig)

    fig, ax = plt.subplots(figsize=(5, 4.4))
    for p, nome, cor in [
        (p_modelo, "Regressão logística", INDIGO),
        (p_fixa, "Fórmula fixa", CINZA),
    ]:
        real, previsto = calibration_curve(y, p, n_bins=10, strategy="quantile")
        ax.plot(previsto, real, marker="o", color=cor, linewidth=2, label=nome)
    ax.plot([0, 1], [0, 1], color="#E5E7EB", linestyle="--")
    ax.set_xlabel("Probabilidade prevista")
    ax.set_ylabel("Frequência observada")
    ax.set_title("Calibração")
    ax.legend(loc="upper left", frameon=False)
    fig.tight_layout()
    fig.savefig(PASTA / "calibracao.png", dpi=150)
    plt.close(fig)


def treinar_dificuldades():
    d = ler_csv("respostas.csv")
    alunos, ia = np.unique(d["id_aluno"], return_inverse=True)
    questoes, iq = np.unique(d["id_questao"], return_inverse=True)
    n = len(ia)
    linhas = np.arange(n)
    X = sparse.hstack(
        [
            sparse.csr_matrix((np.ones(n), (linhas, ia)), shape=(n, len(alunos))),
            sparse.csr_matrix((np.ones(n), (linhas, iq)), shape=(n, len(questoes))),
        ]
    ).tocsr()
    modelo = LogisticRegression(C=10, max_iter=2000, fit_intercept=False)
    modelo.fit(X, d["acertou"].astype(int))

    # O coeficiente da questão é a facilidade; b é o oposto, centrado em zero.
    b = -modelo.coef_[0][len(alunos):]
    b = b - b.mean()
    dificuldades = {str(int(q)): round(float(v), 4) for q, v in zip(questoes, b)}
    json.dump(dificuldades, open(MODELOS / "dificuldades.json", "w"), indent=2)

    reais = json.loads((DADOS / "dificuldades_reais.json").read_text())
    real = np.array([reais[str(int(q))] for q in questoes])
    return float(np.corrcoef(b, real)[0, 1]), n, len(questoes)


def main():
    MODELOS.mkdir(parents=True, exist_ok=True)
    metricas, eventos, teste = treinar_esquecimento()
    correlacao, respostas, questoes = treinar_dificuldades()
    m, f = metricas["modelo"], metricas["fixa"]
    relatorio = f"""# Relatório dos modelos

Dados **simulados** por `gerar_dataset.py`: 500 alunos fictícios. As métricas
medem o quanto o modelo recupera a simulação, não o desempenho com alunos reais.

## Esquecimento

Regressão logística com `log1p(dias)`, `qtd_revisoes`, `dificuldade` e
`taxa_acerto_aluno`. {eventos} eventos, {teste} no teste, separados por aluno.

| Modelo | AUC | Acurácia | Brier |
|---|---|---:|---:|
| Regressão logística | {m['auc']:.3f} | {m['acuracia']:.3f} | {m['brier']:.3f} |
| Fórmula fixa `exp(-dias / (1 + qtd_revisoes))` | {f['auc']:.3f} | {f['acuracia']:.3f} | {f['brier']:.3f} |

![Curva ROC](roc.png)

![Calibração](calibracao.png)

## Proficiência

Dificuldade `b` de {questoes} questões, por regressão logística com one-hot de
aluno e de questão, sobre {respostas} respostas. Correlação entre o `b` estimado
e o `b` usado na simulação: **{correlacao:.3f}**.
"""
    (PASTA / "relatorio.md").write_text(relatorio)
    print(relatorio)


if __name__ == "__main__":
    main()
