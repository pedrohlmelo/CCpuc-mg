import 'package:flutter/material.dart';

/// Poses do Camu, o camaleão do Adapta.
enum PoseCamu { normal, feliz, pensativo }

/// Mascote do app. PNG gerado a partir do vetor em `assets/mascote/`.
class Mascote extends StatelessWidget {
  final PoseCamu pose;
  final double tamanho;

  const Mascote({super.key, this.pose = PoseCamu.normal, this.tamanho = 120});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/mascote/camu_${pose.name}.png',
      width: tamanho,
      height: tamanho,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Camu, o camaleão do Adapta',
    );
  }
}

/// Mascote com animação sutil de "respirar" (sobe e desce). Usar com
/// parcimônia: telas de boas-vindas e feedback.
class MascoteAnimado extends StatefulWidget {
  final PoseCamu pose;
  final double tamanho;

  const MascoteAnimado({
    super.key,
    this.pose = PoseCamu.normal,
    this.tamanho = 140,
  });

  @override
  State<MascoteAnimado> createState() => _MascoteAnimadoState();
}

class _MascoteAnimadoState extends State<MascoteAnimado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, filho) => Transform.translate(
        offset: Offset(0, -4 * Curves.easeInOut.transform(_c.value)),
        child: filho,
      ),
      child: Mascote(pose: widget.pose, tamanho: widget.tamanho),
    );
  }
}
