#!/usr/bin/env python3
"""Monta assets/conteudo/*.json a partir das questões importadas e classificadas.

    python3 ferramentas/importar_enem/montar.py

Entradas: assuntos.json, questoes_brutas.json, classificacao.json,
explicacoes.json e autorais.json. Grava também revisao.csv. Rodar de novo
mantém o que já estava revisado nos JSON. Ver README.md.
"""
import csv
import json
import re
from pathlib import Path

PASTA = Path(__file__).parent
RAIZ = PASTA.parents[1]
CONTEUDO = RAIZ / "assets/conteudo"
IMAGENS = RAIZ / "assets/questoes/enem"
VERSAO = 3
TREINO = "Treino básico — Adapta"
AUTORAL = "Autoral — Adapta"

# Defeitos do texto da API que dá para corrigir com segurança.
CORRECOES = {
    2023161: [("aproximação para 28", "aproximação para √28")],
    2023081: [(" • gestão das ilicitudes pelo sistema judicial. aplicação das sanções "
               "pelo modelo equânime. supressão dos crimes pela penalização severa. "
               "regulamentação dos privilégios pela justiça social. repartição de "
               "vantagens pela hierarquização cultural", "")],
}


def ler(nome):
    return json.loads((PASTA / nome).read_text())


def limpar(texto):
    if texto is None:
        return None
    return re.sub(r"\\([\[\]*_])", r"\1", texto).replace("\xa0", " ")


def questao_importada(q, assunto, explicacao, anterior):
    enunciado = re.sub(r"\s+\n", "\n", limpar(q["enunciado"]))
    enunciado = re.sub(r"[ \n]*•\s*(?=gestão das ilicitudes)", " • ", enunciado)
    for errado, certo in CORRECOES.get(q["id"], []):
        assert errado in enunciado, q["id"]
        enunciado = enunciado.replace(errado, certo)
    revisado = bool(anterior and anterior.get("revisado"))
    return {
        "id": q["id"], "assunto": assunto, "dificuldade": 2,
        "enunciado": anterior["enunciado"] if revisado else enunciado,
        "explicacao": anterior["explicacao"] if revisado else explicacao,
        "imagem": q["imagem"],
        "imagem_descricao": f"Figura de {q['fonte']}." if q["imagem"] else None,
        "fonte": q["fonte"], "explicacao_gerada": True, "revisado": revisado,
        "alternativas": [
            {**a, "texto": limpar(a["texto"]),
             "imagem_descricao": f"Alternativa {a['letra']}." if a["imagem"] else None}
            for a in q["alternativas"]
        ],
    }


def questao_autoral(linha, anterior):
    qid, assunto, dificuldade, enunciado, explicacao, gabarito, textos = linha
    return {
        "id": qid, "assunto": assunto, "dificuldade": dificuldade,
        "enunciado": enunciado, "explicacao": explicacao,
        "imagem": None, "imagem_descricao": None, "fonte": AUTORAL,
        "explicacao_gerada": True,
        "revisado": bool(anterior and anterior.get("revisado")),
        "alternativas": [
            {"letra": l, "texto": t, "correta": l == gabarito,
             "imagem": None, "imagem_descricao": None}
            for l, t in zip("ABCDE", textos)
        ],
    }


