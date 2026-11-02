/// Modelos usados pelas telas e pelos repositórios.
///
/// São classes simples: quem lê e grava é a camada `repositorios/`, sobre o
/// SQLite do aparelho.
library;

/// Papel de quem entrou. O painel administrativo é de uso interno do grupo:
/// quem entra como aluno não vê que ele existe.
enum TipoUsuario { aluno, admin }

/// Quem está usando o app. Sempre existe alguém: sem conta, é um visitante
/// (sem e-mail), que estuda normalmente e pode virar conta depois.
class Usuario {
  final int id;
  final String? uidFirebase;
  final String nome;
  final String? email;
  final TipoUsuario tipo;

  const Usuario({
    this.id = 0,
    this.uidFirebase,
    required this.nome,
    this.email,
    this.tipo = TipoUsuario.aluno,
  });

  bool get isAdmin => tipo == TipoUsuario.admin;

  /// Visitante é quem ainda não tem conta com e-mail.
  bool get visitante => email == null;

  /// Primeiro nome, para as saudações.
  String get primeiroNome => nome.split(' ').first;
}

class Materia {
  final int id;
  final String nome;
  const Materia({required this.id, required this.nome});
}

/// Tópico de estudo. É também um vértice do grafo de conhecimento.
class Assunto {
  final int id;
  final int idMateria;
  final String nome;
  final String descricao;
  const Assunto({
    required this.id,
    required this.idMateria,
    required this.nome,
    this.descricao = '',
  });
}

class Alternativa {
  final String letra;

  /// Nulo quando a alternativa é só uma imagem.
  final String? texto;
  final bool correta;
  final String? imagemUrl;
  final String? imagemLocal;
  final String? imagemDescricao;

  const Alternativa({
    required this.letra,
    required this.texto,
    required this.correta,
    this.imagemUrl,
    this.imagemLocal,
    this.imagemDescricao,
  });
}

class Questao {
  final int id;
  final int idAssunto;
  final String enunciado;
  final String explicacao;
  final int dificuldade; // 1..3
  final double? dificuldadeCalibrada;
  final String? imagemUrl;
  final String? imagemLocal;
  final String? imagemDescricao;
  final List<Alternativa> alternativas;

  const Questao({
    required this.id,
    required this.idAssunto,
    required this.enunciado,
    required this.explicacao,
    required this.dificuldade,
    required this.alternativas,
    this.dificuldadeCalibrada,
    this.imagemUrl,
    this.imagemLocal,
    this.imagemDescricao,
  });

  Alternativa get gabarito => alternativas.firstWhere((a) => a.correta);
}

/// Aresta `prerequisito → dependente` do grafo de conhecimento.
class Dependencia {
  final int prerequisito;
  final int dependente;
  final double peso;
  const Dependencia({
    required this.prerequisito,
    required this.dependente,
    this.peso = 1.0,
  });
}

/// Uma questão que o aluno já respondeu. É o que a tela de histórico lista e
/// o que permite reabrir a resolução antiga ou refazer a questão.
class Resposta {
  final int idQuestao;
  final String letraEscolhida;
  final bool acertou;
  final DateTime quando;
  final int tempoGasto; // segundos

  const Resposta({
    required this.idQuestao,
    required this.letraEscolhida,
    required this.acertou,
    required this.quando,
    this.tempoGasto = 0,
  });
}

/// Estado da memória de um assunto, para as barras coloridas da tela inicial.
enum EstadoMemoria { consolidado, emRisco, critico, naoEstudado }

/// Faixas de retenção: verde ≥ 0,70; amarelo 0,40–0,70; vermelho < 0,40.
EstadoMemoria estadoDaRetencao(double? retencao) => switch (retencao) {
  null => EstadoMemoria.naoEstudado,
  >= 0.70 => EstadoMemoria.consolidado,
  >= 0.40 => EstadoMemoria.emRisco,
  _ => EstadoMemoria.critico,
};

class SaudeAssunto {
  final int idAssunto;
  final String nome;

  /// 0..1 — sai do modelo de esquecimento.
  final double retencao;
  final EstadoMemoria estado;

  const SaudeAssunto({
    required this.idAssunto,
    required this.nome,
    required this.retencao,
    required this.estado,
  });
}
