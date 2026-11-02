import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Botão de voltar das telas que abrem por cima das abas.
///
/// Sempre há saída: se não houver tela anterior na pilha (por exemplo quando
/// alguém abre a rota direto), volta para a tela inicial do aluno.
class BotaoVoltar extends StatelessWidget {
  final String rotaDeFallback;
  final IconData icone;
  final String dica;

  const BotaoVoltar({
    super.key,
    this.rotaDeFallback = '/',
    this.icone = Icons.arrow_back_rounded,
    this.dica = 'Voltar',
  });

  /// Variante com "×", para telas que se fecham (como a sessão de estudo).
  const BotaoVoltar.fechar({
    super.key,
    this.rotaDeFallback = '/',
    this.icone = Icons.close_rounded,
    this.dica = 'Fechar',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('botao_voltar'),
      tooltip: dica,
      icon: Icon(icone),
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(rotaDeFallback);
        }
      },
    );
  }
}
