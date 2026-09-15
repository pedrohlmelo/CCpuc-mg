"""Gera o PDF da Lista 3 a partir das tabelas/figuras do notebook e dos textos em textos_pdf.json."""
import json

import pandas as pd
from reportlab.platypus import KeepTogether, PageBreak, Spacer

from pdf_estilo import LARGURA, bullets, caixa, figura, gerar, p, tabela

T = json.load(open('textos_pdf.json', encoding='utf-8'))
ABREV = {'KNN Imputer': 'KNN', 'Sem balanceamento': 'Sem bal.', 'RandomUnderSampler': 'RUS',
         'Random Search': 'Random', 'Bayesiana (Optuna)': 'Optuna',
         'Árvore de Decisão': 'AD', 'Random Forest': 'RF'}


def br(x, d=3):
    if isinstance(x, str):
        return x
    if pd.isna(x):
        return '—'
    return f'{x:.{d}f}'.replace('.', ',')


def ab(x):
    return ABREV.get(x, x)


def blocos(chave):
    out = []
    for par in T[chave]:
        out += bullets([par[2:]]) if par.startswith('• ') else [p(par)]
    return out


h = []
# --- capa / link --------------------------------------------------------------
h += [p('Lista 3', 'titulo'), p('Pedro Henrique Lopes de Melo', 'subtitulo'),
      p('Ciência da Computação — Inteligência Artificial', 'subtitulo'), Spacer(1, 10)]
h += [p('Link para o código desenvolvido', 'h2')]
h += [p('Notebook <font face="Courier">Lista3_IA_Titanic_AD_RF.ipynb</font> (Google Colab, acesso liberado para '
        'qualquer pessoa com o link):')]
link = T.get('link_colab', '')
h += bullets([f'<link href="{link}" color="blue"><u>{link}</u></link>' if link else
              '<font color="red">[LINK DO COLAB A INSERIR]</font>'])
h += blocos('intro')

# --- 1.a imputação --------------------------------------------------------------
h += [p('Questão 01 — Padrão de sobrevivência no TITANIC', 'h1'), p('1.a) Imputação de dados ausentes', 'h2')]
h += blocos('imputacao_metodo')
imp = pd.read_csv('tabelas/imputacao.csv', index_col=0)
metodos = ['Original (observado)', 'KNN Imputer', 'MissForest', 'Mediana por título (Lista 2)']
linhas_imp = [
    ('Média / desvio padrão', lambda r: f"{br(r['Média'], 2)} / {br(r['Desvio'], 2)}"),
    ('Q1 / mediana / Q3', lambda r: f"{br(r['Q1'], 1)} / {br(r['Mediana'], 1)} / {br(r['Q3'], 1)}"),
    ('Assimetria', lambda r: br(r['Assimetria'])),
    ('Média / desvio só dos imputados', lambda r: f"{br(r['Média (só imputados)'], 2)} / {br(r['Desvio (só imputados)'], 2)}"),
    ('KS vs. original (p-valor)', lambda r: f"{br(r['KS'])} ({br(r['p-valor KS'])})"),
    ('Distância de Wasserstein', lambda r: br(r['Wasserstein'])),
    ('corr(age, pclass) / corr(age, parch)', lambda r: f"{br(r['corr(age, pclass)'])} / {br(r['corr(age, parch)'])}"),
    ('MAE mascarado (± desvio)', lambda r: f"{br(r['MAE mascarado'], 2)} (± {br(r['desvio MAE'], 2)})" if pd.notna(r['MAE mascarado']) else '—'),
    ('RMSE mascarado', lambda r: br(r['RMSE mascarado'], 2)),
    ('Tempo de ajuste + transformação (s)', lambda r: br(r['Tempo (s)'], 2)),
]
h += [KeepTogether([
    tabela(['Atributo age (treino)'] + ['Original (observado)', 'KNN Imputer', 'MissForest', 'Mediana/título (Lista 2)'],
           [[nome] + [f(imp.loc[m]) for m in metodos] for nome, f in linhas_imp], larguras=[2.3, 1.5, 1.5, 1.5, 1.5]),
    p('Tabela 1 — Comparação dos métodos de imputação sobre a distribuição de age (conjunto de treino, 742 observadas '
      'e 174 imputadas).', 'legenda')])]
