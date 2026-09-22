/// Modelos de apresentação do protótipo.
///
/// São classes simples, só com o que as telas precisam desenhar. Não há
/// persistência, consulta nem regra de negócio aqui: isso é responsabilidade
/// do backend (Java + Spring), que ainda não existe. Quando ele chegar, estes
/// modelos passam a ser preenchidos pela resposta da API.
library;

class Materia {
  final int id;
  final String nome;
  const Materia({required this.id, required this.nome});
}

/// Tópico de estudo. No projeto final é também um vértice do grafo.
class Assunto {
  final int id;
  final int idMateria;
  final String nome;
  const Assunto({
    required this.id,
    required this.idMateria,
    required this.nome,
  });
}

class Alternativa {
  final String letra;
  final String texto;
  final bool correta;
  const Alternativa({
    required this.letra,
    required this.texto,
    required this.correta,
  });
}

class Questao {
  final int id;
  final int idAssunto;
  final String enunciado;
  final String explicacao;
  final int dificuldade; // 1..5
  final List<Alternativa> alternativas;

  const Questao({
    required this.id,
    required this.idAssunto,
    required this.enunciado,
    required this.explicacao,
    required this.dificuldade,
    required this.alternativas,
  });

  Alternativa get gabarito => alternativas.firstWhere((a) => a.correta);
}

/// Aresta `prerequisito → dependente` mostrada na tela do grafo (admin).
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
  final DateTime quando;

  const Resposta({
    required this.idQuestao,
    required this.letraEscolhida,
    required this.quando,
  });
}

/// Estado da memória de um assunto, para as barras coloridas da tela inicial.
enum EstadoMemoria { consolidado, emRisco, critico, naoEstudado }

class SaudeAssunto {
  final int idAssunto;
  final String nome;

  /// 0..1 — valor de exemplo. No projeto final vem do previsor de esquecimento.
  final double retencao;
  final EstadoMemoria estado;

  const SaudeAssunto({
    required this.idAssunto,
    required this.nome,
    required this.retencao,
    required this.estado,
  });
}
