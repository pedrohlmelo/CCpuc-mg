#!/usr/bin/env python3
"""Gera lib/dados/banco/pacote_inicial.g.dart a partir do Firestore.

    python gerar_pacote_inicial.py [--saida arquivo]

Leva toda a estrutura, as questões de treino e ~60 questões sem imagem de URL, para
o app funcionar no primeiro acesso sem internet.
"""
import argparse
import json
from pathlib import Path

import comum

DESTINO = Path(__file__).parents[2] / "lib/dados/banco/pacote_inicial.g.dart"
ULTIMO_ID_DE_TREINO = 44
EXTRAS = 60
MINIMO_POR_MATERIA = 4
# Estequiometria: a lacuna da conta de demonstração precisa funcionar offline.
ASSUNTOS_DA_DEMO = {701}


def tem_imagem_remota(q):
    return any((x["imagem"] or "").startswith("http") for x in [q, *q["alternativas"]])


def prioridade(q):
    ordem = {"alta": 0, "media": 1, "baixa": 2}
    return (not q["revisado"], ordem.get(q.get("confianca_classificacao"), 1), q["id"])


def escolher(questoes):
    """Primeiro o mínimo por matéria, depois o máximo de assuntos, depois o que faltar."""
    ativas = [q for q in questoes.values() if q["ativo"]]
    escolhidas = {q["id"]: q for q in ativas if q["id"] <= ULTIMO_ID_DE_TREINO}
    candidatas = sorted((q for q in ativas if q["id"] > ULTIMO_ID_DE_TREINO
                         and not tem_imagem_remota(q)), key=prioridade)
    assuntos = {q["assunto"] for q in escolhidas.values()}
    extras = []
    for q in candidatas:
        if q["assunto"] in ASSUNTOS_DA_DEMO:
            escolhidas[q["id"]] = q
            extras.append(q)

    def incluir(q):
        escolhidas[q["id"]] = q
        assuntos.add(q["assunto"])
        extras.append(q)

    def na_materia(id_materia):
        return sum(q["materia"] == id_materia for q in escolhidas.values())

    for id_materia in sorted({q["materia"] for q in ativas}):
        for preferir_assunto_novo in (True, False):
            for q in candidatas:
                if na_materia(id_materia) >= MINIMO_POR_MATERIA:
                    break
                if (q["materia"] == id_materia and q["id"] not in escolhidas
                        and (q["assunto"] not in assuntos or not preferir_assunto_novo)):
                    incluir(q)
    for q in candidatas:
        if len(extras) < EXTRAS and q["id"] not in escolhidas and q["assunto"] not in assuntos:
            incluir(q)
    for q in candidatas:
        if len(extras) < EXTRAS and q["id"] not in escolhidas:
            incluir(q)
    return sorted(escolhidas.values(), key=lambda q: q["id"])


def literal(valor):
    """JSON é Dart válido, menos o `$`, que abriria uma interpolação."""
    return json.dumps(valor, ensure_ascii=False, indent=2, sort_keys=True).replace("$", "\\$")


def main():
    args = argparse.ArgumentParser()
    args.add_argument("--saida", type=Path, default=DESTINO)
    args = args.parse_args()

    db = comum.conectar()
    meta = db.collection("meta").document("conteudo").get().to_dict()
    materias = [m for _, m in sorted(comum.ler_estrutura(db)[0].items())]
    questoes = escolher(comum.ler_questoes(db))
    args.saida.write_text(
        "// Gerado por gerar_pacote_inicial.py — não edite.\n"
        "// ignore_for_file: type=lint\n\n"
        f"const Map<String, dynamic> pacoteInicialMeta = {literal(meta)};\n\n"
        f"const List<Map<String, dynamic>> pacoteInicialMaterias = {literal(materias)};\n\n"
        f"const List<Map<String, dynamic>> pacoteInicialQuestoes = {literal(questoes)};\n",
        encoding="utf8")
    print(f"{args.saida.name}: versão {meta['versao']}, {len(materias)} matérias, "
          f"{len(questoes)} questões")


if __name__ == "__main__":
    main()