h += [figura('figuras/imputacao_distribuicao.png',
             'Figura 1 — Distribuição de age antes × depois da imputação, valores imputados e idades imputadas por título.')]
h += blocos('imputacao')

# --- 1.b balanceamento ----------------------------------------------------------
h += [p('1.b) Balanceamento de classes', 'h2')]
h += blocos('balanceamento_metodo')
bal = pd.read_csv('tabelas/balanceamento.csv')
bal = bal[bal['Imputação'] == 'MissForest']
h += [KeepTogether([tabela(['Conjunto / técnica', 'Não sobreviveu (0)', 'Sobreviveu (1)', 'Total', '% sobreviveu', 'Razão 0:1'],
                           [[r['Conjunto / técnica'], r['Não sobreviveu (0)'], r['Sobreviveu (1)'], r['Total'],
                             br(r['% sobreviveu'], 1) + '%', br(r['Razão 0:1'], 2)] for _, r in bal.iterrows()],
                           larguras=[2.6, 1.2, 1.2, 0.8, 1, 0.9]),
                    p('Tabela 2 — Distribuição das classes antes e depois de cada técnica (as contagens são idênticas '
                      'com KNN Imputer).', 'legenda')])]
h += blocos('balanceamento')

# --- 2 / 3 hiperparâmetros ------------------------------------------------------
h += [p('2. Árvore de Decisão e 3. Random Forest — otimização de hiperparâmetros', 'h2')]
h += blocos('protocolo')
hip = pd.read_csv('tabelas/hiperparametros.csv')
cab = ['Mod.', 'Imputação', 'Balanc.', 'Otimiz.', 'criterion', 'depth', 'split', 'leaf', 'n_est.', 'max_feat.',
       'CV F1-macro', 'Tempo (s)']
linhas = []
for _, r in hip.iterrows():
    linhas.append([ab(r['Modelo']), ab(r['Imputação']), ab(r['Balanceamento']), ab(r['Otimizador']),
                   r.get('criterion') if pd.notna(r.get('criterion')) else '—',
                   int(r['max_depth']), int(r['min_samples_split']), int(r['min_samples_leaf']),
                   int(r['n_estimators']) if pd.notna(r.get('n_estimators')) else '—',
                   (r['max_features'] if pd.notna(r['max_features']) else 'None') if r['Modelo'] == 'Random Forest' else '—',
                   br(r['CV F1-macro'], 4), br(r['Tempo (s)'], 1)])
h += [KeepTogether([tabela(cab, linhas, larguras=[0.55, 1.05, 1.05, 0.85, 0.85, 0.6, 0.55, 0.55, 0.6, 0.8, 0.85, 0.7], fonte=7),
      p('Tabela 3 — Hiperparâmetros encontrados pelos dois otimizadores para os dois modelos (itens 2.c e 3.c). '
        'depth = max_depth, split = min_samples_split, leaf = min_samples_leaf, n_est. = n_estimators, '
        'max_feat. = max_features; RUS = RandomUnderSampler; CV F1-macro = melhor média na validação cruzada '
        'de 5 folds; o tempo inclui o re-treino do melhor modelo.', 'legenda')])]
h += blocos('hiperparametros')

