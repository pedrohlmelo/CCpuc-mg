import 'package:flutter/material.dart';

class TelaDetalhe extends StatelessWidget {
  const TelaDetalhe({super.key});

  static const String nome = 'Ler';
  static const String meta = 'Meta: 20 páginas por dia';
  static const IconData icone = Icons.menu_book;
  static const String descricao =
      'Ler diariamente ajuda no foco e na capacidade mental, auxiliando em '
      'atividades do dia a dia. Vinte páginas por dia somam cerca de um livro '
      'por mês, sem precisar de longas sessões de leitura.';

  static const String url =
      'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=800&h=400&fit=crop';

  static const double _alturaImagem = 180;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(nome),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  url,
                  height: _alturaImagem,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, filho, progresso) =>
                      progresso == null
                      ? filho
                      : const _FundoImagem(
                          child: CircularProgressIndicator(),
                        ),
                  errorBuilder: (context, erro, pilha) => _FundoImagem(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 32,
                      color: cores.onPrimaryContainer,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: cores.onPrimary,
                          child: Icon(icone, color: cores.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nome,
                                style: textos.titleLarge?.copyWith(
                                  color: cores.onPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                meta,
                                style: textos.bodyMedium?.copyWith(
                                  color: cores.onPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _Indicador(
                      icone: Icons.today,
                      valor: '5 / 20',
                      rotulo: 'Hoje',
                    ),
                  ),
                  Expanded(
                    child: _Indicador(
                      icone: Icons.local_fire_department,
                      valor: '10',
                      rotulo: 'Sequência',
                    ),
                  ),
                  Expanded(
                    child: _Indicador(
                      icone: Icons.calendar_month,
                      valor: '50%',
                      rotulo: 'Na semana',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sobre o hábito', style: textos.titleMedium),
                      const SizedBox(height: 8),
                      Text(descricao, style: textos.bodyMedium),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}


class _FundoImagem extends StatelessWidget {
  const _FundoImagem({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    height: TelaDetalhe._alturaImagem,
    width: double.infinity,
    color: Theme.of(context).colorScheme.primaryContainer,
    alignment: Alignment.center,
    child: child,
  );
}

class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.icone,
    required this.valor,
    required this.rotulo,
  });

  final IconData icone;
  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: cores.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icone, color: cores.primary),
          const SizedBox(height: 8),
          Text(
            valor,
            style: textos.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            rotulo,
            style: textos.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
