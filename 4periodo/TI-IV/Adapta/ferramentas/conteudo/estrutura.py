#!/usr/bin/env python3
"""Matérias, assuntos e arestas do Adapta: grava materias/* e as arestas entre matérias.

    python estrutura.py [--simular] [--forcar]

Sem --forcar, só cria as matérias que ainda não existem no Firestore: o painel admin
do app edita matérias, assuntos e arestas, e este script não pode desfazer isso.
Com --forcar, sobrescreve tudo com o que está neste arquivo (inclusive as arestas
entre matérias de meta/conteudo).

Os ids nunca mudam: o progresso dos alunos aponta para eles. Ver README.md.
"""
import argparse

import comum

# (id, nome, área, [(id do assunto, nome, descrição)])
MATERIAS = [
    (1, 'Matemática', 'matematica', [
        (1, 'Potenciação', 'Produto de fatores iguais e propriedades das potências.'),
        (2, 'Equação do 1º grau', 'Igualdades com a incógnita no primeiro grau.'),
        (3, 'Equação do 2º grau', 'Raízes de ax² + bx + c = 0.'),
        (4, 'Funções', 'Relação entre grandezas, domínio e imagem.'),
        (5, 'Logaritmo', 'Operação inversa da potenciação.'),
        (8, 'Operações básicas', 'As quatro operações em situações do dia a dia.'),
        (9, 'Frações', 'Partes de um inteiro e operações com frações.'),
        (10, 'Radiciação', 'Raízes e simplificação de radicais.'),
        (11, 'Porcentagem', 'Partes de cem, aumentos e descontos.'),
        (12, 'Função afim', 'Funções do tipo f(x) = ax + b e seus gráficos.'),
        (13, 'Função quadrática', 'Parábolas, vértice e pontos de máximo e mínimo.'),
        (14, 'Função exponencial', 'Crescimento e decaimento por um fator constante.'),
        (15, 'Geometria plana', 'Áreas e perímetros de figuras planas.'),
        (16, 'Razão e proporção', 'Comparação entre grandezas e regra de três.'),
        (101, 'Probabilidade', 'Chance de um evento e eventos combinados.'),
        (102, 'Estatística', 'Médias, mediana, moda e leitura de gráficos e tabelas.'),
        (103, 'Análise combinatória', 'Princípio da contagem, arranjos e combinações.'),
        (104, 'Geometria espacial', 'Volumes e áreas de sólidos.'),
        (105, 'Trigonometria', 'Razões no triângulo e funções periódicas.'),
        (106, 'Progressões', 'Sequências aritméticas e geométricas.'),
    ]),
    (2, 'História', 'humanas', [
        (6, 'Iluminismo', 'Movimento de ideias do século XVIII.'),
        (7, 'Revolução Industrial', 'Mudanças na produção a partir do século XVIII.'),
        (201, 'Antiguidade e Idade Média', 'Sociedades antigas e o mundo medieval.'),
        (202, 'Brasil Colônia e Império', 'Colonização, escravidão e formação do Estado.'),
        (203, 'Brasil República', 'Da República Velha à ditadura e à redemocratização.'),
        (204, 'Mundo no século XX', 'Guerras mundiais, totalitarismos e Guerra Fria.'),
    ]),
    (3, 'Geografia', 'humanas', [
        (301, 'Cartografia', 'Escalas, projeções e leitura de mapas.'),
        (302, 'Clima e relevo', 'Dinâmicas climáticas, solos e formas do relevo.'),
        (303, 'Urbanização e população', 'Cidades, migrações e dados demográficos.'),
        (304, 'Geopolítica e globalização', 'Conflitos, blocos e fluxos globais.'),
        (305, 'Questão ambiental', 'Impactos, recursos naturais e sustentabilidade.'),
        (306, 'Agropecuária e indústria', 'Espaço agrário, energia e produção.'),
    ]),
    (4, 'Filosofia', 'humanas', [
        (401, 'Filosofia antiga', 'Pré-socráticos, Sócrates, Platão e Aristóteles.'),
        (402, 'Filosofia moderna', 'Racionalismo, empirismo e Kant.'),
        (403, 'Ética', 'Valores, dever e responsabilidade.'),
        (404, 'Filosofia política', 'Contratualismo, poder e Estado.'),
    ]),
    (5, 'Sociologia', 'humanas', [
        (501, 'Pensadores clássicos', 'Durkheim, Marx e Weber.'),
        (502, 'Cultura e identidade', 'Etnocentrismo, diversidade e indústria cultural.'),
        (503, 'Trabalho e desigualdade', 'Classes, relações de trabalho e exclusão.'),
        (504, 'Cidadania e movimentos sociais', 'Direitos, participação e democracia.'),
    ]),
    (6, 'Física', 'natureza', [
        (601, 'Cinemática', 'Velocidade, aceleração e gráficos do movimento.'),
        (602, 'Dinâmica', 'Leis de Newton, forças e hidrostática.'),
        (603, 'Energia e termologia', 'Trabalho, potência, calor e conservação da energia.'),
        (604, 'Eletricidade', 'Circuitos, potência elétrica e consumo.'),
        (605, 'Ondulatória e óptica', 'Ondas, som e luz.'),
    ]),
    (7, 'Química', 'natureza', [
        (701, 'Estequiometria', 'Cálculo das quantidades em reações.'),
        (702, 'Soluções e equilíbrio', 'Concentração, pH e equilíbrio químico.'),
        (703, 'Química orgânica', 'Funções, cadeias e reações do carbono.'),
        (704, 'Termoquímica', 'Calor nas reações e combustíveis.'),
        (705, 'Eletroquímica', 'Pilhas, eletrólise e oxirredução.'),
        (706, 'Atomística e ligações', 'Estrutura do átomo, tabela periódica e ligações.'),
    ]),
    (8, 'Biologia', 'natureza', [
        (801, 'Citologia', 'Célula, metabolismo e divisão celular.'),
        (802, 'Genética', 'Hereditariedade, DNA e biotecnologia.'),
        (803, 'Evolução', 'Seleção natural e origem das espécies.'),
        (804, 'Ecologia', 'Cadeias, ciclos e relações entre seres vivos.'),
        (805, 'Fisiologia humana', 'Sistemas do corpo e saúde.'),
        (806, 'Seres vivos', 'Diversidade, vírus, bactérias, plantas e animais.'),
    ]),
    (9, 'Língua Portuguesa', 'linguagens', [
        (901, 'Interpretação de texto', 'Tese, argumento e sentido global.'),
        (902, 'Gêneros textuais', 'Finalidade e forma dos textos.'),
        (903, 'Variação linguística', 'Usos da língua e norma-padrão.'),
        (904, 'Funções da linguagem', 'Intenção comunicativa do texto.'),
        (905, 'Gramática em contexto', 'Recursos linguísticos e coesão.'),
    ]),
    (10, 'Literatura', 'linguagens', [
        (1001, 'Escolas literárias', 'Do Barroco ao Realismo.'),
        (1002, 'Modernismo', 'Vanguardas e literatura brasileira moderna.'),
        (1003, 'Literatura contemporânea', 'Prosa e poesia atuais.'),
        (1004, 'Análise de poemas', 'Recursos poéticos e construção de sentido.'),
    ]),
    (11, 'Inglês', 'linguagens', [
        (1101, 'Interpretação de texto em inglês', 'Ideia central e finalidade do texto.'),
        (1102, 'Vocabulário em contexto (inglês)', 'Sentido de palavras e expressões.'),
    ]),
    (12, 'Espanhol', 'linguagens', [
        (1201, 'Interpretação de texto em espanhol', 'Ideia central e finalidade do texto.'),
        (1202, 'Vocabulário em contexto (espanhol)', 'Sentido de palavras e expressões.'),
    ]),
    (13, 'Artes', 'linguagens', [
        (1301, 'Artes visuais', 'Pintura, escultura e vanguardas.'),
        (1302, 'Música e artes cênicas', 'Teatro, dança e música.'),
        (1303, 'Arte e cultura popular', 'Patrimônio e manifestações brasileiras.'),
        (1304, 'Arte contemporânea', 'Intervenções, performance e tecnologia.'),
    ]),
    (14, 'Educação Física', 'linguagens', [
        (1401, 'Corpo, saúde e exercício', 'Atividade física e qualidade de vida.'),
        (1402, 'Esporte e sociedade', 'Mídia, inclusão e regras.'),
        (1403, 'Dança e cultura corporal', 'Jogos, lutas e práticas corporais.'),
        (1404, 'Padrões de beleza e corpo', 'Estética, consumo e identidade.'),
    ]),
]

