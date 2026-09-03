import 'alternativa.dart';

class Questao {
  final int id;
  final int idAssunto;
  final String enunciado;
  final String? explicacao;

  /// Dificuldade declarada pelo autor (1..5). A dificuldade *real* será
  /// inferida pelo Pilar 1 a partir do histórico.
  final int dificuldade;
  final List<Alternativa> alternativas;

  const Questao({
    required this.id,
    required this.idAssunto,
    required this.enunciado,
    required this.dificuldade,
    this.explicacao,
    this.alternativas = const [],
  });

  Alternativa get gabarito => alternativas.firstWhere((a) => a.correta);

  factory Questao.deMapa(
    Map<String, Object?> m, {
    List<Alternativa> alternativas = const [],
  }) => Questao(
    id: m['id'] as int,
    idAssunto: m['id_assunto'] as int,
    enunciado: m['enunciado'] as String,
    explicacao: m['explicacao'] as String?,
    dificuldade: m['dificuldade'] as int,
    alternativas: alternativas,
  );
}
