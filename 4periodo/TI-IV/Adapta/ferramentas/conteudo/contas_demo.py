#!/usr/bin/env python3
"""Cria as contas de demonstração, Ana e Bruno, com histórico no Firestore.

    python contas_demo.py

As datas são relativas a hoje: rode de novo na véspera da apresentação. A senha fica em
~/.config/adapta/demo.txt, fora do repositório. Os roteiros são os de
lib/dados/banco/historicos_demo.dart, com questões do pacote inicial.
"""
import datetime as dt
import math
import random
import secrets
from pathlib import Path

from firebase_admin import auth

import comum
from gerar_pacote_inicial import escolher

ARQUIVO_SENHA = Path.home() / ".config/adapta/demo.txt"
TAXA_THETA = 0.4

# (assunto, dias atrás, taxa de acerto)
ROTEIROS = {
    "ana": ("Ana", 7, [
        (8, [28, 20, 8], 0.9), (9, [27, 18, 6], 0.85), (16, [25, 14, 9], 0.15),
        (706, [22, 10, 4], 0.8), (6, [20, 9, 3], 0.8), (1101, [19, 8, 3], 0.85),
        (701, [15, 7, 3], 0.1),
    ]),
    "bruno": ("Bruno", 11, [
        (8, [29, 15, 3], 0.95), (9, [28, 14, 3], 0.95), (1, [26, 12, 2], 0.9),
        (2, [25, 11, 2], 0.95), (3, [22, 10, 1], 0.9), (4, [29, 27], 0.85),
        (6, [18, 6, 1], 0.9), (1101, [17, 6, 1], 0.9), (801, [16, 5, 1], 0.9),
    ]),
}


def senha_demo():
    if not ARQUIVO_SENHA.exists():
        ARQUIVO_SENHA.write_text(secrets.token_urlsafe(9))
        ARQUIVO_SENHA.chmod(0o600)
    return ARQUIVO_SENHA.read_text().strip()


def conta(email, nome, senha):
    try:
        return auth.update_user(auth.get_user_by_email(email).uid, password=senha).uid
    except auth.UserNotFoundError:
        return auth.create_user(email=email, password=senha, display_name=nome).uid


def respostas(semente, roteiro, questoes, agora):
    aleatorio = random.Random(semente)
    saida = []
    for assunto, dias_atras, taxa in roteiro:
        do_assunto = [q for q in questoes if q["assunto"] == assunto]
        for dias in dias_atras:
            for i, q in enumerate(do_assunto):
                quando = agora - dt.timedelta(days=dias) + dt.timedelta(minutes=i * 3)
                acertou = aleatorio.random() < taxa
                alternativa = next(a for a in q["alternativas"] if a["correta"] == acertou)
                saida.append((quando, q, alternativa["letra"], acertou, 40 + aleatorio.randrange(120)))
    return sorted(saida, key=lambda r: r[0])


def apagar_subcolecao(db, colecao):
    for doc in colecao.stream():
        doc.reference.delete()


def gravar(db, uid, nome, email, lista, agora):
    raiz = db.collection("usuarios").document(uid)
    raiz.set({"nome": nome, "email": email, "tipo": "aluno"})
    for sub in ("historico", "memoria", "proficiencia"):
        apagar_subcolecao(db, raiz.collection(sub))

    thetas = {}
    lote = db.batch()
    for i, (quando, q, letra, acertou, tempo) in enumerate(lista):
        data = quando.isoformat()
        lote.set(raiz.collection("historico").document(f"demo-{uid}-{i}"), {
            "id_questao": q["id"], "letra_escolhida": letra, "acertou": int(acertou),
            "data": data, "tempo_gasto": tempo, "atualizado_em": data,
        })
        theta = thetas.get(q["assunto"], 0.0)
        chance = 1 / (1 + math.exp(-(theta - (q["dificuldade_irt"] or 0.0))))
        thetas[q["assunto"]] = theta + TAXA_THETA * (int(acertou) - chance)
    for assunto, theta in thetas.items():
        data = agora.isoformat()
        lote.set(raiz.collection("proficiencia").document(str(assunto)), {
            "nivel_estimado": theta, "data_atualizacao": data, "atualizado_em": data,
        })
    lote.commit()


def main():
    db = comum.conectar()
    questoes = escolher(comum.ler_questoes(db))
    senha = senha_demo()
    agora = dt.datetime.now().replace(microsecond=0)
    for chave, (nome, semente, roteiro) in ROTEIROS.items():
        email = f"{chave}@adapta.test"
        uid = conta(email, nome, senha)
        lista = respostas(semente, roteiro, questoes, agora)
        gravar(db, uid, nome, email, lista, agora)
        print(f"{email}: {len(lista)} respostas")
    print(f"Senha em {ARQUIVO_SENHA}")


if __name__ == "__main__":
    main()
