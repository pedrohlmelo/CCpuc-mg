#!/usr/bin/env python3
"""Revisão do grupo por planilha.

    python revisao.py exportar                     gera revisao.csv (não revisadas)
    python revisao.py aplicar revisao.csv [--simular]

Na planilha, altere `id_assunto`, `explicacao`, `revisado` e `ativo` (sim/nao).
"""
import argparse
import csv

import comum

COLUNAS = ["id", "fonte", "materia", "id_assunto", "assunto", "confianca", "gabarito",
           "enunciado", "explicacao", "revisado", "ativo"]
ORDEM = {"baixa": 0, "media": 1, "alta": 2}


def sim_nao(valor):
    return "sim" if valor else "nao"


def exportar(db):
    materias, _, nomes = comum.ler_estrutura(db)
    linhas = []
    for q in comum.ler_questoes(db).values():
        if q["revisado"] or q["assunto"] is None:
            continue
        linhas.append({
            "id": q["id"], "fonte": q["fonte"], "materia": materias[q["materia"]]["nome"],
            "id_assunto": q["assunto"], "assunto": nomes[q["assunto"]],
            "confianca": q.get("confianca_classificacao") or "",
            "gabarito": next(a["letra"] for a in q["alternativas"] if a["correta"]),
            "enunciado": " ".join(q["enunciado"].split())[:200],
            "explicacao": q["explicacao"], "revisado": sim_nao(q["revisado"]),
            "ativo": sim_nao(q["ativo"]),
        })
    linhas.sort(key=lambda l: (ORDEM.get(l["confianca"], 3), l["id"]))
    with open("revisao.csv", "w", newline="", encoding="utf-8-sig") as saida:
        escritor = csv.DictWriter(saida, COLUNAS)
        escritor.writeheader()
        escritor.writerows(linhas)
    print(f"revisao.csv: {len(linhas)} questões")


def aplicar(db, caminho, simular):
    _, materia_do_assunto, _ = comum.ler_estrutura(db)
    questoes = comum.ler_questoes(db)
    relogio = comum.Relogio()
    mudancas = {}
    with open(caminho, newline="", encoding="utf-8-sig") as entrada:
        separador = ";" if ";" in entrada.readline() else ","
        entrada.seek(0)
        for linha in csv.DictReader(entrada, delimiter=separador):
            q = questoes[int(linha["id"])]
            assunto = int(linha["id_assunto"])
            if assunto not in materia_do_assunto:
                print(f"Questão {q['id']}: assunto {assunto} não existe; linha ignorada")
                continue
            novos = {
                "assunto": assunto, "materia": materia_do_assunto[assunto],
                "explicacao": linha["explicacao"].strip(),
                "revisado": linha["revisado"].strip().lower() == "sim",
                "ativo": linha["ativo"].strip().lower() == "sim",
            }
            alterados = {c: v for c, v in novos.items() if q[c] != v}
            if alterados:
                mudancas[q["id"]] = {**alterados, "atualizado_em": relogio.proximo()}
    comum.gravar_lotes(db, "questoes", mudancas, simular)
    print(f"{len(mudancas)} questões alteradas")
    if mudancas:
        comum.subir_versao(db, relogio, simular)


def main():
    args = argparse.ArgumentParser()
    acoes = args.add_subparsers(dest="acao", required=True)
    acoes.add_parser("exportar")
    aplicacao = acoes.add_parser("aplicar")
    aplicacao.add_argument("arquivo")
    aplicacao.add_argument("--simular", action="store_true")
    args = args.parse_args()

    if args.acao == "exportar":
        exportar(comum.conectar())
    else:
        aplicar(comum.conectar(args.simular), args.arquivo, args.simular)


if __name__ == "__main__":
    main()
