/// Conteúdo que o app traz embutido: o de `dados_exemplo.dart`, ampliado para
/// 14 assuntos de Matemática com 3 questões cada. Roda uma vez, no primeiro
/// uso do banco.
///
/// Este arquivo é Dart puro (não importa Flutter nem sqflite) para que
/// `ferramentas/exportar_seed.dart` consiga exportá-lo para o treino da IA.
library;

import '../dados_exemplo.dart';
import '../modelos.dart';

/// Sobe quando o conteúdo embutido mudar.
const versaoConteudoSeed = 1;

const assuntosNovos = <Assunto>[
  Assunto(id: 8, idMateria: 1, nome: 'Operações básicas'),
  Assunto(id: 9, idMateria: 1, nome: 'Frações'),
  Assunto(id: 10, idMateria: 1, nome: 'Radiciação'),
  Assunto(id: 11, idMateria: 1, nome: 'Porcentagem'),
  Assunto(id: 12, idMateria: 1, nome: 'Função afim'),
  Assunto(id: 13, idMateria: 1, nome: 'Função quadrática'),
  Assunto(id: 14, idMateria: 1, nome: 'Função exponencial'),
  Assunto(id: 15, idMateria: 1, nome: 'Geometria plana'),
  Assunto(id: 16, idMateria: 1, nome: 'Razão e proporção'),
];

const descricoesAssuntos = <int, String>{
  1: 'Produto de fatores iguais e propriedades das potências.',
  2: 'Igualdades com a incógnita no primeiro grau.',
  3: 'Raízes de ax² + bx + c = 0.',
  4: 'Relação entre grandezas, domínio e imagem.',
  5: 'Operação inversa da potenciação.',
  6: 'Movimento de ideias do século XVIII.',
  7: 'Mudanças na produção a partir do século XVIII.',
  8: 'As quatro operações em situações do dia a dia.',
  9: 'Partes de um inteiro e operações com frações.',
  10: 'Raízes e simplificação de radicais.',
  11: 'Partes de cem, aumentos e descontos.',
  12: 'Funções do tipo f(x) = ax + b e seus gráficos.',
  13: 'Parábolas, vértice e pontos de máximo e mínimo.',
  14: 'Crescimento e decaimento por um fator constante.',
  15: 'Áreas e perímetros de figuras planas.',
  16: 'Comparação entre grandezas e regra de três.',
};

/// Arestas novas, somadas às de `dependenciasExemplo`. O conjunto é um DAG:
/// `test/repositorios/seed_test.dart` confere isso.
const dependenciasNovas = <Dependencia>[
  Dependencia(prerequisito: 8, dependente: 9, peso: 0.9),
  Dependencia(prerequisito: 9, dependente: 1, peso: 0.7),
  Dependencia(prerequisito: 1, dependente: 10, peso: 0.8),
  Dependencia(prerequisito: 8, dependente: 2, peso: 0.8),
  Dependencia(prerequisito: 9, dependente: 16, peso: 0.8),
  Dependencia(prerequisito: 16, dependente: 11, peso: 0.9),
  Dependencia(prerequisito: 4, dependente: 12, peso: 0.9),
  Dependencia(prerequisito: 12, dependente: 13, peso: 0.8),
  Dependencia(prerequisito: 3, dependente: 13, peso: 0.7),
  Dependencia(prerequisito: 1, dependente: 14, peso: 0.8),
  Dependencia(prerequisito: 4, dependente: 14, peso: 0.7),
  Dependencia(prerequisito: 14, dependente: 5, peso: 0.8),
  Dependencia(prerequisito: 8, dependente: 15, peso: 0.6),
  Dependencia(prerequisito: 10, dependente: 15, peso: 0.5),
];

