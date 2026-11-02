# Relatório dos modelos

Dados **simulados** por `gerar_dataset.py`: 500 alunos fictícios. As métricas
medem o quanto o modelo recupera a simulação, não o desempenho com alunos reais.

## Esquecimento

Regressão logística com `log1p(dias)`, `qtd_revisoes`, `dificuldade` e
`taxa_acerto_aluno`. 21018 eventos, 4168 no teste, separados por aluno.

| Modelo | AUC | Acurácia | Brier |
|---|---|---:|---:|
| Regressão logística | 0.799 | 0.761 | 0.158 |
| Fórmula fixa `exp(-dias / (1 + qtd_revisoes))` | 0.749 | 0.727 | 0.188 |

![Curva ROC](roc.png)

![Calibração](calibracao.png)

## Proficiência

Dificuldade `b` de 410 questões, por regressão logística com one-hot de
aluno e de questão, sobre 30000 respostas. Correlação entre o `b` estimado
e o `b` usado na simulação: **0.817**.
