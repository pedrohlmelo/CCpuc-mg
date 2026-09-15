"""Gera o notebook da Lista 3 (Titanic: imputação, balanceamento, AD e RF otimizadas)."""
import json
import os
import nbformat as nbf

AQUI = os.path.dirname(os.path.abspath(__file__))
ANALISES = {}
if os.path.exists(os.path.join(AQUI, 'analises.json')):
    ANALISES = json.load(open(os.path.join(AQUI, 'analises.json'), encoding='utf-8'))

cells = []


def md(s):
    cells.append(nbf.v4.new_markdown_cell(s.strip('\n')))


def code(s):
    cells.append(nbf.v4.new_code_cell(s.strip('\n')))


def analise(chave):
    md(ANALISES.get(chave, f'_(análise `{chave}` preenchida após a execução)_'))


# ---------------------------------------------------------------------------
md(r"""
# Lista 3 — Padrão de sobrevivência no TITANIC
**Pedro Henrique Lopes de Melo** — Ciência da Computação — Inteligência Artificial — Profa. Cristiane Neri Nobre

Continuação da Questão 03 da Lista 2: mesma base (`titanic completo.csv`, 1.309 passageiros), mesma codificação de atributos e mesmo holdout estratificado 70/30 com `random_state = 23`. Etapas:

1. **Pré-processamento** — imputação (KNN Imputer × MissForest) e balanceamento (SMOTE, na versão SMOTE-NC, × RandomUnderSampler), sempre ajustados só no treino;
2. **Árvore de Decisão** — otimização com Random Search e Otimização Bayesiana (Optuna/TPE) e extração das regras;
3. **Random Forest** — mesmos dois otimizadores;
4. **Avaliação e comparação** — métricas no conjunto de teste para todas as combinações.

> **Colab:** ao executar a célula de leitura, envie o arquivo `titanic completo.csv` (disponível no CANVAS). A execução completa leva alguns minutos, pois são 24 buscas de hiperparâmetros.
""")

code(r"""
# Dependências que não vêm instaladas por padrão no Colab
import importlib.util, subprocess, sys
for pacote, modulo in [('optuna', 'optuna'), ('imbalanced-learn', 'imblearn')]:
    if importlib.util.find_spec(modulo) is None:
        subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-q', pacote])
""")

md("## 0. Bibliotecas, leitura e codificação da base")

code(r"""
import os, re, time, warnings
os.environ['PYTHONWARNINGS'] = 'ignore'   # também silencia os processos paralelos
warnings.filterwarnings('ignore')

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats

import sklearn
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.experimental import enable_iterative_imputer  # noqa: F401
from sklearn.impute import KNNImputer, IterativeImputer
from sklearn.preprocessing import MinMaxScaler
from sklearn.tree import DecisionTreeClassifier, export_text, plot_tree
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.model_selection import train_test_split, StratifiedKFold, RandomizedSearchCV, cross_val_score
from sklearn.metrics import (accuracy_score, precision_score, recall_score, f1_score,
                             confusion_matrix, ConfusionMatrixDisplay)

import imblearn
from imblearn.over_sampling import SMOTE, SMOTENC
from imblearn.under_sampling import RandomUnderSampler
from imblearn.pipeline import Pipeline as ImbPipeline

import optuna
from optuna.samplers import TPESampler
optuna.logging.set_verbosity(optuna.logging.WARNING)

pd.set_option('display.max_columns', 50)
pd.set_option('display.width', 220)
sns.set_theme(style='whitegrid')

SEED = 23
N_JOBS = 4   # processos paralelos (4 para caber na memória de máquinas com 8 GB)
os.makedirs('figuras', exist_ok=True)
os.makedirs('tabelas', exist_ok=True)

def salvar_fig(nome):
    plt.savefig(f'figuras/{nome}.png', dpi=150, bbox_inches='tight')

print('scikit-learn', sklearn.__version__, '| imbalanced-learn', imblearn.__version__,
      '| optuna', optuna.__version__, '| núcleos de CPU:', os.cpu_count())
""")

code(r"""
ARQUIVO = 'titanic completo.csv'
if not os.path.exists(ARQUIVO):
    from google.colab import files          # só existe no Colab
    print('Envie o arquivo "titanic completo.csv" (base do CANVAS):')
    ARQUIVO = next(iter(files.upload()))

base = pd.read_csv(ARQUIVO)
print(base.shape)
ausentes = (base.isnull().mean() * 100).round(1)
print('\n% de valores ausentes:')
print(ausentes[ausentes > 0].sort_values(ascending=False))
print('\nDistribuição da classe survived:')
print(base['survived'].value_counts(normalize=True).round(3))
""")

md(r"""
**Codificação (herdada da Lista 2).** `boat`, `body` e `home.dest` são removidos por vazamento de dados (informação posterior ao naufrágio) e `ticket` por não ter semântica. Do nome sai o `titulo`; `cabin` vira o indicador `tem_cabine`; `sex` vira `sexo` (0 = feminino, 1 = masculino); `tam_familia` e `sozinho` são derivados de `sibsp` e `parch`; `titulo` recebe one-hot.

A diferença em relação à Lista 2 está na imputação: lá `age` era preenchida pela mediana por título, `fare` pela mediana por classe e `embarked` pela moda. Agora os valores ausentes são **mantidos como NaN** para serem imputados pelo KNN Imputer e pelo MissForest. `embarked` entra na imputação como código numérico (S = 0, C = 1, Q = 2) e só depois recebe one-hot.
""")

code(r"""
def extrai_titulo(nome):
    t = re.search(r',\s*([^\.]*)\.', nome).group(1).strip()
    if t == 'Mr': return 'Mr'
    if t in ('Mrs', 'Mme', 'Lady', 'the Countess', 'Dona'): return 'Mrs'
    if t in ('Miss', 'Ms', 'Mlle'): return 'Miss'
    if t == 'Master': return 'Master'
    return 'Outros'

df = base.drop(columns=['boat', 'body', 'home.dest', 'ticket'])
df['titulo'] = df['name'].apply(extrai_titulo)
df['tem_cabine'] = df['cabin'].notnull().astype(int)
df['tam_familia'] = df['sibsp'] + df['parch'] + 1
df['sozinho'] = (df['tam_familia'] == 1).astype(int)
df['sexo'] = (df['sex'] == 'male').astype(int)
df['embarque'] = df['embarked'].map({'S': 0, 'C': 1, 'Q': 2})     # NaN preservado

ATRIBUTOS = ['pclass', 'sexo', 'age', 'sibsp', 'parch', 'fare', 'embarque',
             'tem_cabine', 'tam_familia', 'sozinho']
X = pd.concat([df[ATRIBUTOS], pd.get_dummies(df['titulo'], prefix='titulo', dtype=int)], axis=1)
y = df['survived']

# Holdout estratificado 70/30 — o conjunto de teste nunca participa de imputação, balanceamento ou otimização
X_treino, X_teste, y_treino, y_teste = train_test_split(
    X, y, test_size=0.30, random_state=SEED, stratify=y)
print('treino:', X_treino.shape, '| teste:', X_teste.shape)
pd.DataFrame({'ausentes treino': X_treino.isnull().sum(),
              'ausentes teste': X_teste.isnull().sum()}).query('`ausentes treino` + `ausentes teste` > 0')
""")