Questao _q(
  int id,
  int idAssunto,
  int dificuldade,
  String enunciado,
  String explicacao,
  String gabarito,
  List<String> textos, {
  String? imagem,
  String? descricaoImagem,
}) => Questao(
  id: id,
  idAssunto: idAssunto,
  enunciado: enunciado,
  explicacao: explicacao,
  dificuldade: dificuldade,
  imagemUrl: imagem == null ? null : 'asset:assets/questoes/$imagem',
  imagemDescricao: descricaoImagem,
  alternativas: [
    for (var i = 0; i < textos.length; i++)
      Alternativa(
        letra: 'ABCDE'[i],
        texto: textos[i],
        correta: 'ABCDE'[i] == gabarito,
      ),
  ],
);

final questoesNovas = <Questao>[
  // Potenciação
  _q(
    11,
    1,
    2,
    'Uma cultura de bactérias dobra de tamanho a cada hora. Se ela começa com 3 mil bactérias, quantas haverá depois de 5 horas?',
    'São 5 duplicações: 3 000 · 2⁵ = 3 000 · 32 = 96 000.',
    'C',
    ['15 mil', '48 mil', '96 mil', '192 mil', '243 mil'],
  ),
  // Equação do 1º grau
  _q(
    12,
    2,
    2,
    'Um táxi cobra R\$ 5,00 de bandeirada e R\$ 2,50 por quilômetro rodado. Uma corrida custou R\$ 30,00. Quantos quilômetros foram percorridos?',
    '5 + 2,5x = 30, logo 2,5x = 25 e x = 10.',
    'B',
    ['8', '10', '12', '14', '20'],
  ),
  // Equação do 2º grau
  _q(
    13,
    3,
    2,
    'Um terreno retangular tem 40 m² de área, e o comprimento é 3 m maior que a largura. Qual é a largura, em metros?',
    'x(x + 3) = 40 leva a x² + 3x − 40 = 0, com raízes 5 e −8. A medida positiva é 5.',
    'B',
    ['4', '5', '6', '8', '10'],
  ),
  _q(
    14,
    3,
    3,
    'O lucro de uma fábrica é dado por L(x) = −x² + 10x − 16, em que x é a quantidade produzida. Para quais valores de x o lucro é zero?',
    'x² − 10x + 16 = 0 tem soma 10 e produto 16: as raízes são 2 e 8.',
    'C',
    ['1 e 16', '4 e 6', '2 e 8', '−2 e −8', '3 e 7'],
  ),
  // Funções
  _q(
    15,
    4,
    1,
    'O custo, em reais, para produzir n camisetas é C(n) = 12n + 300. Qual é o custo de produzir 50 camisetas?',
    'C(50) = 12 · 50 + 300 = 600 + 300 = 900.',
    'C',
    ['362', '600', '900', '1 200', '1 500'],
  ),
  // Logaritmo
  _q(
    16,
    5,
    2,
    'O pH de uma solução é pH = −log [H⁺]. Qual é o pH de uma solução com [H⁺] = 10⁻⁴ mol/L?',
    'log 10⁻⁴ = −4, portanto pH = −(−4) = 4.',
    'C',
    ['−4', '0,4', '4', '10', '14'],
  ),
  _q(
    17,
    5,
    3,
    'Um capital evolui segundo M(t) = 1 000 · 2ᵗ, com t em anos. Em quanto tempo ele chega a R\$ 8 000,00?',
    '2ᵗ = 8, então t = log₂ 8 = 3 anos.',
    'B',
    ['2 anos', '3 anos', '4 anos', '6 anos', '8 anos'],
  ),
  // Operações básicas
  _q(
    18,
    8,
    1,
    'Uma caixa com 24 latas custa R\$ 36,00. Qual é o preço de cada lata?',
    '36 ÷ 24 = 1,50.',
    'B',
    ['R\$ 1,20', 'R\$ 1,50', 'R\$ 1,80', 'R\$ 2,00', 'R\$ 2,40'],
  ),
  _q(
    19,
    8,
    2,
    'Uma excursão levará 350 pessoas em ônibus de 42 lugares. Qual é o menor número de ônibus necessário?',
    '350 ÷ 42 ≈ 8,3. Oito ônibus não bastam, então são necessários 9.',
    'C',
    ['7', '8', '9', '10', '12'],
  ),
  _q(
    20,
    8,
    2,
    'Com um salário de R\$ 1 800,00, uma pessoa paga R\$ 650,00 de aluguel e R\$ 430,00 de alimentação. O restante é dividido igualmente em 4 metas. Quanto vai para cada meta?',
    '1 800 − 650 − 430 = 720, e 720 ÷ 4 = 180.',
    'C',
    ['R\$ 120,00', 'R\$ 160,00', 'R\$ 180,00', 'R\$ 240,00', 'R\$ 280,00'],
  ),
  // Frações
  _q(
    21,
    9,
    2,
    'Uma receita usa 3/4 de xícara de açúcar. Quantas xícaras são necessárias para fazer 2 receitas e meia?',
    '3/4 · 5/2 = 15/8 = 1 7/8 xícaras.',
    'C',
    ['1 1/2', '1 3/4', '1 7/8', '2 1/4', '2 1/2'],
  ),
  _q(
    22,
    9,
    1,
    'Em uma turma de 30 estudantes, 2/5 são meninos. Quantas são as meninas?',
    'São 2/5 · 30 = 12 meninos, logo 30 − 12 = 18 meninas.',
    'C',
    ['12', '15', '18', '20', '24'],
  ),
  _q(
    23,
    9,
    2,
    'De um tanque de 60 litros, gastou-se 1/2 do total pela manhã e 1/3 do total à tarde. Quantos litros restaram?',
    '1/2 + 1/3 = 5/6. Resta 1/6 de 60, que são 10 litros.',
    'B',
    ['5', '10', '15', '20', '25'],
  ),
  // Razão e proporção
  _q(
    24,
    16,
    2,
    'Em um mapa na escala 1 : 50 000, duas cidades estão a 8 cm de distância. Qual é a distância real?',
    '8 · 50 000 = 400 000 cm, que são 4 km.',
    'B',
    ['0,4 km', '4 km', '8 km', '40 km', '400 km'],
  ),
  _q(
    25,
    16,
    2,
    'Cinco torneiras iguais enchem um tanque em 6 horas. Em quanto tempo três dessas torneiras enchem o mesmo tanque?',
    'Grandezas inversas: 5 · 6 = 3 · t, então t = 10 horas.',
    'D',
    ['3 h', '6 h', '8 h', '10 h', '12 h'],
  ),
  _q(
    26,
    16,
    1,
    'Uma tinta é feita com 2 partes de azul para 3 de branco. Quantos litros de azul há em 20 litros da mistura?',
    'O azul é 2/5 do total: 2/5 · 20 = 8 litros.',
    'B',
    ['4', '8', '10', '12', '16'],
  ),
  // Porcentagem
  _q(
    27,
    11,
    2,
    'A tabela mostra as vendas de uma loja em cada trimestre. Qual foi o aumento percentual do 1º para o 2º trimestre?',
    'De 200 para 250 são 50 a mais, e 50 ÷ 200 = 25%.',
    'B',
    ['20%', '25%', '30%', '50%', '125%'],
    imagem: 'tabela_vendas.jpg',
    descricaoImagem:
        'Tabela de vendas por trimestre: 1º trimestre 200, 2º trimestre 250, 3º trimestre 300, 4º trimestre 240.',
  ),
  _q(
    28,
    11,
    2,
    'Um produto de R\$ 80,00 teve aumento de 10% e, depois, desconto de 10%. Qual é o preço final?',
    '80 · 1,1 = 88 e 88 · 0,9 = 79,20. Os 10% incidem sobre bases diferentes.',
    'C',
    ['R\$ 72,00', 'R\$ 78,00', 'R\$ 79,20', 'R\$ 80,00', 'R\$ 88,00'],
  ),
  _q(
    29,
    11,
    1,
    'Um salário de R\$ 2 000,00 tem desconto de 15%. Qual é o valor líquido?',
    '15% de 2 000 são 300, e 2 000 − 300 = 1 700.',
    'B',
    [
      'R\$ 1 300,00',
      'R\$ 1 700,00',
      'R\$ 1 750,00',
      'R\$ 1 850,00',
      'R\$ 1 985,00',
    ],
  ),
  // Função afim
  _q(
    30,
    12,
    2,
    'O gráfico representa uma função afim f. Qual é a lei de f?',
    'A reta passa por (0, 2) e (4, 10). A taxa é (10 − 2) ÷ 4 = 2 e o valor inicial é 2: f(x) = 2x + 2.',
    'B',
    [
      'f(x) = x + 2',
      'f(x) = 2x + 2',
      'f(x) = 2x + 4',
      'f(x) = 4x + 2',
      'f(x) = 3x − 2',
    ],
    imagem: 'grafico_funcao_afim.jpg',
    descricaoImagem:
        'Gráfico de uma reta crescente que passa pelos pontos (0, 2) e (4, 10).',
  ),
  _q(
    31,
    12,
    1,
    'Um plano de celular custa R\$ 40,00 fixos mais R\$ 0,50 por minuto. Quanto paga quem usa 100 minutos?',
    'C(100) = 40 + 0,5 · 100 = 90.',
    'B',
    ['R\$ 50,00', 'R\$ 90,00', 'R\$ 100,00', 'R\$ 140,00', 'R\$ 150,00'],
  ),
  _q(
    32,
    12,
    2,
    'Um reservatório com 500 litros perde 20 litros por hora. Em quantas horas ele fica vazio?',
    '500 − 20t = 0, então t = 25 horas.',
    'C',
    ['10', '20', '25', '40', '50'],
  ),
  // Função quadrática
  _q(
    33,
    13,
    3,
    'Qual é o valor mínimo da função f(x) = x² − 6x + 5?',
    'O vértice está em x = 6 ÷ 2 = 3, e f(3) = 9 − 18 + 5 = −4.',
    'B',
    ['−9', '−4', '0', '3', '5'],
  ),
  _q(
    34,
    13,
    3,
    'A altura de uma bola, em metros, é h(t) = −5t² + 20t, com t em segundos. Qual é a altura máxima?',
    'O vértice está em t = 20 ÷ 10 = 2, e h(2) = −20 + 40 = 20 m.',
    'C',
    ['10 m', '15 m', '20 m', '25 m', '40 m'],
  ),
  _q(
    35,
    13,
    3,
    'A receita de uma loja é R(p) = p(100 − p), em que p é o preço. Qual preço dá a maior receita?',
    'As raízes são 0 e 100, e o vértice fica no meio: p = 50.',
    'C',
    ['25', '40', '50', '75', '100'],
  ),
  // Função exponencial
  _q(
    36,
    14,
    1,
    'Uma população é dada por P(t) = 1 000 · 3ᵗ, com t em anos. Qual é a população depois de 3 anos?',
    'P(3) = 1 000 · 27 = 27 000.',
    'C',
    ['3 000', '9 000', '27 000', '30 000', '81 000'],
  ),
  _q(
    37,
    14,
    2,
    'A quantidade de um medicamento no corpo cai pela metade a cada 6 horas. Depois de tomar 80 mg, quanto resta em 18 horas?',
    '18 horas são 3 meias-vidas: 80 → 40 → 20 → 10 mg.',
    'B',
    ['5 mg', '10 mg', '20 mg', '26 mg', '40 mg'],
  ),
  _q(
    38,
    14,
    2,
    'Qual é o valor de x na equação 2ˣ = 64?',
    '64 = 2⁶, portanto x = 6.',
    'C',
    ['3', '4', '6', '8', '32'],
  ),
  // Geometria plana
  _q(
    39,
    15,
    2,
    'A figura mostra o desenho de um canteiro em forma de trapézio, com medidas em metros. Qual é a área do canteiro?',
    'Área do trapézio: (10 + 6) · 4 ÷ 2 = 32 m².',
    'B',
    ['24 m²', '32 m²', '40 m²', '48 m²', '60 m²'],
    imagem: 'figura_trapezio.jpg',
    descricaoImagem:
        'Trapézio com base maior de 10 metros, base menor de 6 metros e altura de 4 metros.',
  ),
  _q(
    40,
    15,
    1,
    'Uma praça circular tem 10 m de raio. Usando π ≈ 3, qual é a área da praça?',
    'A = π · r² ≈ 3 · 100 = 300 m².',
    'D',
    ['30 m²', '60 m²', '100 m²', '300 m²', '600 m²'],
  ),
  _q(
    41,
    15,
    2,
    'Uma escada de 5 m está apoiada em uma parede, com o pé a 3 m da base. A que altura ela toca a parede?',
    'Pitágoras: h² + 3² = 5², logo h² = 16 e h = 4 m.',
    'C',
    ['2 m', '3 m', '4 m', '6 m', '8 m'],
  ),
  // Radiciação
  _q(
    42,
    10,
    2,
    'Qual é a forma simplificada de √72?',
    '√72 = √(36 · 2) = 6√2.',
    'A',
    ['6√2', '8√2', '4√3', '36', '12'],
  ),
  _q(
    43,
    10,
    1,
    'Um terreno quadrado tem 144 m² de área. Qual é o seu perímetro?',
    'O lado é √144 = 12 m, e o perímetro é 4 · 12 = 48 m.',
    'D',
    ['12 m', '24 m', '36 m', '48 m', '72 m'],
  ),
  _q(
    44,
    10,
    1,
    'Qual é o valor de √(16 + 9)?',
    'Primeiro a soma: √25 = 5.',
    'A',
    ['5', '7', '12', '25', '√7'],
  ),
];