# --- 2.d regras -----------------------------------------------------------------
h += [p('2.d) Regras da Árvore de Decisão otimizada', 'h2')]
h += blocos('regras_intro')
h += [figura('figuras/arvore_otimizada.png', 'Figura 2 — Árvore de Decisão otimizada (plot_tree).')]
reg = pd.read_csv('tabelas/regras_ad.csv', index_col=0)
h += [tabela(['', 'Regra (antecedente)', 'Classe', 'Cobertura treino', 'Confiança treino', 'Cobertura teste', 'Confiança teste'],
             [[i, r['Regra'][3:], r['Classe'], br(100 * r['Cobertura (treino)'], 1) + '%',
               br(100 * r['Confiança (treino)'], 1) + '%' if pd.notna(r['Confiança (treino)']) else '—',
               br(100 * r['Cobertura (teste)'], 1) + '%',
               br(100 * r['Confiança (teste)'], 1) + '%' if pd.notna(r['Confiança (teste)']) else '—']
              for i, r in reg.iterrows()], larguras=[0.35, 3.35, 1.3, 0.75, 0.75, 0.75, 0.75], fonte=7),
      p('Tabela 4 — Regras extraídas (uma por folha), com cobertura e confiança no treino original e no teste.', 'legenda')]
h += blocos('regras')

# --- 4 avaliação ----------------------------------------------------------------
h += [p('4. Avaliação e comparação dos resultados', 'h1'), p('4.a) Métricas de desempenho', 'h2')]
h += blocos('4a_intro')
h += [figura('figuras/metricas_modelos.png', 'Figura 3 — F1-macro no teste por combinação, AD × RF.')]
met = pd.read_csv('tabelas/metricas.csv')
h += [KeepTogether([tabela(['Mod.', 'Imputação', 'Balanc.', 'Otimiz.', 'CV F1-macro', 'Acurácia treino', 'Acurácia teste',
              'Precisão (1)', 'Recall (1)', 'F1 (1)', 'F1-macro'],
             [[ab(r['Modelo']), ab(r['Imputação']), ab(r['Balanceamento']), ab(r['Otimizador']), br(r['CV F1-macro']),
               br(r['Acurácia treino']), br(r['Acurácia']), br(r['Precisão']), br(r['Recall']), br(r['F1']), br(r['F1-macro'])]
              for _, r in met.iterrows()], larguras=[0.55, 1.05, 1.05, 0.85, 0.85, 0.85, 0.85, 0.85, 0.75, 0.7, 0.8], fonte=7),
      p('Tabela 5 — Métricas no conjunto de teste (393 passageiros) para cada combinação. Precisão, recall e F1 da '
        'classe sobreviveu (1), a minoritária.', 'legenda')])]
for chave, titulo, figs in [
        ('4b', '4.b) Árvore de Decisão × Random Forest', [('figuras/matrizes_confusao.png', 'Figura 4 — Matrizes de confusão (teste) da melhor AD e da melhor RF.', 0.75)]),
        ('4c', '4.c) Random Search × Otimização Bayesiana (Optuna)', [('figuras/convergencia.png', 'Figura 5 — Convergência das buscas: melhor CV F1-macro até cada iteração.', 1.0)]),
        ('4d', '4.d) KNN Imputer × MissForest', []),
        ('4e', '4.e) SMOTE-NC × RandomUnderSampler', [('figuras/precisao_recall.png', 'Figura 6 — Precisão × recall da classe sobreviveu para os 24 modelos.', 0.62)]),
        ('4f', '4.f) Interpretabilidade: Árvore de Decisão × Random Forest', [('figuras/importancias.png', 'Figura 7 — Importância dos atributos na AD e na RF.', 0.62)])]:
    h += [p(titulo, 'h2')] + blocos(chave)
    extra = f'{chave}_tabela'
    if extra in T:
        d = T[extra]
        h += [KeepTogether([tabela(d['cabecalho'], d['linhas'], larguras=d.get('larguras')), p(d['legenda'], 'legenda')])]
    if f'{chave}_pos' in T:
        h += blocos(f'{chave}_pos')
    for arq, leg, frac in figs:
        h += [figura(arq, leg, largura=LARGURA * frac)]

h += [p('Conclusão', 'h1')] + blocos('conclusao')
if 'destaque' in T:
    h += [Spacer(1, 4), caixa(T['destaque'])]

gerar('Lista3_IA_Pedro_Henrique.pdf', h)
print('PDF gerado')