# ---------------------------------------------------------------------------
md(r"""
## 1. Pré-processamento
### 1.a) Imputação de dados ausentes: KNN Imputer × MissForest

Atributos com ausentes: `age` (20,1%), `embarked` (2 registros) e `fare` (1 registro). Ambos os imputadores são **ajustados apenas no treino** e depois aplicados a treino e teste.

* **KNN Imputer** (`KNNImputer`, k = 5): preenche com a média dos 5 passageiros mais parecidos. Os atributos são escalados para [0, 1] antes do cálculo de distância e revertidos depois; sem isso `fare` (0 a 512) dominaria a distância.
* **MissForest** (`IterativeImputer` com `RandomForestRegressor`, 100 árvores, até 10 iterações): cada atributo com ausentes é modelado por uma floresta a partir dos demais, repetindo até convergir. A biblioteca `missingpy` não é compatível com as versões atuais do scikit-learn, por isso foi usada a alternativa indicada no enunciado.
* **Mediana por título** (método da Lista 2): entra apenas como referência.
""")

code(r"""
class ImputadorKNN(BaseEstimator, TransformerMixin):
    def __init__(self, n_neighbors=5):
        self.n_neighbors = n_neighbors
    def fit(self, X, y=None):
        self.escala_ = MinMaxScaler().fit(X)                       # ignora NaN no ajuste
        self.knn_ = KNNImputer(n_neighbors=self.n_neighbors).fit(self.escala_.transform(X))
        return self
    def transform(self, X):
        Z = self.knn_.transform(self.escala_.transform(X))
        return pd.DataFrame(self.escala_.inverse_transform(Z), columns=X.columns, index=X.index)

class ImputadorMissForest(BaseEstimator, TransformerMixin):
    def __init__(self, n_estimators=100, max_iter=10):
        self.n_estimators = n_estimators
        self.max_iter = max_iter
    def fit(self, X, y=None):
        floresta = RandomForestRegressor(n_estimators=self.n_estimators, n_jobs=N_JOBS, random_state=SEED)
        self.imp_ = IterativeImputer(estimator=floresta, max_iter=self.max_iter,
                                     initial_strategy='median', random_state=SEED).fit(X)
        return self
    def transform(self, X):
        return pd.DataFrame(self.imp_.transform(X), columns=X.columns, index=X.index)

class ImputadorMedianaTitulo(BaseEstimator, TransformerMixin):
    # Referência: estratégia usada na Lista 2
    def fit(self, X, y=None):
        titulo = X.filter(like='titulo_').idxmax(axis=1)
        self.idade_ = X['age'].groupby(titulo).median()
        self.tarifa_ = X['fare'].groupby(X['pclass']).median()
        self.embarque_ = X['embarque'].mode()[0]
        return self
    def transform(self, X):
        X = X.copy()
        titulo = X.filter(like='titulo_').idxmax(axis=1)
        X['age'] = X['age'].fillna(titulo.map(self.idade_))
        X['fare'] = X['fare'].fillna(X['pclass'].map(self.tarifa_))
        X['embarque'] = X['embarque'].fillna(self.embarque_)
        return X

TITULOS = ['Master', 'Miss', 'Mr', 'Mrs', 'Outros']
PORTOS = ['S', 'C', 'Q']

def finalizar(D):
    # embarque imputado vira categoria válida (arredonda); título volta a ser uma coluna com código.
    # O one-hot é feito DEPOIS do balanceamento (dentro do pipeline), para o SMOTE-NC tratar cada
    # atributo nominal como uma única variável categórica.
    D = D.copy()
    D['embarque'] = D['embarque'].round().clip(0, 2).astype(int)
    D['titulo'] = D[[f'titulo_{t}' for t in TITULOS]].values.argmax(axis=1)
    return D.drop(columns=[f'titulo_{t}' for t in TITULOS])

class CodificadorOneHot(BaseEstimator, TransformerMixin):
    # one-hot de titulo e embarque com categorias fixas (mesmas colunas em treino, teste e folds)
    def fit(self, X, y=None):
        return self
    def transform(self, X):
        X = X.copy()
        for coluna, categorias, prefixo in [('titulo', TITULOS, 'titulo'), ('embarque', PORTOS, 'embarked')]:
            codigos = X.pop(coluna).round().astype(int)
            for codigo, nome in enumerate(categorias):
                X[f'{prefixo}_{nome}'] = (codigos == codigo).astype(int)
        return X

IMPUTADORES = {'KNN Imputer': ImputadorKNN, 'MissForest': ImputadorMissForest}
dados, tempo_imputacao = {}, {}
for nome, Classe in IMPUTADORES.items():
    t0 = time.perf_counter()
    imp = Classe().fit(X_treino)
    bruto_tr, bruto_te = imp.transform(X_treino), imp.transform(X_teste)
    tempo_imputacao[nome] = time.perf_counter() - t0
    dados[nome] = {'bruto_treino': bruto_tr, 'bruto_teste': bruto_te,
                   'treino': finalizar(bruto_tr), 'teste': finalizar(bruto_te)}
    print(f'{nome}: {tempo_imputacao[nome]:.2f} s')

referencia = ImputadorMedianaTitulo().fit(X_treino)
bruto_ref = referencia.transform(X_treino)
""")

code(r"""
# Valores imputados para os poucos ausentes de fare e embarked
linhas = []
for split, Xo in [('treino', X_treino), ('teste', X_teste)]:
    for col in ['fare', 'embarque']:
        for idx in Xo.index[Xo[col].isna()]:
            linha = {'conjunto': split, 'atributo': 'embarked' if col == 'embarque' else col,
                     'passageiro': base.loc[idx, 'name'], 'pclass': Xo.loc[idx, 'pclass']}
            for nome in IMPUTADORES:
                v = dados[nome]['bruto_' + split].loc[idx, col]
                linha[nome] = f'{v:.2f}' if col == 'fare' else f'{PORTOS[int(np.clip(round(v), 0, 2))]} ({v:.2f})'
            linhas.append(linha)
pd.DataFrame(linhas)
""")

