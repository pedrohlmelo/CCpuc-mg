/// Históricos de ~30 dias usados nos testes dos modelos e da fila.
library;

import 'dart:math';

import '../modelos.dart';
import 'seed.dart';

enum PerfilDemo { ana, bruno }

/// Estudo de um assunto: em quantos dias atrás e com que taxa de acerto.
class _Roteiro {
  final int idAssunto;
  final List<int> diasAtras;
  final double taxaAcerto;
  const _Roteiro(this.idAssunto, this.diasAtras, this.taxaAcerto);
}

/// Ana erra muito Logaritmo e Potenciação; o resto vai bem.
const _roteiroAna = [
  _Roteiro(8, [28, 20, 8], 0.9),
  _Roteiro(9, [27, 18, 6], 0.85),
  _Roteiro(1, [25, 14, 6, 2], 0.2),
  _Roteiro(2, [24, 12, 3], 0.8),
  _Roteiro(4, [22, 10, 4], 0.8),
  _Roteiro(3, [20, 9, 3], 0.75),
  _Roteiro(5, [15, 7, 1], 0.1),
];

/// Bruno vai bem em tudo, mas não vê Funções há quase um mês.
const _roteiroBruno = [
  _Roteiro(8, [29, 15, 3], 0.95),
  _Roteiro(9, [28, 14, 3], 0.95),
  _Roteiro(1, [26, 12, 2], 0.9),
  _Roteiro(2, [25, 11, 2], 0.95),
  _Roteiro(3, [22, 10, 1], 0.9),
  _Roteiro(4, [29, 27], 0.85),
  _Roteiro(14, [18, 6, 1], 0.9),
  _Roteiro(5, [17, 6, 1], 0.9),
  _Roteiro(15, [16, 5, 1], 0.9),
];

/// Gera as respostas do perfil, da mais antiga para a mais recente. A semente
/// é fixa: a demonstração sai igual em todo aparelho.
List<Resposta> historicoDemo(PerfilDemo perfil, DateTime agora) {
  final aleatorio = Random(perfil == PerfilDemo.ana ? 7 : 11);
  final respostas = <Resposta>[];

  for (final roteiro
      in perfil == PerfilDemo.ana ? _roteiroAna : _roteiroBruno) {
    final questoes = questoesSeed
        .where((q) => q.idAssunto == roteiro.idAssunto)
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