def main():
    base = ler("assuntos.json")
    classes = ler("classificacao.json")
    explicacoes = ler("explicacoes.json")
    brutas = ler("questoes_brutas.json")["questoes"]
    autorais = ler("autorais.json")

    existentes = {}
    assuntos_antigos = {}
    for id_materia, nome in ((1, "matematica.json"), (2, "historia.json")):
        doc = json.loads((CONTEUDO / nome).read_text())
        assuntos_antigos[id_materia] = doc["assuntos"]
        for d in doc["dependencias"]:
            if [d["pre"], d["dep"], d["peso"]] not in base["dependencias"]:
                base["dependencias"].append([d["pre"], d["dep"], d["peso"]])
    for m in base["materias"].values():
        arquivo = CONTEUDO / m["arquivo"]
        if arquivo.exists():
            for q in json.loads(arquivo.read_text())["questoes"]:
                existentes[q["id"]] = q

    materias, materia_do_assunto = {}, {}
    for id_texto, m in base["materias"].items():
        id_materia = int(id_texto)
        assuntos = [a for a in assuntos_antigos.get(id_materia, [])
                    if a["id"] not in {n[0] for n in m["assuntos"]}]
        assuntos += [{"id": i, "nome": n, "descricao": d} for i, n, d in m["assuntos"]]
        materias[id_materia] = {**m, "assuntos": assuntos, "dependencias": [], "questoes": []}
        for a in assuntos:
            materia_do_assunto[a["id"]] = id_materia

    entre_materias = []
    for pre, dep, peso in base["dependencias"]:
        aresta = {"pre": pre, "dep": dep, "peso": peso}
        if materia_do_assunto[pre] == materia_do_assunto[dep]:
            materias[materia_do_assunto[dep]]["dependencias"].append(aresta)
        else:
            entre_materias.append(aresta)

    # Questões de treino: as primeiras do app, mantidas com os mesmos ids.
    for q in existentes.values():
        if q["id"] <= 44:
            materias[materia_do_assunto[q["assunto"]]]["questoes"].append(
                {**q, "fonte": TREINO})

    for linha in autorais:
        q = questao_autoral(linha, existentes.get(linha[0]))
        materias[materia_do_assunto[q["assunto"]]]["questoes"].append(q)

    usadas = set()
    revisao = []
    for q in brutas:
        c = classes[str(q["id"])]
        if c["assunto"] is None:
            continue
        nova = questao_importada(q, c["assunto"], explicacoes[str(q["id"])],
                                 existentes.get(q["id"]))
        materias[materia_do_assunto[c["assunto"]]]["questoes"].append(nova)
        for a in [nova, *nova["alternativas"]]:
            if a["imagem"]:
                usadas.add(a["imagem"].split("/")[-1])

    nomes = {a["id"]: (a["nome"], m["nome"]) for m in materias.values() for a in m["assuntos"]}
    for id_materia, m in sorted(materias.items()):
        m["questoes"].sort(key=lambda q: q["id"])
        doc = {"materia": id_materia, "assuntos": m["assuntos"],
               "dependencias": m["dependencias"], "questoes": m["questoes"]}
        (CONTEUDO / m["arquivo"]).write_text(
            json.dumps(doc, ensure_ascii=False, indent=2) + "\n")
        for q in m["questoes"]:
            if not q["revisado"]:
                gabarito = next(a["letra"] for a in q["alternativas"] if a["correta"])
                confianca = classes.get(str(q["id"]), {}).get("confianca", "")
                assunto, materia = nomes[q["assunto"]]
                revisao.append([q["id"], q["fonte"], materia, assunto, confianca, gabarito,
                                re.sub(r"\s+", " ", q["enunciado"])[:120]])

    indice = {
        "versao": VERSAO,
        "materias": [{"id": i, "nome": m["nome"], "area": m["area"], "arquivo": m["arquivo"]}
                     for i, m in sorted(materias.items())],
        "dependencias_entre_materias": entre_materias,
    }
    (CONTEUDO / "indice.json").write_text(json.dumps(indice, ensure_ascii=False, indent=2) + "\n")

    with (PASTA / "revisao.csv").open("w", newline="") as saida:
        escritor = csv.writer(saida)
        escritor.writerow(["id", "fonte", "materia", "assunto", "confianca", "gabarito", "enunciado"])
        ordem = {"baixa": 0, "media": 1, "alta": 2, "": 3}
        escritor.writerows(sorted(revisao, key=lambda l: (ordem[l[4]], l[0])))

    removidas = 0
    for imagem in IMAGENS.rglob("*.jpg"):
        if imagem.name not in usadas:
            imagem.unlink()
            removidas += 1
    print(f"{sum(len(m['questoes']) for m in materias.values())} questões, "
          f"{len(revisao)} a revisar, {removidas} imagens sem uso removidas")


if __name__ == "__main__":
    main()