md(r"""
**Efeito sobre a distribuição de `age`.** `age` concentra 263 dos 266 ausentes, então é nela que a escolha do método pesa. A comparação é feita no treino entre as idades observadas (antes da imputação) e a coluna completa depois da imputação, usando:

* estatísticas descritivas: média, desvio padrão, quartis e assimetria;
* teste de Kolmogorov-Smirnov (KS) e distância de Wasserstein em relação à distribuição original: quanto menor, mais preservada;
* correlação de `age` com `pclass` e `parch`, para ver se a relação com os outros atributos se mantém;
* **erro de imputação mascarado**: 20% das idades conhecidas são escondidas e imputadas, e o MAE/RMSE mede o quanto cada método acerta o valor real (3 repetições).
""")

code(r"""
ausente_idade = X_treino['age'].isna()
original = X_treino.loc[~ausente_idade, 'age']

def resumo_idade(nome, serie):
    imputados = serie[ausente_idade] if nome != 'Original (observado)' else pd.Series(dtype=float)
    ks = stats.ks_2samp(original, serie)
    return {'Método': nome, 'n': len(serie), 'Média': serie.mean(), 'Desvio': serie.std(),
            'Q1': serie.quantile(.25), 'Mediana': serie.median(), 'Q3': serie.quantile(.75),
            'Assimetria': serie.skew(),
            'Média (só imputados)': imputados.mean(), 'Desvio (só imputados)': imputados.std(),
            'KS': ks.statistic, 'p-valor KS': ks.pvalue,
            'Wasserstein': stats.wasserstein_distance(original, serie),
            'corr(age, pclass)': serie.corr(X_treino.loc[serie.index, 'pclass']),
            'corr(age, parch)': serie.corr(X_treino.loc[serie.index, 'parch'])}

def erro_mascarado(Classe, repeticoes=3, fracao=0.20):
    conhecidos = X_treino.index[~ausente_idade]
    mae, rmse = [], []
    for rep in range(repeticoes):
        ocultos = np.random.RandomState(SEED + rep).choice(conhecidos, int(fracao * len(conhecidos)), replace=False)
        Xm = X_treino.copy()
        Xm.loc[ocultos, 'age'] = np.nan
        erro = Classe().fit(Xm).transform(Xm).loc[ocultos, 'age'] - X_treino.loc[ocultos, 'age']
        mae.append(erro.abs().mean())
        rmse.append(np.sqrt((erro ** 2).mean()))
    return np.mean(mae), np.std(mae), np.mean(rmse)

series = {'Original (observado)': original,
          'KNN Imputer': dados['KNN Imputer']['bruto_treino']['age'],
          'MissForest': dados['MissForest']['bruto_treino']['age'],
          'Mediana por título (Lista 2)': bruto_ref['age']}
tabela_imputacao = pd.DataFrame([resumo_idade(n, s) for n, s in series.items()]).set_index('Método')

classes_imp = {'KNN Imputer': ImputadorKNN, 'MissForest': ImputadorMissForest,
               'Mediana por título (Lista 2)': ImputadorMedianaTitulo}
for nome, Classe in classes_imp.items():
    m, d, r = erro_mascarado(Classe)
    tabela_imputacao.loc[nome, ['MAE mascarado', 'desvio MAE', 'RMSE mascarado']] = [m, d, r]
tabela_imputacao.loc['KNN Imputer', 'Tempo (s)'] = tempo_imputacao['KNN Imputer']
tabela_imputacao.loc['MissForest', 'Tempo (s)'] = tempo_imputacao['MissForest']

tabela_imputacao.to_csv('tabelas/imputacao.csv')
tabela_imputacao.round(3).T
""")

code(r"""
fig, ax = plt.subplots(1, 3, figsize=(18, 4.8))
cores = {'Original (observado)': 'black', 'KNN Imputer': '#1f77b4', 'MissForest': '#2ca02c',
         'Mediana por título (Lista 2)': '#d62728'}
for nome, serie in series.items():
    sns.kdeplot(serie, ax=ax[0], label=nome, color=cores[nome], lw=2.2 if nome.startswith('Orig') else 1.6,
                ls='--' if nome.startswith('Mediana') else '-')
ax[0].set_title('Distribuição de age: antes × depois da imputação'); ax[0].set_xlabel('idade'); ax[0].legend(fontsize=8)

for nome in ['KNN Imputer', 'MissForest', 'Mediana por título (Lista 2)']:
    ax[1].hist(series[nome][ausente_idade], bins=np.arange(0, 66, 3), alpha=.5, label=nome, color=cores[nome])
ax[1].set_title(f'Somente os {ausente_idade.sum()} valores imputados'); ax[1].set_xlabel('idade'); ax[1].legend(fontsize=8)

titulo_treino = X_treino.filter(like='titulo_').idxmax(axis=1).str.replace('titulo_', '')
caixa = pd.concat([pd.DataFrame({'idade': series[n][ausente_idade], 'título': titulo_treino[ausente_idade], 'método': n})
                   for n in ['KNN Imputer', 'MissForest']] +
                  [pd.DataFrame({'idade': original, 'título': titulo_treino[~ausente_idade], 'método': 'Original (observado)'})])
sns.boxplot(data=caixa, x='título', y='idade', hue='método', ax=ax[2],
            palette={k: cores[k] for k in ['Original (observado)', 'KNN Imputer', 'MissForest']},
            order=['Master', 'Miss', 'Mr', 'Mrs', 'Outros'], fliersize=2)
ax[2].set_title('Idades imputadas por título × idades observadas'); ax[2].legend(fontsize=8)
plt.tight_layout(); salvar_fig('imputacao_distribuicao'); plt.show()
""")

analise('imputacao')

code(r"""
IMPUTACAO_ESCOLHIDA = 'MissForest'
""")

