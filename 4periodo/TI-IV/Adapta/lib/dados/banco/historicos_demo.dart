/// Históricos de ~30 dias usados nos testes dos modelos e da fila.
library;

import 'dart:math';

import '../modelos.dart';
import 'pacote_inicial.g.dart';

enum PerfilDemo { ana, bruno }

/// Só as questões do pacote inicial: a demonstração funciona offline, e as
/// outras mudam quando o banco cresce.
final _idsDoPacote = {for (final q in pacoteInicialQuestoes) q['id'] as int};

/// Estudo de um assunto: em quantos dias atrás e com que taxa de acerto.
class _Roteiro {
  final int idAssunto;
  final List<int> diasAtras;
  final double taxaAcerto;
  const _Roteiro(this.idAssunto, this.diasAtras, this.taxaAcerto);
}

/// Ana erra Razão e proporção e, por isso, Estequiometria: a lacuna atravessa
/// matérias. Vai bem em História e Inglês.
const _roteiroAna = [
  _Roteiro(8, [28, 20, 8], 0.9),
  _Roteiro(9, [27, 18, 6], 0.85),
  _Roteiro(16, [25, 14, 6, 2], 0.2),
  _Roteiro(706, [22, 10, 4], 0.8),
  _Roteiro(6, [20, 9, 3], 0.8),
  _Roteiro(1101, [19, 8, 3], 0.85),
  _Roteiro(701, [15, 7, 1], 0.1),
];

/// Bruno vai bem em tudo, mas não vê Funções há quase um mês.
const _roteiroBruno = [
  _Roteiro(8, [29, 15, 3], 0.95),
  _Roteiro(9, [28, 14, 3], 0.95),
  _Roteiro(1, [26, 12, 2], 0.9),
  _Roteiro(2, [25, 11, 2], 0.95),
  _Roteiro(3, [22, 10, 1], 0.9),
  _Roteiro(4, [29, 27], 0.85),
  _Roteiro(6, [18, 6, 1], 0.9),
  _Roteiro(1101, [17, 6, 1], 0.9),
  _Roteiro(801, [16, 5, 1], 0.9),
];

/// Gera as respostas do perfil, da mais antiga para a mais recente. A semente
/// é fixa: a demonstração sai igual em todo aparelho.
List<Resposta> historicoDemo(
  PerfilDemo perfil,
  List<Questao> todas,
  DateTime agora,
) {
  final aleatorio = Random(perfil == PerfilDemo.ana ? 7 : 11);
  final respostas = <Resposta>[];

  for (final roteiro
      in perfil == PerfilDemo.ana ? _roteiroAna : _roteiroBruno) {
    final questoes = todas
        .where(
          (q) =>
              q.idAssunto == roteiro.idAssunto && _idsDoPacote.contains(q.id),
        )
        .toList();
    for (final dias in roteiro.diasAtras) {
      for (var i = 0; i < questoes.length; i++) {
        final questao = questoes[i];
        final acertou = aleatorio.nextDouble() < roteiro.taxaAcerto;
        final errada = questao.alternativas.firstWhere((a) => !a.correta);
        respostas.add(
          Resposta(
            idQuestao: questao.id,
            letraEscolhida: acertou ? questao.gabarito.letra : errada.letra,
            acertou: acertou,
            quando: agora
                .subtract(Duration(days: dias))
                .add(Duration(minutes: i * 3)),
            tempoGasto: 40 + aleatorio.nextInt(120),
          ),
        );
      }
    }
  }
  return respostas..sort((a, b) => a.quando.compareTo(b.quando));
}
