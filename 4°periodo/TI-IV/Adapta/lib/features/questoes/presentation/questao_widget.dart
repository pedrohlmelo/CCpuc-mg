import 'package:flutter/material.dart';

import '../../../core/tema/app_tema.dart';
import '../../../core/widgets/cartoes.dart';
import '../../../core/widgets/mascote.dart';
import '../domain/alternativa.dart';
import '../domain/questao.dart';

/// RF04 / RF05 — enunciado + alternativas; após a escolha, feedback imediato
/// com explicação e o Camu reagindo.
class QuestaoWidget extends StatefulWidget {
  final Questao questao;
  final Future<void> Function(bool acertou) aoResponder;
  final VoidCallback aoAvancar;

  const QuestaoWidget({
    super.key,
    required this.questao,
    required this.aoResponder,
    required this.aoAvancar,
  });

  @override
  State<QuestaoWidget> createState() => _QuestaoWidgetState();
}

class _QuestaoWidgetState extends State<QuestaoWidget> {
  Alternativa? _escolhida;
  bool get _respondida => _escolhida != null;

  Future<void> _escolher(Alternativa alt) async {
    if (_respondida) return;
    setState(() => _escolhida = alt);
    await widget.aoResponder(alt.correta);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questao;
    final texto = Theme.of(context).textTheme;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Row(children: [_Dificuldade(nivel: q.dificuldade)]),
              const SizedBox(height: 14),
              AppCartao(
                padding: const EdgeInsets.all(20),
                child: Text(
                  q.enunciado,
                  style: texto.titleLarge?.copyWith(height: 1.4),
                ),
              ),
              const SizedBox(height: 18),
              for (final alt in q.alternativas) ...[
                _Alternativa(
                  alternativa: alt,
                  estado: _estadoDe(alt),
                  aoTocar: _respondida ? null : () => _escolher(alt),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (filho, anim) => SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(anim),
            child: filho,
          ),
          child: !_respondida
              ? const SizedBox.shrink()
              : _Feedback(
                  acertou: _escolhida!.correta,
                  gabarito: q.gabarito.letra,
                  explicacao: q.explicacao,
                  aoAvancar: widget.aoAvancar,
                ),
        ),
      ],
    );
  }

  _EstadoAlternativa _estadoDe(Alternativa alt) {
    if (!_respondida) return _EstadoAlternativa.neutra;
    if (alt.correta) return _EstadoAlternativa.correta;
    if (alt == _escolhida) return _EstadoAlternativa.errada;
    return _EstadoAlternativa.apagada;
  }
}

enum _EstadoAlternativa { neutra, correta, errada, apagada }

class _Alternativa extends StatelessWidget {
  final Alternativa alternativa;
  final _EstadoAlternativa estado;
  final VoidCallback? aoTocar;

  const _Alternativa({
    required this.alternativa,
    required this.estado,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    final (
      Color borda,
      Color fundo,
      Color badge,
      Color badgeTexto,
      IconData? icone,
    ) = switch (estado) {
      _EstadoAlternativa.neutra => (
        scheme.outline,
        scheme.surface,
        scheme.surfaceContainer,
        scheme.onSurface,
        null,
      ),
      _EstadoAlternativa.correta => (
        CoresMemoria.consolidado,
        CoresMemoria.consolidado.withValues(alpha: 0.08),
        CoresMemoria.consolidado,
        Colors.white,
        Icons.check_rounded,
      ),
      _EstadoAlternativa.errada => (
        CoresMemoria.critico,
        CoresMemoria.critico.withValues(alpha: 0.08),
        CoresMemoria.critico,
        Colors.white,
        Icons.close_rounded,
      ),
      _EstadoAlternativa.apagada => (
        scheme.outline,
        scheme.surface,
        scheme.surfaceContainer,
        scheme.onSurfaceVariant,
        null,
      ),
    };

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: estado == _EstadoAlternativa.apagada ? 0.55 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borda,
            width: estado == _EstadoAlternativa.neutra ? 1 : 1.8,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('alternativa_${alternativa.letra}'),
            onTap: aoTocar,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: badge,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: icone != null
                        ? Icon(icone, color: badgeTexto, size: 20)
                        : Text(
                            alternativa.letra,
                            style: texto.labelLarge?.copyWith(
                              color: badgeTexto,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(alternativa.texto, style: texto.bodyLarge),
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

class _Dificuldade extends StatelessWidget {
  final int nivel;
  const _Dificuldade({required this.nivel});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Dificuldade', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(width: 8),
          for (var i = 1; i <= 5; i++)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= nivel ? scheme.primary : scheme.outline,
              ),
            ),
        ],
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  final bool acertou;
  final String gabarito;
  final String? explicacao;
  final VoidCallback aoAvancar;

  const _Feedback({
    required this.acertou,
    required this.gabarito,
    required this.explicacao,
    required this.aoAvancar,
  });

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final cor = acertou ? CoresMemoria.consolidado : CoresMemoria.critico;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: cor, width: 3)),
        boxShadow: sombraSuave(context),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Mascote(
                    pose: acertou ? PoseCamu.feliz : PoseCamu.pensativo,
                    tamanho: 56,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          acertou ? 'Mandou bem!' : 'Quase lá.',
                          key: const Key('feedback_resposta'),
                          style: texto.titleLarge?.copyWith(color: cor),
                        ),
                        Text(
                          acertou
                              ? 'Resposta correta.'
                              : 'A alternativa certa era a $gabarito.',
                          style: texto.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (explicacao != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 18,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(explicacao!, style: texto.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton(
                key: const Key('botao_proxima'),
                style: FilledButton.styleFrom(backgroundColor: cor),
                onPressed: aoAvancar,
                child: const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