# ---------------------------------------------------------------------------
md(r"""
### 1.b) Balanceamento de classes: SMOTE (SMOTE-NC) × RandomUnderSampler

No treino, 61,8% dos passageiros não sobreviveram e 38,2% sobreviveram (razão de 1,62 : 1). É um desbalanceamento moderado, com a classe **sobreviveu (1)** como minoritária. Foram comparados:

* **SMOTE**: cria exemplos sintéticos da classe minoritária interpolando cada exemplo com seus vizinhos mais próximos (k = 5) até igualar as classes. O SMOTE clássico interpola *todos* os atributos, e metade da base é binária ou nominal (`sexo`, `tem_cabine`, `sozinho`, `pclass`, `titulo`, `embarque`). Ele gera passageiros com `sexo = 0,37` ou `pclass = 2,6`, e a árvore passa a criar cortes como `sexo <= 0,996`, que só separam exemplos sintéticos (demonstrado abaixo). Por isso foi usado o **SMOTE-NC** (`SMOTENC`), a versão do SMOTE para dados mistos definida no próprio artigo original (Chawla et al., 2002, seção 6.1): interpola os atributos contínuos e, nos categóricos, usa o valor mais frequente entre os vizinhos. Por isso o one-hot de `titulo` e `embarque` é aplicado depois do balanceamento;
* **RandomUnderSampler**: descarta aleatoriamente exemplos da classe majoritária até igualar as classes;
* **Sem balanceamento**: referência para medir se balancear ajuda.

O balanceamento só é aplicado ao treino. Nas buscas de hiperparâmetros ele fica **dentro** de um `imblearn.Pipeline`, então em cada fold da validação cruzada só a parte de treino do fold é reamostrada e a parte de validação mantém a distribuição real. O conjunto de teste nunca é reamostrado.
""")

code(r"""
CATEGORICAS = ['pclass', 'sexo', 'embarque', 'tem_cabine', 'sozinho', 'titulo']
AMOSTRADORES = {'Sem balanceamento': None,
                'SMOTE-NC': lambda: SMOTENC(categorical_features=CATEGORICAS, random_state=SEED),
                'RandomUnderSampler': lambda: RandomUnderSampler(random_state=SEED)}

def contagem(nome, yb, imp):
    c = pd.Series(yb).value_counts().sort_index()
    return {'Imputação': imp, 'Conjunto / técnica': nome, 'Não sobreviveu (0)': c[0], 'Sobreviveu (1)': c[1],
            'Total': len(yb), '% sobreviveu': round(100 * c[1] / len(yb), 1), 'Razão 0:1': round(c[0] / c[1], 2)}

linhas = []
for imp in IMPUTADORES:
    Xtr = dados[imp]['treino']
    linhas.append(contagem('Treino — antes (original)', y_treino, imp))
    for nome in ['SMOTE-NC', 'RandomUnderSampler']:
        _, yb = AMOSTRADORES[nome]().fit_resample(Xtr, y_treino)
        linhas.append(contagem(f'Treino — depois do {nome}', yb, imp))
    linhas.append(contagem('Teste (nunca balanceado)', y_teste, imp))
tabela_balanceamento = pd.DataFrame(linhas)
tabela_balanceamento.to_csv('tabelas/balanceamento.csv', index=False)
tabela_balanceamento
""")

code(r"""
# Por que SMOTE-NC: o SMOTE clássico (sobre os dados já em one-hot) cria categorias inexistentes
Xtr = dados[IMPUTACAO_ESCOLHIDA]['treino']
Xtr_oh = CodificadorOneHot().transform(Xtr)
NOMINAIS = ['pclass', 'sexo', 'tem_cabine', 'sozinho'] + [c for c in Xtr_oh.columns if c.startswith(('titulo_', 'embarked_'))]

def invalidos(sinteticos):
    fora = sinteticos[NOMINAIS] != sinteticos[NOMINAIS].round()
    return fora.any(axis=1).mean(), fora.mean()

X_s, _ = SMOTE(random_state=SEED).fit_resample(Xtr_oh, y_treino)
X_nc, _ = AMOSTRADORES['SMOTE-NC']().fit_resample(Xtr, y_treino)
X_nc = CodificadorOneHot().transform(X_nc)
for nome, Xb in [('SMOTE clássico', X_s), ('SMOTE-NC', X_nc)]:
    linha, por_coluna = invalidos(Xb.iloc[len(Xtr):])
    print(f'{nome:15s}: {len(Xb) - len(Xtr)} sintéticos | com algum atributo nominal fracionário: {linha:.1%} '
          f'| sexo fracionário: {por_coluna["sexo"]:.1%} | pclass fracionário: {por_coluna["pclass"]:.1%}')

t = tabela_balanceamento[tabela_balanceamento['Imputação'] == IMPUTACAO_ESCOLHIDA].set_index('Conjunto / técnica')
ax = t[['Não sobreviveu (0)', 'Sobreviveu (1)']].plot(kind='bar', figsize=(9, 4), color=['#c0392b', '#27ae60'], rot=0)
for p in ax.patches:
    ax.annotate(int(p.get_height()), (p.get_x() + p.get_width() / 2, p.get_height()), ha='center', va='bottom', fontsize=8)
ax.set_xticklabels([s.replace(' — ', '\n') for s in t.index], fontsize=8)
ax.set_title('Distribuição das classes antes e depois do balanceamento'); ax.set_xlabel('')
plt.tight_layout(); salvar_fig('balanceamento'); plt.show()
""")

analise('balanceamento')

# ---------------------------------------------------------------------------
md(r"""
## 2. Árvore de Decisão
### 2.a/b) Treinamento e otimização de hiperparâmetros

Para a comparação entre otimizadores ser justa, os dois recebem as mesmas condições:

| Item | Configuração |
|---|---|
| Otimizadores | **Random Search** (`RandomizedSearchCV`) e **Otimização Bayesiana** (`Optuna`, amostrador TPE) |
| Orçamento | 50 configurações avaliadas por cada um |
| Validação | `StratifiedKFold` com 5 folds e os mesmos folds para os dois |
| Métrica otimizada | F1-macro, que pesa igualmente as duas classes, ao contrário da acurácia, que favorece a majoritária |
| Espaço (AD) | `criterion` ∈ {gini, entropy}, `max_depth` 2–15, `min_samples_split` 2–50, `min_samples_leaf` 1–30 |
| Espaço (RF) | `n_estimators` 50–300, `max_depth` 2–20, `min_samples_split` 2–30, `min_samples_leaf` 1–15, `max_features` ∈ {sqrt, log2, None} |
| Paralelismo | 4 processos em paralelo (`n_jobs = 4`) nos dois otimizadores |

Cada busca é repetida para as **6 combinações** de imputação (KNN, MissForest) × balanceamento (sem, SMOTE-NC, RandomUnderSampler). O tempo medido inclui o re-treino do melhor modelo no treino completo.
""")

