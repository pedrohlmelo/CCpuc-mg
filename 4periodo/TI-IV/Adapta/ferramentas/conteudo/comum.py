"""Conexão com o Firestore e regras comuns aos scripts de conteúdo. Ver README.md."""
import datetime as dt
import os
import sys

import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud import firestore as cloud_firestore
from google.cloud.firestore_v1.base_query import FieldFilter

PROJETO = "adapta-ti4"
TAMANHO_LOTE = 400
AREAS = {"linguagens", "humanas", "natureza", "matematica"}


def conectar(simular=False):
    """Devolve o cliente, ou None ao simular sem credencial (Firestore tratado como vazio)."""
    if os.environ.get("FIRESTORE_EMULATOR_HOST"):
        return cloud_firestore.Client(project=os.environ.get("GCLOUD_PROJECT", PROJETO))
    caminho = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if not caminho:
        if simular:
            print("Sem credencial: simulando contra um Firestore vazio.")
            return None
        sys.exit("Defina GOOGLE_APPLICATION_CREDENTIALS com o caminho da chave (fora do repositório).")
    firebase_admin.initialize_app(credentials.Certificate(caminho))
    return firestore.client()


class Relogio:
    """`atualizado_em` único por documento: o app pagina por esse campo com
    `startAfter`, e dois documentos com o mesmo valor na virada de uma página
    fariam o segundo ser pulado."""

    def __init__(self):
        self.atual = dt.datetime.now(dt.timezone.utc)

    def proximo(self):
        self.atual += dt.timedelta(milliseconds=1)
        return self.atual.strftime("%Y-%m-%dT%H:%M:%S.") + f"{self.atual.microsecond // 1000:03d}Z"


def ler_colecao(db, nome):
    if db is None:
        return {}
    return {d.id: d.to_dict() for d in db.collection(nome).stream()}


def ler_questoes(db):
    return {int(i): q for i, q in ler_colecao(db, "questoes").items()}


def ler_estrutura(db):
    """(matérias por id, matéria de cada assunto, nome de cada assunto)."""
    materias = {int(i): m for i, m in ler_colecao(db, "materias").items()}
    materia_do_assunto, nomes = {}, {}
    for id_materia, m in materias.items():
        for a in m["assuntos"]:
            materia_do_assunto[a["id"]] = id_materia
            nomes[a["id"]] = a["nome"]
    return materias, materia_do_assunto, nomes


def gravar_lotes(db, colecao, documentos, simular):
    """Grava {id: campos} em lotes, sem apagar os campos que não vierem."""
    if simular or db is None:
        return
    itens = list(documentos.items())
    for inicio in range(0, len(itens), TAMANHO_LOTE):
        lote = db.batch()
        for id_doc, campos in itens[inicio:inicio + TAMANHO_LOTE]:
            lote.set(db.collection(colecao).document(str(id_doc)), campos, merge=True)
        lote.commit()


def subir_versao(db, relogio, simular, **campos):
    """Sempre por último: o app só vai buscar conteúdo novo quando a versão muda."""
    if simular or db is None:
        print("Simulação: nada gravado.")
        return None
    ref = db.collection("meta").document("conteudo")
    atual = ref.get().to_dict() or {}
    filtro = FieldFilter("ativo", "==", True)
    ativas = int(db.collection("questoes").where(filter=filtro).count().get()[0][0].value)
    versao = atual.get("versao", 0) + 1
    ref.set({"versao": versao, "atualizado_em": relogio.proximo(),
             "total_questoes": ativas, **campos}, merge=True)
    print(f"meta/conteudo: versão {versao}, {ativas} questões ativas")
    return versao


def tem_ciclo(assuntos, arestas):
    saida = {a: [] for a in assuntos}
    grau = {a: 0 for a in assuntos}
    for pre, dep in arestas:
        saida[pre].append(dep)
        grau[dep] += 1
    fila = [a for a, g in grau.items() if g == 0]
    vistos = 0
    while fila:
        vistos += 1
        for dep in saida[fila.pop()]:
            grau[dep] -= 1
            if grau[dep] == 0:
                fila.append(dep)
    return vistos != len(grau)


def alternativas_validas(alternativas):
    return (len({a["letra"] for a in alternativas}) == len(alternativas)
            and sum(bool(a["correta"]) for a in alternativas) == 1
            and all(a["texto"] or a["imagem"] for a in alternativas))
