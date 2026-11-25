import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../sensores/detector_balanco.dart';
import '../widgets/questao_relampago.dart';

/// Moldura das três abas do aluno: Início, Histórico e Perfil.
///
/// A barra de baixo é a navegação principal do app. Telas que abrem por cima
/// (matérias, sessão, login, painel admin) ficam fora desta moldura e sempre
/// têm botão de voltar.
///
/// Balançar o celular nas abas abre a questão relâmpago. Com outra tela por
/// cima (sessão, login, admin, o próprio painel), o gesto é ignorado.
class CascaAluno extends ConsumerStatefulWidget {
  final StatefulNavigationShell shell;
  const CascaAluno({required this.shell, super.key});

  @override
  ConsumerState<CascaAluno> createState() => _CascaAlunoState();
}

class _CascaAlunoState extends ConsumerState<CascaAluno> {
  StreamSubscription<void>? _balancos;
  bool _abrindo = false;

  @override
  void initState() {
    super.initState();
    _balancos = ref.read(balancoProvider).listen((_) => _aoBalancar());
  }

  @override
  void dispose() {
    _balancos?.cancel();
    super.dispose();
  }

  Future<void> _aoBalancar() async {
    final noTopo = ModalRoute.of(context)?.isCurrent ?? true;
    if (_abrindo || !noTopo) return;
    _abrindo = true;
    try {
      await abrirQuestaoRelampago(context, ref);
    } finally {
      _abrindo = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    final naInicial = shell.currentIndex == 0;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: shell,
      // O botão principal só aparece na aba Início e fica sempre acima da
      // barra de navegação.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: !naInicial
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('botao_estudar'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    elevation: 6,
                    shadowColor: scheme.primary.withValues(alpha: 0.4),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Estudar agora'),
                  onPressed: () => context.push('/sessao'),
                ),
              ),
            ),
      bottomNavigationBar: NavigationBar(
        key: const Key('barra_navegacao'),
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            key: Key('aba_historico'),
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_toggle_off_rounded),
            label: 'Histórico',
          ),
          NavigationDestination(
            key: Key('aba_perfil'),
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