final materiasSeed = materiasExemplo;
final assuntosSeed = <Assunto>[...assuntosExemplo, ...assuntosNovos];
final dependenciasSeed = <Dependencia>[
  ...dependenciasExemplo,
  ...dependenciasNovas,
];
final questoesSeed = <Questao>[...questoesExemplo, ...questoesNovas];

/// Grava todo o conteúdo por meio de [inserir], que recebe a tabela e a linha.
void gravarSeed(
  void Function(String tabela, Map<String, Object?> linha) inserir,
) {
  for (final m in materiasSeed) {
    inserir('Materia', {'id': m.id, 'nome': m.nome});
  }
  for (final a in assuntosSeed) {
    inserir('Assunto', {
      'id': a.id,
      'id_materia': a.idMateria,
      'nome': a.nome,
      'descricao': descricoesAssuntos[a.id] ?? '',
    });
  }
  for (final d in dependenciasSeed) {
    inserir('Grafo_Dependencia', {
      'id_prerequisito': d.prerequisito,
      'id_dependente': d.dependente,
      'peso': d.peso,
    });
  }
  for (final q in questoesSeed) {
    inserir('Questao', {
      'id': q.id,
      'id_assunto': q.idAssunto,
      'enunciado': q.enunciado,
      'explicacao': q.explicacao,
      'dificuldade': q.dificuldade,
      'imagem_url': q.imagemUrl,
      'imagem_descricao': q.imagemDescricao,
    });
    for (final a in q.alternativas) {
      inserir('Alternativa', {
        'id_questao': q.id,
        'letra': a.letra,
        'texto': a.texto,
        'correta': a.correta ? 1 : 0,
        'imagem_url': a.imagemUrl,
        'imagem_descricao': a.imagemDescricao,
      });
    }
  }
}