code(r"""
CV = StratifiedKFold(n_splits=5, shuffle=True, random_state=SEED)
N_ITER = 50
METRICA = 'f1_macro'
MODELOS = {'Árvore de Decisão': DecisionTreeClassifier, 'Random Forest': RandomForestClassifier}

ESPACO_RANDOM = {
    'Árvore de Decisão': {'criterion': ['gini', 'entropy'], 'max_depth': stats.randint(2, 16),
                          'min_samples_split': stats.randint(2, 51), 'min_samples_leaf': stats.randint(1, 31)},
    'Random Forest': {'n_estimators': stats.randint(50, 301), 'max_depth': stats.randint(2, 21),
                      'min_samples_split': stats.randint(2, 31), 'min_samples_leaf': stats.randint(1, 16),
                      'max_features': ['sqrt', 'log2', None]},
}

def espaco_optuna(trial, modelo):
    if modelo == 'Árvore de Decisão':
        return {'criterion': trial.suggest_categorical('criterion', ['gini', 'entropy']),
                'max_depth': trial.suggest_int('max_depth', 2, 15),
                'min_samples_split': trial.suggest_int('min_samples_split', 2, 50),
                'min_samples_leaf': trial.suggest_int('min_samples_leaf', 1, 30)}
    return {'n_estimators': trial.suggest_int('n_estimators', 50, 300),
            'max_depth': trial.suggest_int('max_depth', 2, 20),
            'min_samples_split': trial.suggest_int('min_samples_split', 2, 30),
            'min_samples_leaf': trial.suggest_int('min_samples_leaf', 1, 15),
            'max_features': trial.suggest_categorical('max_features', ['sqrt', 'log2', None])}

def criar_pipeline(modelo, balanceamento, **params):
    passos = []
    if AMOSTRADORES[balanceamento] is not None:
        passos.append(('balanceamento', AMOSTRADORES[balanceamento]()))
    passos.append(('one_hot', CodificadorOneHot()))
    passos.append(('modelo', MODELOS[modelo](random_state=SEED, **params)))
    return ImbPipeline(passos)

def busca_random(modelo, Xtr, ytr, balanceamento):
    grade = {f'modelo__{k}': v for k, v in ESPACO_RANDOM[modelo].items()}
    busca = RandomizedSearchCV(criar_pipeline(modelo, balanceamento), grade, n_iter=N_ITER,
                               scoring=METRICA, cv=CV, n_jobs=N_JOBS, random_state=SEED)
    t0 = time.perf_counter()
    busca.fit(Xtr, ytr)
    tempo = time.perf_counter() - t0
    return {'params': {k.replace('modelo__', ''): v for k, v in busca.best_params_.items()},
            'cv': busca.best_score_, 'tempo': tempo, 'estimador': busca.best_estimator_,
            'historico': np.maximum.accumulate(busca.cv_results_['mean_test_score'])}

def busca_optuna(modelo, Xtr, ytr, balanceamento):
    def objetivo(trial):
        pipe = criar_pipeline(modelo, balanceamento, **espaco_optuna(trial, modelo))
        return cross_val_score(pipe, Xtr, ytr, cv=CV, scoring=METRICA, n_jobs=N_JOBS).mean()
    estudo = optuna.create_study(direction='maximize', sampler=TPESampler(seed=SEED))
    t0 = time.perf_counter()
    estudo.optimize(objetivo, n_trials=N_ITER)
    final = criar_pipeline(modelo, balanceamento, **estudo.best_params).fit(Xtr, ytr)
    tempo = time.perf_counter() - t0
    return {'params': estudo.best_params, 'cv': estudo.best_value, 'tempo': tempo, 'estimador': final,
            'historico': np.maximum.accumulate([t.value for t in estudo.trials])}

OTIMIZADORES = {'Random Search': busca_random, 'Bayesiana (Optuna)': busca_optuna}

def avaliar(estimador, Xtr, ytr, Xte, yte):
    p = estimador.predict(Xte)
    return {'Acurácia treino': accuracy_score(ytr, estimador.predict(Xtr)),
            'Acurácia': accuracy_score(yte, p), 'Precisão': precision_score(yte, p),
            'Recall': recall_score(yte, p), 'F1': f1_score(yte, p),
            'F1-macro': f1_score(yte, p, average='macro'),
            'Precisão (0)': precision_score(yte, p, pos_label=0), 'Recall (0)': recall_score(yte, p, pos_label=0)}

resultados = []
def executar_buscas(modelo):
    for imp in IMPUTADORES:
        Xtr, Xte = dados[imp]['treino'], dados[imp]['teste']
        for bal in AMOSTRADORES:
            for otim, buscar in OTIMIZADORES.items():
                r = buscar(modelo, Xtr, y_treino, bal)
                resultados.append({'Modelo': modelo, 'Imputação': imp, 'Balanceamento': bal, 'Otimizador': otim,
                                   'CV F1-macro': r['cv'], 'Tempo (s)': r['tempo'],
                                   **avaliar(r['estimador'], Xtr, y_treino, Xte, y_teste),
                                   'params': r['params'], 'estimador': r['estimador'], 'historico': r['historico']})
                print(f"{imp:11s} | {bal:18s} | {otim:18s} | CV F1-macro = {r['cv']:.4f} | "
                      f"{r['tempo']:6.1f} s | {r['params']}")

def tabela_hiperparametros(modelo):
    linhas = [{'Imputação': r['Imputação'], 'Balanceamento': r['Balanceamento'], 'Otimizador': r['Otimizador'],
               **r['params'], 'CV F1-macro': round(r['CV F1-macro'], 4), 'Tempo (s)': round(r['Tempo (s)'], 1)}
              for r in resultados if r['Modelo'] == modelo]
    return pd.DataFrame(linhas)
""")

code(r"""
# aquecimento: inicializa o pool de processos paralelos antes de cronometrar (senão a 1ª busca paga esse custo)
cross_val_score(criar_pipeline('Árvore de Decisão', 'SMOTE-NC'), dados['MissForest']['treino'], y_treino, cv=CV, n_jobs=N_JOBS)
executar_buscas('Árvore de Decisão')
""")

md("### 2.c) Melhores hiperparâmetros e tempo de busca — Árvore de Decisão")

code(r"""
hiper_ad = tabela_hiperparametros('Árvore de Decisão')
hiper_ad.to_csv('tabelas/hiperparametros_ad.csv', index=False)
hiper_ad
""")

analise('hiper_ad')