# (pré-requisito, dependente, peso)
ARESTAS = [
    (11, 102, 0.6), (8, 103, 0.7), (103, 101, 0.9), (9, 101, 0.6),
    (15, 104, 0.9), (15, 105, 0.7), (4, 105, 0.5), (12, 106, 0.6),
    (14, 106, 0.5), (2, 3, 0.9), (2, 4, 0.8), (3, 5, 0.6),
    (4, 5, 0.7), (1, 5, 1.0), (8, 9, 0.9), (9, 1, 0.7),
    (1, 10, 0.8), (8, 2, 0.8), (9, 16, 0.8), (16, 11, 0.9),
    (4, 12, 0.9), (12, 13, 0.8), (3, 13, 0.7), (1, 14, 0.8),
    (4, 14, 0.7), (14, 5, 0.8), (8, 15, 0.6), (10, 15, 0.5),
    (201, 6, 0.3), (6, 7, 0.8), (6, 202, 0.4), (7, 204, 0.6),
    (202, 203, 0.8), (204, 203, 0.4), (301, 302, 0.5), (301, 304, 0.4),
    (303, 304, 0.6), (302, 305, 0.7), (306, 305, 0.6), (303, 306, 0.5),
    (401, 402, 0.7), (401, 403, 0.6), (403, 404, 0.5), (402, 404, 0.5),
    (501, 502, 0.5), (501, 503, 0.7), (503, 504, 0.6), (601, 602, 0.9),
    (602, 603, 0.8), (603, 604, 0.6), (601, 605, 0.5), (706, 701, 0.8),
    (701, 702, 0.8), (706, 703, 0.6), (701, 704, 0.7), (702, 705, 0.6),
    (801, 802, 0.8), (802, 803, 0.8), (803, 806, 0.5), (806, 804, 0.6),
    (801, 805, 0.7), (901, 902, 0.8), (902, 904, 0.7), (901, 903, 0.6),
    (901, 905, 0.5), (1001, 1002, 0.8), (1002, 1003, 0.7), (1004, 1002, 0.4),
    (1101, 1102, 0.6), (1201, 1202, 0.6), (1301, 1304, 0.6), (1303, 1302, 0.4),
    (1401, 1402, 0.4), (1403, 1404, 0.4), (16, 701, 0.7), (16, 702, 0.6),
    (12, 601, 0.7), (13, 601, 0.5), (12, 604, 0.5), (11, 303, 0.5),
    (102, 303, 0.5), (16, 301, 0.6), (14, 804, 0.4), (101, 802, 0.6),
    (706, 801, 0.4), (704, 603, 0.4), (604, 705, 0.4), (804, 305, 0.6),
    (7, 501, 0.4), (6, 404, 0.5), (204, 304, 0.5), (901, 1001, 0.7),
    (901, 1004, 0.6), (901, 1101, 0.6), (901, 1201, 0.6),
]


