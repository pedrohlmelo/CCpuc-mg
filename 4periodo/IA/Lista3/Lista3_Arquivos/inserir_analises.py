"""Preenche as células de análise do notebook JÁ EXECUTADO (sem reexecutar as buscas)."""
import json
import re

ARQ = 'Lista3_IA_Titanic_AD_RF.ipynb'
analises = json.load(open('analises.json', encoding='utf-8'))
nb = json.load(open(ARQ, encoding='utf-8'))

padrao = re.compile(r'^_\(análise `(\w+)` preenchida após a execução\)_$')
# células já preenchidas (ex.: analises.json embutido pelo build_notebook) são reconhecidas pelo início do texto
inicios = {texto[:40]: chave for chave, texto in analises.items()}
preenchidas, faltando = [], []
for c in nb['cells']:
    if c['cell_type'] != 'markdown':
        continue
    fonte = ''.join(c['source']).strip()
    m = padrao.match(fonte)
    chave = m.group(1) if m else inicios.get(fonte[:40])
    if chave is None:
        continue
    if chave in analises:
        c['source'] = analises[chave].splitlines(keepends=True)
        preenchidas.append(chave)
    else:
        faltando.append(chave)

json.dump(nb, open(ARQ, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('preenchidas:', preenchidas)
print('faltando:', faltando)