md(r"""
### 2.d) Regras da Árvore de Decisão otimizada

As regras vêm da árvore com **maior F1-macro na validação cruzada** entre as configurações que usam a imputação escolhida. A escolha pela validação cruzada, e não pelo teste, evita ajustar a decisão ao conjunto de teste. Além do `export_text` e do `plot_tree`, cada folha é convertida em uma regra SE–ENTÃO com as condições simplificadas: limites repetidos sobre o mesmo atributo são fundidos e atributos binários aparecem como categoria. A qualidade de cada regra é medida pela **cobertura**, a fração de passageiros que satisfazem a regra, e pela **confiança**, a fração desses em que a classe prevista está correta. As duas são calculadas no treino original (sem exemplos sintéticos) e no teste.
""")

code(r"""
candidatas = [r for r in resultados if r['Modelo'] == 'Árvore de Decisão' and r['Imputação'] == IMPUTACAO_ESCOLHIDA]
melhor_ad = max(candidatas, key=lambda r: r['CV F1-macro'])
arvore = melhor_ad['estimador'].named_steps['modelo']
conj_treino = CodificadorOneHot().transform(dados[IMPUTACAO_ESCOLHIDA]['treino'])
conj_teste = CodificadorOneHot().transform(dados[IMPUTACAO_ESCOLHIDA]['teste'])
nomes = list(conj_treino.columns)
print(f"Configuração: {melhor_ad['Imputação']} + {melhor_ad['Balanceamento']} + {melhor_ad['Otimizador']}")
print(f"Hiperparâmetros: {melhor_ad['params']}")
print(f"Profundidade real: {arvore.get_depth()} | folhas (= regras): {arvore.get_n_leaves()}")
print()
print(export_text(arvore, feature_names=nomes, decimals=2))
""")

code(r"""
profundidade_plot = None if arvore.get_n_leaves() <= 24 else 4
fig, ax = plt.subplots(figsize=(24, 10))
plot_tree(arvore, feature_names=nomes, class_names=['Não sobreviveu', 'Sobreviveu'], filled=True,
          impurity=False, proportion=False, fontsize=8, max_depth=profundidade_plot, ax=ax)
titulo = 'Árvore de Decisão otimizada' + ('' if profundidade_plot is None else f' (primeiros {profundidade_plot} níveis)')
ax.set_title(titulo, fontsize=14)
salvar_fig('arvore_otimizada'); plt.show()
""")

code(r"""
BINARIOS = {'sexo': ('mulher', 'homem'), 'tem_cabine': ('sem cabine', 'com cabine'), 'sozinho': ('acompanhado', 'sozinho')}
INTEIROS = {'pclass': 'classe', 'sibsp': 'sibsp', 'parch': 'parch', 'tam_familia': 'família'}
CONTINUOS = {'age': 'idade', 'fare': 'tarifa'}

def condicao(atributo, inferior, superior):
    # inferior: atributo > limite ; superior: atributo <= limite
    if atributo in BINARIOS:
        return BINARIOS[atributo][1] if inferior is not None else BINARIOS[atributo][0]
    if atributo.startswith('titulo_'):
        return f"título = {atributo[7:]}" if inferior is not None else f"título ≠ {atributo[7:]}"
    if atributo.startswith('embarked_'):
        return f"embarque = {atributo[9:]}" if inferior is not None else f"embarque ≠ {atributo[9:]}"
    if atributo in INTEIROS:
        nome = INTEIROS[atributo]
        lo = None if inferior is None else int(np.floor(inferior)) + 1
        hi = None if superior is None else int(np.floor(superior))
        if lo is not None and hi is not None:
            return f'{nome} = {lo}' if lo == hi else f'{nome} de {lo} a {hi}'
        return f'{nome} ≥ {lo}' if lo is not None else f'{nome} ≤ {hi}'
    nome = CONTINUOS.get(atributo, atributo)
    if inferior is not None and superior is not None:
        return f'{inferior:.1f} < {nome} ≤ {superior:.1f}'
    return f'{nome} > {inferior:.1f}' if inferior is not None else f'{nome} ≤ {superior:.1f}'

def extrair_regras(arvore, nomes, conjuntos):
    t = arvore.tree_
    folhas = {nome: arvore.apply(Xc) for nome, (Xc, _) in conjuntos.items()}
    regras = []
    def descer(no, limites):
        if t.children_left[no] == -1:
            classe = arvore.classes_[np.argmax(t.value[no][0])]
            regra = {'Regra': 'SE ' + ' E '.join(condicao(a, lo, hi) for a, (lo, hi) in limites.items()),
                     'Classe': 'SOBREVIVEU' if classe == 1 else 'NÃO SOBREVIVEU'}
            for nome, (Xc, yc) in conjuntos.items():
                cobre = folhas[nome] == no
                regra[f'Cobertura ({nome})'] = cobre.mean()
                regra[f'Confiança ({nome})'] = (np.asarray(yc)[cobre] == classe).mean() if cobre.any() else np.nan
            regra['n (teste)'] = int((folhas['teste'] == no).sum())
            regras.append(regra)
            return
        a, limiar = nomes[t.feature[no]], t.threshold[no]
        lo, hi = limites.get(a, (None, None))
        descer(t.children_left[no], {**limites, a: (lo, limiar if hi is None else min(hi, limiar))})
        descer(t.children_right[no], {**limites, a: (limiar if lo is None else max(lo, limiar), hi)})
    descer(0, {})
    return pd.DataFrame(regras)

regras = extrair_regras(arvore, nomes, {'treino': (conj_treino, y_treino), 'teste': (conj_teste, y_teste)})
regras = regras.sort_values(['Classe', 'Cobertura (treino)'], ascending=[False, False]).reset_index(drop=True)
regras.index = [f'R{i + 1}' for i in range(len(regras))]
regras.to_csv('tabelas/regras_ad.csv')

importancia_ad = pd.Series(arvore.feature_importances_, index=nomes).sort_values(ascending=False)
print('Importância dos atributos (AD):')
print(importancia_ad[importancia_ad > 0].round(3).to_string())
with pd.option_context('display.max_colwidth', 120):
    display(regras.style.format({c: '{:.1%}' for c in regras.columns if c.startswith(('Cobertura', 'Confiança'))}))
""")

analise('regras')

# ---------------------------------------------------------------------------
md(r"""
## 3. Random Forest
### 3.a/b) Treinamento e otimização com os mesmos dois otimizadores

Mesmo protocolo da Árvore de Decisão: mesmas 6 combinações de pré-processamento, 50 avaliações por otimizador, os mesmos folds e a mesma métrica. Cada floresta roda com `n_jobs = 1` para que o paralelismo fique só entre os folds, igual para os dois otimizadores.
""")

code(r"""
executar_buscas('Random Forest')
""")

