import 'package:flutter/material.dart';

import '../../../core/tema/app_tema.dart';
import '../../../core/widgets/marca.dart';
import '../../../core/widgets/mascote.dart';

/// Moldura das telas de login e cadastro: topo com gradiente, mascote e
/// marca; corpo em painel claro arredondado que ocupa o resto da tela.
class MolduraAuth extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Widget child;
  final PoseCamu pose;

  const MolduraAuth({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.child,
    this.pose = PoseCamu.normal,
  });

  static const _alturaCabecalho = 196.0;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppCores.indigo,
      body: Container(
        decoration: const BoxDecoration(gradient: AppCores.gradienteMarca),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: _alturaCabecalho,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 20, 24, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const MarcaAdapta(cor: Colors.white),
                                const SizedBox(height: 10),
                                Text(
                                  subtitulo,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: texto.bodyLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          MascoteAnimado(pose: pose, tamanho: 112),
                        ],
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (c.maxHeight - _alturaCabecalho).clamp(
                        0.0,
                        double.infinity,
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(titulo, style: texto.headlineMedium),
                                const SizedBox(height: 20),
                                child,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mensagem de erro inline padronizada.
class MensagemErro extends StatelessWidget {
  final String texto;
  const MensagemErro(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
