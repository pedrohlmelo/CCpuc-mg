#!/usr/bin/env python3
"""Resume assets/conteudo/ e confere as regras dos ids e do grafo.

    python3 ferramentas/relatorio_conteudo.py
"""
import json
import re
import sys
from collections import Counter
from pathlib import Path

RAIZ = Path(__file__).parents[1]
CONTEUDO = RAIZ / "assets/conteudo"
CLASSES = json.loads((RAIZ / "ferramentas/importar_enem/classificacao.json").read_text())
AREAS = {"linguagens", "humanas", "natureza", "matematica"}


def main():
    indice = json.loads((CONTEUDO / "indice.json").read_text())
    erros, ids_a, ids_q, arestas = [], set(), set(), []
    assuntos_materia, totais = {}, Counter()

    for m in indice["materias"]:
        if m["area"] not in AREAS:
            erros.append(f"matéria {m['id']}: área {m['area']}")
        arquivo = CONTEUDO / m["arquivo"]
        doc = json.loads(arquivo.read_text())
        print(f"\n{m['nome']} ({m['area']}) — {arquivo.stat().st_size / 1024:.0f} KB")
        arestas += doc["dependencias"]
        por_assunto = {a["id"]: [] for a in doc["assuntos"]}
        for a in doc["assuntos"]:
            if a["id"] in ids_a:
                erros.append(f"assunto {a['id']} repetido")
            ids_a.add(a["id"])
            assuntos_materia[a["id"]] = m["id"]
            if a["id"] > 16 and a["id"] // 100 != m["id"]:
                erros.append(f"assunto {a['id']} fora da faixa da matéria {m['id']}")
        for q in doc["questoes"]:
            if q["id"] in ids_q:
                erros.append(f"questão {q['id']} repetida")
            ids_q.add(q["id"])
            if q["assunto"] not in por_assunto:
                erros.append(f"questão {q['id']}: assunto de outra matéria")
                continue
            por_assunto[q["assunto"]].append(q)
            if sum(a["correta"] for a in q["alternativas"]) != 1:
                erros.append(f"questão {q['id']}: gabarito")
            if q["fonte"].startswith("ENEM"):
                ano, indice_q = map(int, re.findall(r"\d+", q["fonte"])[:2])
                if q["id"] not in (ano * 1000 + indice_q, ano * 1000 + indice_q + 500):
                    erros.append(f"questão {q['id']}: id não bate com {q['fonte']}")
        for a in doc["assuntos"]:
            qs = por_assunto[a["id"]]
            enem = sum(q["fonte"].startswith("ENEM") for q in qs)
            baixas = sum(CLASSES.get(str(q["id"]), {}).get("confianca") == "baixa" for q in qs)
            nao_rev = sum(not q["revisado"] for q in qs)
            totais.update(total=len(qs), enem=enem, baixas=baixas, nao_revisadas=nao_rev)
            if len(qs) < 3:
                erros.append(f"assunto {a['id']} com {len(qs)} questões")
            print(f"  {a['nome']:<38} {len(qs):3d} q | ENEM {enem:3d} | outras {len(qs) - enem:2d}"
                  f" | conf. baixa {baixas:2d} | não revisadas {nao_rev:3d}")

    arestas += indice["dependencias_entre_materias"]
    for d in arestas:
        if d["pre"] not in ids_a or d["dep"] not in ids_a:
            erros.append(f"aresta {d['pre']} → {d['dep']} sem assunto")
    for original in (*range(1, 17),):
        if original not in ids_a:
            erros.append(f"assunto original {original} sumiu")
    for original in range(1, 45):
        if original not in ids_q:
            erros.append(f"questão original {original} sumiu")

    entrada = Counter(d["dep"] for d in arestas)
    livres = [i for i in ids_a if entrada[i] == 0]
    vistos = 0
    while livres:
        v = livres.pop()
        vistos += 1
        for d in arestas:
            if d["pre"] == v:
                entrada[d["dep"]] -= 1
                if entrada[d["dep"]] == 0:
                    livres.append(d["dep"])
    if vistos != len(ids_a):
        erros.append("o grafo tem ciclo")

    pasta = RAIZ / "assets/questoes/enem"
    imagens = list(pasta.rglob("*.jpg"))
    tamanho = sum(f.stat().st_size for f in imagens)
    print(f"\nVersão {indice['versao']}: {len(indice['materias'])} matérias, {len(ids_a)} assuntos,"
          f" {len(arestas)} arestas ({len(indice['dependencias_entre_materias'])} entre matérias)")
    print(f"Questões: {totais['total']} ({totais['enem']} ENEM, {totais['total'] - totais['enem']}"
          f" autorais), {totais['baixas']} com confiança baixa, {totais['nao_revisadas']} não revisadas")
    print(f"Imagens: {len(imagens)} arquivos, {tamanho / 1048576:.1f} MB (teto 25 MB)")
    if erros:
        print("\nPROBLEMAS:\n  " + "\n  ".join(erros))
        sys.exit(1)
    print("Regras de ids e grafo: tudo certo")


if __name__ == "__main__":
    main()
