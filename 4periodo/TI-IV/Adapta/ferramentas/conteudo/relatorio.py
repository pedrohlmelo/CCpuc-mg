#!/usr/bin/env python3
"""Relatório do conteúdo no Firestore: contagens por matéria e assunto e regras de ids.

    python relatorio.py
"""
import comum
from gerar_pacote_inicial import escolher, tem_imagem_remota

ULTIMO_ASSUNTO_ANTIGO = 16
ULTIMA_QUESTAO_ANTIGA = 44
# Questões criadas no painel admin do app.
IDS_DO_PAINEL = range(9000001, 10000000)


def contar(questoes, pacote):
    enem = [q for q in questoes if q["fonte"].startswith("ENEM")]
    return (f"{len(questoes):4d} {len(enem):5d} {len(questoes) - len(enem):8d} "
            f"{sum(q.get('confianca_classificacao') == 'baixa' for q in questoes):6d} "
            f"{sum(not q['revisado'] for q in questoes):8d} "
            f"{sum(tem_imagem_remota(q) for q in questoes):7d} "
            f"{sum(q['id'] in pacote for q in questoes):7d}")


def conferir(materias, questoes):
    problemas = []
    arestas = []
    for id_materia, m in materias.items():
        arestas += [(d["pre"], d["dep"]) for d in m["dependencias"]]
        for a in m["assuntos"]:
            if a["id"] > ULTIMO_ASSUNTO_ANTIGO and a["id"] // 100 != id_materia:
                problemas.append(f"assunto {a['id']} fora da regra da matéria {id_materia}")
    for q in questoes.values():
        fora = (q["id"] // 1000 < 2000 if q["fonte"].startswith("ENEM")
                else q["id"] not in IDS_DO_PAINEL
                and q["id"] > ULTIMA_QUESTAO_ANTIGA and q["id"] // 10 != q["assunto"])
        if fora:
            problemas.append(f"questão {q['id']} fora da regra de ids")
        if q["ativo"] and not comum.alternativas_validas(q["alternativas"]):
            problemas.append(f"questão {q['id']} com alternativas inválidas")
    return problemas, arestas


def main():
    db = comum.conectar()
    meta = db.collection("meta").document("conteudo").get().to_dict() or {}
    materias, materia_do_assunto, nomes = comum.ler_estrutura(db)
    questoes = comum.ler_questoes(db)
    ativas = [q for q in questoes.values() if q["ativo"]]
    pacote = {q["id"] for q in escolher(questoes)}

    cabecalho = "total  enem autorais  baixa não_rev imagens pacote"
    print(f"{'':44s}{cabecalho}")
    for id_materia, m in sorted(materias.items()):
        da_materia = [q for q in ativas if q["materia"] == id_materia]
        print(f"{m['nome'] + ' (' + m['area'] + ')':44s}{contar(da_materia, pacote)}")
        for a in m["assuntos"]:
            print(f"    {a['nome'][:38]:40s}"
                  f"{contar([q for q in da_materia if q['assunto'] == a['id']], pacote)}")
    print(f"{'TOTAL':44s}{contar(ativas, pacote)}")

    problemas, arestas = conferir(materias, questoes)
    arestas += [(d["pre"], d["dep"]) for d in meta.get("dependencias_entre_materias", [])]
    fracos = [nomes[a] for a in nomes
              if sum(q["assunto"] == a for q in ativas) < 3]
    print(f"\n{len(materias)} matérias, {len(nomes)} assuntos, {len(arestas)} arestas, "
          f"{len(questoes) - len(ativas)} questões inativas, versão {meta.get('versao')}")
    print(f"Grafo sem ciclo: {not comum.tem_ciclo(materia_do_assunto, arestas)}")
    print(f"Assuntos com menos de 3 questões: {fracos or 'nenhum'}")
    print(f"Regras de ids: {problemas or 'ok'}")


if __name__ == "__main__":
    main()
