enum TipoUsuario {
  aluno,
  admin;

  static TipoUsuario deTexto(String valor) =>
      values.firstWhere((t) => t.name == valor, orElse: () => aluno);
}

class Usuario {
  final int id;
  final String nome;
  final String email;
  final TipoUsuario tipo;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.tipo = TipoUsuario.aluno,
  });

  bool get isAdmin => tipo == TipoUsuario.admin;

  factory Usuario.deMapa(Map<String, Object?> m) => Usuario(
    id: m['id'] as int,
    nome: m['nome'] as String,
    email: m['email'] as String,
    tipo: TipoUsuario.deTexto(m['tipo'] as String),
  );
}
