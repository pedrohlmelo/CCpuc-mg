class Habito {
  const Habito({
    this.id,
    required this.nome,
    required this.meta,
    this.icone = 'padrao',
  });

  final int? id; 
  final String nome;
  final String meta;
  final String icone;

  Map<String, Object?> toMap() =>
      {'id': id, 'nome': nome, 'meta': meta, 'icone': icone};

  factory Habito.fromMap(Map<String, Object?> m) => Habito(
    id: m['id'] as int?,
    nome: m['nome'] as String,
    meta: m['meta'] as String,
    icone: m['icone'] as String,
  );

  static bool nomeValido(String nome) => nome.trim().length >= 3;

  static bool metaValida(String meta) => meta.trim().isNotEmpty;
}