def validar():
    assuntos = [a[0] for m in MATERIAS for a in m[3]]
    assert len({m[0] for m in MATERIAS}) == len(MATERIAS), "matéria repetida"
    assert len(set(assuntos)) == len(assuntos), "assunto repetido"
    assert all(m[2] in comum.AREAS for m in MATERIAS), "área inválida"
    assert all(p in assuntos and d in assuntos for p, d, _ in ARESTAS), "aresta sem assunto"
    assert not comum.tem_ciclo(assuntos, [(p, d) for p, d, _ in ARESTAS]), "o grafo tem ciclo"


def documentos():
    """Aresta dentro de uma matéria fica nela; entre matérias, em meta/conteudo."""
    materia_do_assunto = {a[0]: m[0] for m in MATERIAS for a in m[3]}
    docs = {
        i: {"id": i, "nome": nome, "area": area,
            "assuntos": [{"id": a, "nome": n, "descricao": d} for a, n, d in assuntos],
            "dependencias": []}
        for i, nome, area, assuntos in MATERIAS
    }
    entre_materias = []
    for pre, dep, peso in ARESTAS:
        aresta = {"pre": pre, "dep": dep, "peso": peso}
        if materia_do_assunto[pre] == materia_do_assunto[dep]:
            docs[materia_do_assunto[pre]]["dependencias"].append(aresta)
        else:
            entre_materias.append(aresta)
    return docs, entre_materias


def main():
    args = argparse.ArgumentParser()
    args.add_argument("--simular", action="store_true")
    args.add_argument("--forcar", action="store_true",
                      help="sobrescreve o que o painel admin mudou no Firestore")
    args = args.parse_args()

    validar()
    db = comum.conectar(args.simular)
    docs, entre_materias = documentos()
    atuais = comum.ler_colecao(db, "materias")
    if args.forcar:
        mudaram = {i: d for i, d in docs.items() if atuais.get(str(i)) != d}
    else:
        mudaram = {i: d for i, d in docs.items() if str(i) not in atuais}
        ignoradas = sum(1 for i, d in docs.items() if str(i) in atuais and atuais[str(i)] != d)
        if ignoradas:
            print(f"{ignoradas} matérias diferem do Firestore e ficaram como estão "
                  "(podem ter sido editadas no painel admin; use --forcar para sobrescrever)")
    comum.gravar_lotes(db, "materias", mudaram, args.simular)
    print(f"{len(docs)} matérias ({len(mudaram)} gravadas), "
          f"{sum(len(d['assuntos']) for d in docs.values())} assuntos, {len(ARESTAS)} arestas, "
          f"{len(entre_materias)} entre matérias")
    meta = db.collection("meta").document("conteudo").get().to_dict() if db else None
    arestas_atuais = (meta or {}).get("dependencias_entre_materias")
    trocar_arestas = arestas_atuais != entre_materias and (args.forcar or not arestas_atuais)
    if mudaram or trocar_arestas:
        extras = {"dependencias_entre_materias": entre_materias} if trocar_arestas else {}
        comum.subir_versao(db, comum.Relogio(), args.simular, **extras)


if __name__ == "__main__":
    main()
