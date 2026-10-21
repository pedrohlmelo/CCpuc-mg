class Exercicio {
  const Exercicio({
    required this.nome,
    required this.musculo,
    required this.equipamento,
  });

  final String nome;
  final String musculo;
  final String equipamento;

  factory Exercicio.fromMap(Map<String, Object?> m) {
    final traducoes = m['translations'] as List<dynamic>? ?? [];
    final musculos = m['muscles'] as List<dynamic>? ?? [];
    final equipamentos = m['equipment'] as List<dynamic>? ?? [];

    final traducao = traducoes.cast<Map<String, Object?>?>().firstWhere(
      (t) => t?['language'] == 2,
      orElse: () => null,
    );
    final primeiroMusculo = musculos.isEmpty
        ? null
        : musculos.first as Map<String, Object?>;
    final primeiroEquipamento = equipamentos.isEmpty
        ? null
        : equipamentos.first as Map<String, Object?>;

    final popular = primeiroMusculo?['name_en'] as String? ?? '';

    return Exercicio(
      nome: traducao?['name'] as String? ?? '(sem nome)',
      musculo: popular.isNotEmpty
          ? popular
          : primeiroMusculo?['name'] as String? ?? 'músculo não informado',
      equipamento:
          primeiroEquipamento?['name'] as String? ??
          'equipamento não informado',
    );
  }
}
