#!/usr/bin/env python3
"""Baixa as provas do ENEM da API enem.dev e prepara as questões do Adapta.

    python3 ferramentas/importar_enem/importar.py 2023 2022

Saída: cache/ (respostas brutas), assets/questoes/enem/{ano}/ (imagens) e
questoes_brutas.json, que a classificação e a montagem usam. Rodar de novo
aproveita o cache. Ver README.md.
"""
import json
import re
import subprocess
import sys
import tempfile
import time
import urllib.request
from pathlib import Path

API = "https://api.enem.dev/v1"
PASTA = Path(__file__).parent
RAIZ = PASTA.parents[1]
CACHE = PASTA / "cache"
SAIDA = PASTA / "questoes_brutas.json"
LIMITE_IMAGEM = 150 * 1024
TETO_IMAGENS = 25 * 1024 * 1024
PAUSA = 0.5
IMAGEM_MD = re.compile(r"!\[[^\]]*\]\(([^)]+)\)")


def baixar(url, destino):
    if destino.exists():
        return destino.read_bytes()
    pedido = urllib.request.Request(url, headers={"User-Agent": "adapta-ti4"})
    with urllib.request.urlopen(pedido, timeout=40) as resposta:
        dados = resposta.read()
    destino.parent.mkdir(parents=True, exist_ok=True)
    destino.write_bytes(dados)
    time.sleep(PAUSA)
    return dados


def questoes_da_prova(ano, lingua):
    offset, todas = 0, []
    while True:
        url = f"{API}/exams/{ano}/questions?limit=50&offset={offset}&language={lingua}"
        pagina = json.loads(baixar(url, CACHE / f"{ano}_{lingua}_{offset}.json"))
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
    texto = re.sub(r"[ \t]+\n", "\n", texto)
    texto = re.sub(r"\n{3,}", "\n\n", texto)
    return texto.strip()


def id_questao(q):
    base = q["year"] * 1000 + q["index"]
    return base + 500 if q.get("language") == "espanhol" else base


def imagens_da_questao(q):
    urls = IMAGEM_MD.findall(q.get("context") or "")
    urls += [u for u in (q.get("files") or []) if u not in urls]
    return urls


def converter(bruto, destino):
    """JPG de até 150 KB. O fundo transparente vira branco no PNG convertido."""
    with tempfile.TemporaryDirectory() as pasta:
        origem = Path(pasta) / "origem.png"
        origem.write_bytes(bruto)
        saida = Path(pasta) / "saida.jpg"
        for lado, qualidade in [(1000, 80), (900, 65), (800, 55), (650, 50), (500, 45)]:
            subprocess.run(
                ["sips", "-s", "format", "jpeg", "-s", "formatOptions", str(qualidade),
                 "-Z", str(lado), str(origem), "--out", str(saida)],
                check=True, capture_output=True,
            )
            if saida.stat().st_size <= LIMITE_IMAGEM:
                destino.parent.mkdir(parents=True, exist_ok=True)
                destino.write_bytes(saida.read_bytes())
                return True
    return False


def baixar_imagem(url, ano, nome):
    destino = RAIZ / f"assets/questoes/enem/{ano}/{nome}.jpg"
    if not destino.exists():
        extensao = url.rsplit(".", 1)[-1].split("?")[0].lower()
        bruto = baixar(url, CACHE / "imagens" / f"{ano}_{nome}.{extensao}")
        if not converter(bruto, destino):
            return None
    return f"asset:assets/questoes/enem/{ano}/{nome}.jpg"


def converter_questao(q, motivos):
    qid = id_questao(q)
    gabarito = q.get("correctAlternative")
    if gabarito not in list("ABCDE") or len(q.get("alternatives") or []) != 5:
        motivos[qid] = "sem gabarito ou sem 5 alternativas"
        return None
    if sum(bool(a.get("isCorrect")) for a in q["alternatives"]) != 1:
        motivos[qid] = "gabarito inconsistente"
        return None

    urls = imagens_da_questao(q)
    if any("broken-image" in u for u in urls):
        motivos[qid] = "imagem ausente na API"
        return None
    if len(urls) > 1:
        motivos[qid] = "mais de uma imagem no enunciado"
        return None

    imagem = baixar_imagem(urls[0], q["year"], str(qid)) if urls else None
    if urls and imagem is None:
        motivos[qid] = "imagem não coube em 150 KB"
        return None

    alternativas = []
    for a in q["alternatives"]:
        figura = None
        if a.get("file"):
            if "broken-image" in a["file"]:
                motivos[qid] = "imagem ausente na API"
                return None
            figura = baixar_imagem(a["file"], q["year"], f"{qid}_{a['letter']}")
            if figura is None:
                motivos[qid] = "imagem não coube em 150 KB"
                return None
        texto = limpar(a.get("text")) or None
        if texto is None and figura is None:
            motivos[qid] = "alternativa vazia"
            return None
        alternativas.append({
            "letra": a["letter"], "texto": texto, "correta": a["letter"] == gabarito,
            "imagem": figura, "imagem_descricao": None,
        })

    partes = [limpar(q.get("context")), limpar(q.get("alternativesIntroduction"))]
    return {
        "id": qid, "ano": q["year"], "indice": q["index"], "area": q["discipline"],
        "lingua": q.get("language"), "enunciado": "\n\n".join(p for p in partes if p),
        "imagem": imagem, "alternativas": alternativas,
        "fonte": f"ENEM {q['year']}, questão {q['index']}",
    }


def tamanho_imagens():
    pasta = RAIZ / "assets/questoes/enem"
    return sum(f.stat().st_size for f in pasta.rglob("*.jpg")) if pasta.exists() else 0


def main(anos):
    questoes, motivos = {}, {}
    for ano in anos:
        for lingua in ("ingles", "espanhol"):
            for q in questoes_da_prova(ano, lingua):
                if id_questao(q) in questoes or id_questao(q) in motivos:
                    continue
                convertida = converter_questao(q, motivos)
                if convertida:
                    questoes[convertida["id"]] = convertida

    ordenadas = sorted(questoes.values(), key=lambda q: q["id"])
    SAIDA.write_text(json.dumps(
        {"questoes": ordenadas, "fora": {str(k): v for k, v in sorted(motivos.items())}},
        ensure_ascii=False, indent=1) + "\n")

    total = tamanho_imagens()
    print(f"{len(ordenadas)} questões, {len(motivos)} de fora, imagens {total / 1048576:.1f} MB")
    if total > TETO_IMAGENS:
        print("ATENÇÃO: passou do teto de 25 MB")
    contagem = {}
    for motivo in motivos.values():
        contagem[motivo] = contagem.get(motivo, 0) + 1
    for motivo, n in sorted(contagem.items(), key=lambda m: -m[1]):
        print(f"  {n:4d}  {motivo}")


if __name__ == "__main__":
    main([int(a) for a in sys.argv[1:]] or [2023])
