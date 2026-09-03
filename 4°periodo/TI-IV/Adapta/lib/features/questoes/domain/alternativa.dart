class Alternativa {
  final int id;
  final int idQuestao;
  final String letra;
  final String texto;
  final bool correta;

  const Alternativa({
    required this.id,
    required this.idQuestao,
    required this.letra,
    required this.texto,
    required this.correta,
  });

  factory Alternativa.deMapa(Map<String, Object?> m) => Alternativa(
    id: m['id'] as int,
    idQuestao: m['id_questao'] as int,
    letra: m['letra'] as String,
    texto: m['texto'] as String,
    correta: (m['correta'] as int) == 1,
  );
}
