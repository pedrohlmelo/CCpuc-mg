class Habito {
  final String nome;
  final String meta;
  final String icone;

  const Habito(this.nome, this.meta, {this.icone = 'padrao'});

  static bool nomeValido(String nome) => nome.trim().length >= 3;

  static bool metaValida(String meta) => meta.trim().isNotEmpty;
}
