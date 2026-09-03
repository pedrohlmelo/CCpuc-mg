import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tema/tema_controller.dart';

/// Ícone sol/lua que alterna o tema claro/escuro, com giro e fade na troca.
class BotaoTema extends ConsumerWidget {
  /// Cor do ícone; por padrão segue a AppBar/tema. Use branco em cabeçalhos
  /// com gradiente.
  final Color? cor;

  const BotaoTema({super.key, this.cor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(temaProvider);
    final escuro = ref.read(temaProvider.notifier).estaEscuro(context);

    return IconButton(
      key: const Key('botao_tema'),
      tooltip: escuro ? 'Tema claro' : 'Tema escuro',
      color: cor,
      onPressed: () => ref.read(temaProvider.notifier).alternar(context),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => RotationTransition(
          turns: Tween(begin: 0.75, end: 1.0).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(
          escuro ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          key: ValueKey(escuro),
        ),
      ),
    );
  }
}