md("### 3.c) Melhores hiperparâmetros e tempo de busca — Random Forest")

code(r"""
hiper_rf = tabela_hiperparametros('Random Forest')
hiper_rf.to_csv('tabelas/hiperparametros_rf.csv', index=False)
hiper_rf
""")

analise('hiper_rf')

# ---------------------------------------------------------------------------
md(r"""
## 4. Avaliação e comparação dos resultados
### 4.a) Métricas no conjunto de teste para todas as combinações

Precisão, recall e F1 referem-se à classe **sobreviveu (1)**, a minoritária. As colunas "(0)" referem-se a não sobreviveu. O teste tem 393 passageiros, então o erro padrão da acurácia fica em torno de ±2 p.p. e diferenças menores que isso não devem ser tratadas como relevantes.
""")

code(r"""
COLUNAS = ['Modelo', 'Imputação', 'Balanceamento', 'Otimizador', 'CV F1-macro', 'Acurácia treino', 'Acurácia',
           'Precisão', 'Recall', 'F1', 'F1-macro', 'Precisão (0)', 'Recall (0)', 'Tempo (s)']
metricas = pd.DataFrame(resultados)[COLUNAS]
metricas.to_csv('tabelas/metricas.csv', index=False)
metricas.style.format({c: '{:.3f}' for c in COLUNAS[4:-1]} | {'Tempo (s)': '{:.1f}'}) \
    .background_gradient(subset=['Acurácia', 'F1', 'F1-macro'], cmap='Greens')
""")

code(r"""
fig, ax = plt.subplots(1, 2, figsize=(17, 5), sharey=True)
for i, otim in enumerate(OTIMIZADORES):
    m = metricas[metricas['Otimizador'] == otim].copy()
    m['Combinação'] = m['Imputação'].str.replace(' Imputer', '') + '\n' + m['Balanceamento'].str.replace('RandomUnderSampler', 'RUS').str.replace('Sem balanceamento', 'sem bal.')
    sns.barplot(data=m, x='Combinação', y='F1-macro', hue='Modelo', ax=ax[i], palette=['#e67e22', '#2980b9'])
    for p in ax[i].patches:
        if p.get_height() > 0:
            ax[i].annotate(f'{p.get_height():.3f}', (p.get_x() + p.get_width() / 2, p.get_height()), ha='center', va='bottom', fontsize=7)
    ax[i].set_ylim(0.6, 0.9); ax[i].set_title(f'F1-macro no teste — {otim}'); ax[i].set_xlabel('')
plt.tight_layout(); salvar_fig('metricas_modelos'); plt.show()
""")

md("### 4.b) Árvore de Decisão × Random Forest — qual generaliza melhor?")

code(r"""
generalizacao = metricas.groupby('Modelo')[['Acurácia treino', 'CV F1-macro', 'Acurácia', 'F1', 'F1-macro']].mean()
generalizacao['Gap treino − teste (acurácia)'] = generalizacao['Acurácia treino'] - generalizacao['Acurácia']
vitorias = (metricas.pivot_table(index=['Imputação', 'Balanceamento', 'Otimizador'], columns='Modelo', values='F1-macro')
            .pipe(lambda p: (p['Random Forest'] > p['Árvore de Decisão']).sum()))
print(f'Combinações em que a RF supera a AD em F1-macro no teste: {vitorias} de 12')
generalizacao.round(3)
""")

code(r"""
melhor_rf = max([r for r in resultados if r['Modelo'] == 'Random Forest' and r['Imputação'] == IMPUTACAO_ESCOLHIDA],
                key=lambda r: r['CV F1-macro'])
fig, ax = plt.subplots(1, 2, figsize=(10, 4))
for i, r in enumerate([melhor_ad, melhor_rf]):
    Xte = dados[r['Imputação']]['teste']
    ConfusionMatrixDisplay.from_predictions(y_teste, r['estimador'].predict(Xte), display_labels=['Não sobr.', 'Sobreviveu'],
                                            cmap='Blues', colorbar=False, ax=ax[i])
    ax[i].grid(False)
    ax[i].set_xlabel('Classe prevista'); ax[i].set_ylabel('Classe real')
    ax[i].set_title(f"{r['Modelo']}\n{r['Imputação']} + {r['Balanceamento']} + {r['Otimizador']}", fontsize=9)
plt.tight_layout(); salvar_fig('matrizes_confusao'); plt.show()
pd.DataFrame([{k: r[k] for k in COLUNAS} for r in [melhor_ad, melhor_rf]]).round(3)
""")

analise('4b')

md("### 4.c) Random Search × Otimização Bayesiana (Optuna)")

code(r"""
otimizadores = metricas.groupby(['Modelo', 'Otimizador']).agg(
    **{'Tempo médio (s)': ('Tempo (s)', 'mean'), 'Tempo total (s)': ('Tempo (s)', 'sum'),
       'CV F1-macro médio': ('CV F1-macro', 'mean'), 'F1-macro teste médio': ('F1-macro', 'mean')})

par = metricas.pivot_table(index=['Modelo', 'Imputação', 'Balanceamento'], columns='Otimizador', values=['CV F1-macro', 'F1-macro', 'Tempo (s)'])
duelo = pd.DataFrame({
    'Δ CV (Optuna − Random)': par['CV F1-macro']['Bayesiana (Optuna)'] - par['CV F1-macro']['Random Search'],
    'Δ F1-macro teste (Optuna − Random)': par['F1-macro']['Bayesiana (Optuna)'] - par['F1-macro']['Random Search'],
    'Tempo Optuna / Random': par['Tempo (s)']['Bayesiana (Optuna)'] / par['Tempo (s)']['Random Search']})
print('Optuna com CV maior ou igual:', (duelo['Δ CV (Optuna − Random)'] >= 0).sum(), 'de', len(duelo))
display(otimizadores.round(3))
duelo.round(4)
""")

code(r"""
fig, ax = plt.subplots(1, 2, figsize=(14, 4.2))
for i, modelo in enumerate(MODELOS):
    for otim, cor in zip(OTIMIZADORES, ['#8e44ad', '#16a085']):
        curvas = np.array([r['historico'] for r in resultados if r['Modelo'] == modelo and r['Otimizador'] == otim])
        # normaliza pela melhor pontuação de cada combinação (a melhor dos dois otimizadores)
        melhores = np.array([max(r['CV F1-macro'] for r in resultados if r['Modelo'] == modelo and
                                 r['Imputação'] == q['Imputação'] and r['Balanceamento'] == q['Balanceamento'])
                             for q in resultados if q['Modelo'] == modelo and q['Otimizador'] == otim])
        rel = curvas / melhores[:, None]
        ax[i].plot(range(1, N_ITER + 1), rel.mean(axis=0), color=cor, lw=2, label=otim)
        ax[i].fill_between(range(1, N_ITER + 1), rel.min(axis=0), rel.max(axis=0), color=cor, alpha=.15)
    ax[i].set_title(f'{modelo}: melhor CV F1-macro até a iteração t\n(relativo ao melhor das duas buscas; média das 6 combinações)', fontsize=10)
    ax[i].set_xlabel('iteração'); ax[i].set_ylabel('fração do melhor valor'); ax[i].legend()
plt.tight_layout(); salvar_fig('convergencia'); plt.show()
""")

