"""Gera os dados sintéticos do treino da IA do Adapta.

Uso, a partir da raiz do projeto Flutter:
    python3 -m pip install -r ia/requirements.txt
    dart run ferramentas/exportar_seed.dart   # gera ia/seed.json
    python3 ia/gerar_dataset.py

Os dados são simulados: o app ainda não tem alunos reais. Saída em ia/dados/:
  eventos.csv    uma linha por revisão de um assunto (modelo de esquecimento)
  respostas.csv  aluno × questão (dificuldade de Rasch)
  dificuldades_reais.json  dificuldade `b` usada na simulação, para conferência
"""
import csv
import json
import math
import random
from pathlib import Path

PASTA = Path(__file__).resolve().parent
DADOS = PASTA / "dados"
ALUNOS = 500
SEMENTE = 2026


def gerar_eventos(aleatorio, questoes_por_assunto):
    """Retenção ~ exp(−dias / estabilidade); estabilidade individual, que cresce
    a cada revisão bem-sucedida e cai com a dificuldade."""
    assuntos = sorted(questoes_por_assunto)
    linhas = []
    for aluno in range(ALUNOS):
        ritmo = math.exp(aleatorio.gauss(math.log(7), 0.5))
        for assunto in aleatorio.sample(assuntos, k=min(7, len(assuntos))):
            dificuldades = [q["dificuldade"] for q in questoes_por_assunto[assunto]]
            dificuldade = sum(dificuldades) / len(dificuldades)
            dominio = aleatorio.betavariate(2.2, 1.4)
            estabilidade = ritmo / (dificuldade**0.6)
            acertos, total = 0, 0
            for revisoes in range(aleatorio.randint(3, 9)):
                dias = min(45.0, max(0.5, aleatorio.expovariate(1 / 9)))
                teto = 0.2 + 0.8 * dominio
                chance = teto * math.exp(-dias / estabilidade)
                lembrou = aleatorio.random() < chance
                # Mesma suavização que o app usa em ServicoAprendizado.
                taxa = (acertos + 1) / (total + 2)
                linhas.append(
                    [aluno, dias, revisoes, dificuldade, taxa, int(lembrou)]
                )
                total += 1
                if lembrou:
                    acertos += 1
                    estabilidade *= 1.45
    return linhas


def gerar_respostas(aleatorio, questoes):
    """Rasch: P(acerto) = sigmoide(θ − b)."""
    reais = {
        q["id"]: (q["dificuldade"] - 2) * 0.8 + aleatorio.gauss(0, 0.35)
        for q in questoes
    }
    linhas = []
    for aluno in range(ALUNOS):
        theta = aleatorio.gauss(0, 1)
        for q in aleatorio.sample(questoes, k=min(30, len(questoes))):
            chance = 1 / (1 + math.exp(-(theta - reais[q["id"]])))
            linhas.append([aluno, q["id"], int(aleatorio.random() < chance)])
    return linhas, reais


def main():
    aleatorio = random.Random(SEMENTE)
    seed = json.loads((PASTA / "seed.json").read_text())
    questoes_por_assunto = {}
    for q in seed["questoes"]:
        questoes_por_assunto.setdefault(q["id_assunto"], []).append(q)

    DADOS.mkdir(exist_ok=True)
    eventos = gerar_eventos(aleatorio, questoes_por_assunto)
    with open(DADOS / "eventos.csv", "w", newline="") as arquivo:
        saida = csv.writer(arquivo)
        saida.writerow(
            [
                "id_aluno",
                "dias_desde_ultimo_estudo",
                "qtd_revisoes",
                "dificuldade",
                "taxa_acerto_aluno",
                "lembrou",
            ]
        )
        saida.writerows(eventos)

    respostas, reais = gerar_respostas(aleatorio, seed["questoes"])
    with open(DADOS / "respostas.csv", "w", newline="") as arquivo:
        saida = csv.writer(arquivo)
        saida.writerow(["id_aluno", "id_questao", "acertou"])
        saida.writerows(respostas)
    (DADOS / "dificuldades_reais.json").write_text(json.dumps(reais))
    print(f"{len(eventos)} eventos, {len(respostas)} respostas")


if __name__ == "__main__":
    main()
