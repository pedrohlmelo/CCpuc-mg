#!/usr/bin/env python3
"""Classificação e explicações, gravadas no próprio documento da questão.

    python classificar.py pendentes [--lote 50]         mostra as próximas sem assunto
    python classificar.py aplicar notas.json [--simular]

notas.json: {"2023136": {"assunto": 101, "confianca": "alta", "explicacao": "..."}}.
A explicação também pode vir à parte, num segundo arquivo {"2023136": "..."}.
Assunto nulo: não há assunto adequado, e a questão fica inativa e fora das pendentes.
"""
import argparse
import json

import comum

SEM_ASSUNTO = "sem_assunto"


def pendentes(questoes):
    return [q for _, q in sorted(questoes.items())
            if q["assunto"] is None and q.get("confianca_classificacao") is None]


def mostrar(db, tamanho):
    todas = pendentes(comum.ler_questoes(db))
    print(f"{len(todas)} pendentes")
    for q in todas[:tamanho]:
        print(f"\n# {q['id']} — {q['fonte']}\n{q['enunciado']}")
        for a in q["alternativas"]:
            marca = "*" if a["correta"] else " "
            print(f"{marca} {a['letra']}) {a['texto'] or '[imagem]'}")


def aplicar(db, arquivos, simular):
    notas = {}
    for caminho in arquivos:
        with open(caminho, encoding="utf8") as entrada:
            for qid, nota in json.load(entrada).items():
                nota = nota if isinstance(nota, dict) else {"explicacao": nota}
                notas.setdefault(int(qid), {}).update(nota)

    _, materia_do_assunto, _ = comum.ler_estrutura(db)
    questoes = comum.ler_questoes(db)
    relogio = comum.Relogio()
    mudancas, ignoradas = {}, []
    abertas = {q["id"] for q in pendentes(questoes)}
    for qid, nota in sorted(notas.items()):
        q = questoes.get(qid)
        assunto = nota.get("assunto")
        if qid not in abertas:
            ignoradas.append(qid)
        elif assunto is None:
            mudancas[qid] = {"confianca_classificacao": SEM_ASSUNTO, "ativo": False,
                             "atualizado_em": relogio.proximo()}
        elif assunto not in materia_do_assunto or not nota.get("explicacao"):
            ignoradas.append(qid)
        else:
            mudancas[qid] = {
                "materia": materia_do_assunto[assunto], "assunto": assunto,
                "confianca_classificacao": nota["confianca"],
                "explicacao": nota["explicacao"], "explicacao_gerada": True,
                "revisado": False, "ativo": True, "atualizado_em": relogio.proximo(),
            }
    comum.gravar_lotes(db, "questoes", mudancas, simular)
    print(f"{len(mudancas)} classificadas, {len(ignoradas)} ignoradas {ignoradas[:10]}")
    if mudancas:
        comum.subir_versao(db, relogio, simular)


def main():
    args = argparse.ArgumentParser()
    acoes = args.add_subparsers(dest="acao", required=True)
    acoes.add_parser("pendentes").add_argument("--lote", type=int, default=50)
    aplicacao = acoes.add_parser("aplicar")
    aplicacao.add_argument("arquivos", nargs="+")
    aplicacao.add_argument("--simular", action="store_true")
    args = args.parse_args()

    if args.acao == "pendentes":
        mostrar(comum.conectar(), args.lote)
    else:
        aplicar(comum.conectar(args.simular), args.arquivos, args.simular)


if __name__ == "__main__":
    main()
