"""Imprime as saídas de texto do notebook executado (para revisão)."""
import json
import sys

nb = json.load(open(sys.argv[1] if len(sys.argv) > 1 else 'Lista3_IA_Titanic_AD_RF.ipynb', encoding='utf-8'))
for i, c in enumerate(nb['cells']):
    if c['cell_type'] != 'code':
        continue
    for o in c.get('outputs', []):
        if o['output_type'] == 'stream':
            txt = ''.join(o['text'])
        elif o['output_type'] in ('execute_result', 'display_data'):
            txt = ''.join(o['data'].get('text/plain', ''))
        elif o['output_type'] == 'error':
            txt = f"ERRO {o['ename']}: {o['evalue']}"
        else:
            continue
        if txt.strip():
            print(f'--- célula {i} ---')
            print(txt[:6000])
