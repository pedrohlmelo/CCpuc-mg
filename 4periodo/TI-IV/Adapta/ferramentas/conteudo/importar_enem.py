#!/usr/bin/env python3
"""Importa provas do ENEM da API enem.dev direto para questoes/* (sem assunto e inativas).

    python importar_enem.py 2023 2022 [--simular]

Questão que já existe no Firestore não é sobrescrita. Ver README.md.
"""
import argparse
import json
import re
import time
import urllib.error
import urllib.request

import comum

API = "https://api.enem.dev/v1"
PAUSA = 0.5
ESPERA_LIMITE = 30
TENTATIVAS = 6
IMAGEM_MD = re.compile(r"!\[[^\]]*\]\(([^)]+)\)")

# Defeitos do texto da API que dá para corrigir com segurança.
CORRECOES = {
    2023161: [("aproximação para 28", "aproximação para √28")],
    2023081: [(" • gestão das ilicitudes pelo sistema judicial. aplicação das sanções "
               "pelo modelo equânime. supressão dos crimes pela penalização severa. "
               "regulamentação dos privilégios pela justiça social. repartição de "
               "vantagens pela hierarquização cultural", "")],
}


def pedir(url, metodo="GET"):
    pedido = urllib.request.Request(url, method=metodo, headers={"User-Agent": "adapta-ti4"})
    for tentativa in range(TENTATIVAS):
        try:
            with urllib.request.urlopen(pedido, timeout=40) as resposta:
                dados = resposta.read()
            time.sleep(PAUSA)
            return dados
        except urllib.error.HTTPError as erro:
            if erro.code != 429 or tentativa == TENTATIVAS - 1:
                raise
            espera = int(erro.headers.get("Retry-After") or ESPERA_LIMITE)
            print(f"Limite da API: aguardando {espera} s")
            time.sleep(espera)


def imagem_responde(url):
    try:
        pedir(url, "HEAD")
        return True
    except (urllib.error.URLError, TimeoutError):
        return False


def questoes_da_prova(ano, lingua):
    offset, todas = 0, []
    while True:
        pagina = json.loads(pedir(
            f"{API}/exams/{ano}/questions?limit=50&offset={offset}&language={lingua}"))
        todas += pagina["questions"]
        if not pagina["metadata"]["hasMore"]:
            return todas
        offset += 50


def limpar(texto):
    """Tira o Markdown que não é texto e deixa os parágrafos."""
    texto = IMAGEM_MD.sub("", texto or "")
    texto = re.sub(r"\*\*(.+?)\*\*", r"\1", texto, flags=re.S)
    texto = re.sub(r"(?<!\w)[*_]([^*_\n]+)[*_](?!\w)", r"\1", texto)
    texto = re.sub(r"^#+\s*", "", texto, flags=re.M)
    texto = re.sub(r"\\([\[\]*_])", r"\1", texto).replace("\xa0", " ")
    texto = re.sub(r"\s+\n", "\n", texto)
    texto = re.sub(r"\n{3,}", "\n\n", texto)
    return texto.strip()


def id_questao(q):
    base = q["year"] * 1000 + q["index"]
    return base + 500 if q.get("language") == "espanhol" else base


def imagens_da_questao(q):
    urls = IMAGEM_MD.findall(q.get("context") or "")
    urls += [u for u in (q.get("files") or []) if u not in urls]
    return urls


def enunciado_da_questao(q, qid):
    partes = [limpar(q.get("context")), limpar(q.get("alternativesIntroduction"))]
    enunciado = "\n\n".join(p for p in partes if p)
    enunciado = re.sub(r"[ \n]*•\s*(?=gestão das ilicitudes)", " • ", enunciado)
    for errado, certo in CORRECOES.get(qid, []):
        assert errado in enunciado, qid
        enunciado = enunciado.replace(errado, certo)
    return enunciado


def converter(q, motivos):
    """Documento da questão, ou None com o motivo em `motivos`."""
    qid = id_questao(q)
    gabarito = q.get("correctAlternative")
    if gabarito not in list("ABCDE") or len(q.get("alternatives") or []) != 5:
        motivos[qid] = "sem gabarito ou sem 5 alternativas"
        return None
    if sum(bool(a.get("isCorrect")) for a in q["alternatives"]) != 1:
        motivos[qid] = "gabarito inconsistente"
        return None

    urls = imagens_da_questao(q)
    arquivos = urls + [a["file"] for a in q["alternatives"] if a.get("file")]
    if any("broken-image" in u for u in arquivos):
        motivos[qid] = "imagem ausente na API"
        return None
    if len(urls) > 1:
        motivos[qid] = "mais de uma imagem no enunciado"
        return None
    if not all(imagem_responde(u) for u in arquivos):
        motivos[qid] = "imagem não responde"
        return None

    fonte = f"ENEM {q['year']}, questão {q['index']}"
    alternativas = []
    for a in q["alternatives"]:
        texto = limpar(a.get("text")) or None
        figura = a.get("file") or None
        if texto is None and figura is None:
            motivos[qid] = "alternativa vazia"
            return None
        alternativas.append({
            "letra": a["letter"], "texto": texto, "correta": a["letter"] == gabarito,
            "imagem": figura,
            "imagem_descricao": f"Alternativa {a['letter']}." if figura else None,
        })
    return {
        "id": qid, "materia": None, "assunto": None, "dificuldade": 2, "dificuldade_irt": None,
        "enunciado": enunciado_da_questao(q, qid), "explicacao": "",
        "imagem": urls[0] if urls else None,
        "imagem_descricao": f"Figura de {fonte}." if urls else None,
        "fonte": fonte, "explicacao_gerada": False, "revisado": False, "ativo": False,
        "confianca_classificacao": None, "alternativas": alternativas,
    }


def main():
    args = argparse.ArgumentParser()
    args.add_argument("anos", nargs="*", type=int, default=[2023])
    args.add_argument("--simular", action="store_true")
    args = args.parse_args()

    db = comum.conectar(args.simular)
    existentes = comum.ler_questoes(db)
    relogio = comum.Relogio()
    novas, motivos, vistas = {}, {}, set()
    for ano in args.anos:
        for lingua in ("ingles", "espanhol"):
            for q in questoes_da_prova(ano, lingua):
                qid = id_questao(q)
                if qid in vistas or qid in existentes:
                    continue
                vistas.add(qid)
                doc = converter(q, motivos)
                if doc:
                    novas[qid] = {**doc, "atualizado_em": relogio.proximo()}

    comum.gravar_lotes(db, "questoes", novas, args.simular)
    print(f"{len(novas)} questões novas, {len(existentes)} já existiam, {len(motivos)} de fora")
    contagem = {}
    for motivo in motivos.values():
        contagem[motivo] = contagem.get(motivo, 0) + 1
    for motivo, n in sorted(contagem.items(), key=lambda m: -m[1]):
        print(f"  {n:4d}  {motivo}")
    if novas:
        comum.subir_versao(db, relogio, args.simular)


if __name__ == "__main__":
    main()
