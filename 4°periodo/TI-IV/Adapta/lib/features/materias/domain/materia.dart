class Materia {
  final int id;
  final String nome;
  const Materia({required this.id, required this.nome});

  factory Materia.deMapa(Map<String, Object?> m) =>
      Materia(id: m['id'] as int, nome: m['nome'] as String);
}
