/// Tópico de estudo. É também um vértice do grafo de conhecimento.
class Assunto {
  final int id;
  final int idMateria;
  final String nome;
  final String? descricao;

  const Assunto({
    required this.id,
    required this.idMateria,
    required this.nome,
    this.descricao,
  });

  factory Assunto.deMapa(Map<String, Object?> m) => Assunto(
    id: m['id'] as int,
    idMateria: m['id_materia'] as int,
    nome: m['nome'] as String,
    descricao: m['descricao'] as String?,
  );
}
