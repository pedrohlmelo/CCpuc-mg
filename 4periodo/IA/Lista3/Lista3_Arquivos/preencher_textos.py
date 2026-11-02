"""Preenche os marcadores [[...]] dos textos com os valores da execução final e gera
textos_pdf.json (PDF) e analises.json (células de análise do notebook)."""
import json
import re
import sys

import pandas as pd

SNAP = sys.argv[1] if len(sys.argv) > 1 else None


def br(x, d=1):
    return f'{x:.{d}f}'.replace('.', ',')


met = pd.read_csv('tabelas/metricas.csv')
imp = pd.read_csv('tabelas/imputacao.csv', index_col=0)
impt = pd.read_csv('tabelas/importancias.csv', index_col=0)

# as métricas não podem mudar entre execuções (só o tempo)
if SNAP:
    antes = pd.read_csv(f'{SNAP}/metricas.csv').drop(columns='Tempo (s)')
    pd.testing.assert_frame_equal(antes, met.drop(columns='Tempo (s)'), check_exact=False, atol=1e-9)
    print('métricas idênticas à execução anterior')

t = met.groupby(['Modelo', 'Otimizador'])['Tempo (s)'].mean()
par = met.pivot_table(index=['Modelo', 'Imputação', 'Balanceamento'], columns='Otimizador', values='Tempo (s)')
razao = (par['Bayesiana (Optuna)'] / par['Random Search']).groupby('Modelo').mean()
rf = impt['Random Forest']
valores = {
    't_ad_rs': br(t['Árvore de Decisão', 'Random Search']), 't_ad_op': br(t['Árvore de Decisão', 'Bayesiana (Optuna)']),
    't_rf_rs': br(t['Random Forest', 'Random Search']), 't_rf_op': br(t['Random Forest', 'Bayesiana (Optuna)']),
    'r_ad': br(razao['Árvore de Decisão']), 'r_rf': br(razao['Random Forest']),
    't_knn_imp': br(imp.loc['KNN Imputer', 'Tempo (s)'], 2), 't_mf_imp': br(imp.loc['MissForest', 'Tempo (s)'], 1),
    'imp_sexo_titulo_rf': br(rf['sexo'] + rf.filter(like='titulo_').sum(), 2),
}
print(valores)


def preencher(obj):
    if isinstance(obj, str):
        for k, v in valores.items():
            obj = obj.replace(f'[[{k}]]', v)
        assert '[[' not in obj, obj
        return obj
    if isinstance(obj, list):
        return [preencher(o) for o in obj]
    if isinstance(obj, dict):
        return {k: preencher(v) for k, v in obj.items()}
    return obj


T = preencher(json.load(open('textos_base.json', encoding='utf-8')))
json.dump(T, open('textos_pdf.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)


# --- versão markdown para o notebook -------------------------------------------
def md(texto):
    texto = re.sub(r'</?b>', '**', texto)
    texto = re.sub(r'</?i>', '*', texto)
    texto = re.sub(r"<font face='CourierNew'>(.*?)</font>", r'`\1`', texto)
    texto = re.sub(r'\s*\(Figura \d+[^)]*\)', '', texto)
    texto = re.sub(r'\s*\(Tabelas? \d+\)', '', texto)
    texto = re.sub(r'Na Figura \d+, ', 'No gráfico acima, ', texto)
    texto = re.sub(r'A Figura \d+ ', 'O gráfico acima ', texto)
    texto = re.sub(r'Na Tabela \d+, ', 'Na tabela de regras, ', texto)
    texto = re.sub(r'A Tabela \d+ ', 'A tabela ', texto)
    return texto.replace('• ', '* ')


def md_blocos(chave):
    return '\n\n'.join(md(par) for par in T[chave])


def md_tabela(chave):
    d = T[chave]
    linhas = ['| ' + ' | '.join(d['cabecalho']) + ' |', '|' + '---|' * len(d['cabecalho'])]
    linhas += ['| ' + ' | '.join(l) + ' |' for l in d['linhas']]
    return '\n'.join(linhas)


def secao(chave):
    partes = [md_blocos(chave)]
    if f'{chave}_tabela' in T:
        partes.append(md_tabela(f'{chave}_tabela'))
    if f'{chave}_pos' in T:
        partes.append(md_blocos(f'{chave}_pos'))
    return '\n\n'.join(partes)


h = T['hiperparametros']
analises = {
    'imputacao': md_blocos('imputacao'),
    'balanceamento': md_blocos('balanceamento'),
    'hiper_ad': md(h[0]) + '\n\n' + md(h[2]),
    'regras': md_blocos('regras'),
    'hiper_rf': md(h[1]),
    '4b': secao('4b'), '4c': secao('4c'), '4d': secao('4d'), '4e': secao('4e'), '4f': secao('4f'),
    'conclusao': md_blocos('conclusao') + '\n\n> ' + T['destaque'],
}
json.dump(analises, open('analises.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('textos_pdf.json e analises.json gerados')
