import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dados/sincronizacao/servico_sincronizacao.dart';
import 'navegacao/rotas.dart';
import 'tema/app_tema.dart';
import 'tema/tema_controller.dart';

class AdaptaApp extends ConsumerWidget {
  const AdaptaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sincronizadorProvider);
    return MaterialApp.router(
      title: 'Adapta',
      theme: temaAdapta(),
      darkTheme: temaAdaptaEscuro(),
      themeMode: ref.watch(temaProvider),
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}