code(r"""
# Tabela consolidada de hiperparâmetros (entregável): AD e RF lado a lado
hiperparametros = pd.concat([hiper_ad.assign(Modelo='Árvore de Decisão'), hiper_rf.assign(Modelo='Random Forest')])
hiperparametros = hiperparametros[['Modelo'] + [c for c in hiperparametros.columns if c != 'Modelo']]
hiperparametros.to_csv('tabelas/hiperparametros.csv', index=False)
hiperparametros
""")

analise('4c')

md("### 4.d) KNN Imputer × MissForest")

code(r"""
por_imputacao = metricas.groupby(['Modelo', 'Imputação'])[['CV F1-macro', 'Acurácia', 'Precisão', 'Recall', 'F1', 'F1-macro']].mean()
display(por_imputacao.round(3))
tabela_imputacao[['Média', 'Desvio', 'Mediana', 'Assimetria', 'KS', 'Wasserstein', 'corr(age, pclass)', 'MAE mascarado', 'RMSE mascarado']].round(3)
""")

analise('4d')

md("### 4.e) SMOTE (SMOTE-NC) × RandomUnderSampler — equilíbrio entre precisão e recall da classe minoritária")

code(r"""
por_balanceamento = metricas.groupby(['Modelo', 'Balanceamento'])[['Precisão', 'Recall', 'F1', 'Precisão (0)', 'Recall (0)', 'F1-macro', 'Acurácia']].mean()
por_balanceamento['|Precisão − Recall|'] = (por_balanceamento['Precisão'] - por_balanceamento['Recall']).abs()
por_balanceamento.to_csv('tabelas/por_balanceamento.csv')

fig, ax = plt.subplots(figsize=(7.5, 5))
marcadores = {'Sem balanceamento': 'o', 'SMOTE-NC': 's', 'RandomUnderSampler': '^'}
cores_modelo = {'Árvore de Decisão': '#e67e22', 'Random Forest': '#2980b9'}
for _, r in metricas.iterrows():
    ax.scatter(r['Recall'], r['Precisão'], marker=marcadores[r['Balanceamento']], color=cores_modelo[r['Modelo']], s=60, alpha=.75)
ax.plot([0.6, 0.9], [0.6, 0.9], ls=':', color='gray')
from matplotlib.lines import Line2D
ax.legend(handles=[Line2D([], [], marker=m, ls='', color='gray', label=b) for b, m in marcadores.items()] +
                  [Line2D([], [], marker='o', ls='', color=c, label=mo) for mo, c in cores_modelo.items()], fontsize=8)
ax.set_xlabel('Recall (sobreviveu)'); ax.set_ylabel('Precisão (sobreviveu)')
ax.set_title('Precisão × recall da classe minoritária (24 modelos)\nlinha pontilhada: precisão = recall')
plt.tight_layout(); salvar_fig('precisao_recall'); plt.show()
por_balanceamento.round(3)
""")

analise('4e')

md("### 4.f) As regras da Árvore continuam interpretáveis no Random Forest?")

code(r"""
floresta = melhor_rf['estimador'].named_steps['modelo']
nomes_rf = list(CodificadorOneHot().transform(dados[melhor_rf['Imputação']]['treino']).columns)
raizes = pd.Series([nomes_rf[e.tree_.feature[0]] for e in floresta.estimators_]).value_counts()
folhas_rf = [e.get_n_leaves() for e in floresta.estimators_]
prof_rf = [e.get_depth() for e in floresta.estimators_]
print(f"Random Forest ({melhor_rf['Imputação']} + {melhor_rf['Balanceamento']} + {melhor_rf['Otimizador']}): {melhor_rf['params']}")
print(f'Árvores: {len(floresta.estimators_)} | profundidade média: {np.mean(prof_rf):.1f} | '
      f'folhas por árvore: {np.mean(folhas_rf):.0f} (média) | regras no total: {sum(folhas_rf)}')
print(f'Árvore de Decisão: profundidade {arvore.get_depth()} | regras: {arvore.get_n_leaves()}')
print('\nAtributo usado na raiz de cada árvore da floresta:')
print(raizes.to_string())
for i in range(2):
    print(f'\n--- Árvore {i} da floresta (2 primeiros níveis) ---')
    print(export_text(floresta.estimators_[i], feature_names=nomes_rf, max_depth=2, decimals=2))
""")

code(r"""
importancias = pd.DataFrame({'Árvore de Decisão': importancia_ad,
                             'Random Forest': pd.Series(floresta.feature_importances_, index=nomes_rf)}).fillna(0)
importancias = importancias.sort_values('Random Forest', ascending=True)
importancias.to_csv('tabelas/importancias.csv')
importancias.plot(kind='barh', figsize=(8, 6), color=['#e67e22', '#2980b9'])
plt.title('Importância dos atributos (redução média de impureza)'); plt.xlabel('importância')
plt.tight_layout(); salvar_fig('importancias'); plt.show()

resumo_rf = {'arvores': len(floresta.estimators_), 'prof_media': float(np.mean(prof_rf)), 'folhas_media': float(np.mean(folhas_rf)),
             'regras_total': int(sum(folhas_rf)), 'raizes': raizes.to_dict(),
             'ad_prof': int(arvore.get_depth()), 'ad_folhas': int(arvore.get_n_leaves())}
pd.Series(resumo_rf)
""")

analise('4f')

md("## 5. Conclusão")
analise('conclusao')

nb = nbf.v4.new_notebook()
nb['cells'] = cells
nb['metadata'] = {'kernelspec': {'name': 'python3', 'display_name': 'Python 3', 'language': 'python'},
                  'language_info': {'name': 'python'}, 'colab': {'provenance': []}}
nbf.write(nb, os.path.join(AQUI, 'Lista3_IA_Titanic_AD_RF.ipynb'))
print('notebook gerado com', len(cells), 'células')
