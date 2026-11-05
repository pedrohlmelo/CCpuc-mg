import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dados/modelos.dart';
import '../../dados/repositorios/admin_conteudo_repositorio.dart';
import '../../dados/repositorios/conteudo_repositorio.dart';
import '../../widgets/cartoes.dart';
import 'admin_scaffold.dart';

/// Banco de questões (RF11): filtros por matéria e assunto, busca e as não
/// revisadas. Tocar numa questão abre o formulário.
class AdminQuestoesScreen extends ConsumerStatefulWidget {
  const AdminQuestoesScreen({super.key});

  @override
  ConsumerState<AdminQuestoesScreen> createState() =>
      _AdminQuestoesScreenState();
}

class _AdminQuestoesScreenState extends ConsumerState<AdminQuestoesScreen> {
  int? _idMateria;
  int? _idAssunto;
  String _busca = '';
  bool _naoRevisadas = false;
  bool _inativos = false;

  List<Questao> _filtrar(Conteudo c) {
    final busca = _busca.trim().toLowerCase();
    final assuntosDaMateria = _idMateria == null
        ? null
        : c.todosAssuntos
              .where((a) => a.idMateria == _idMateria)
              .map((a) => a.id)
              .toSet();
    return [
      for (final q in _inativos ? c.todasQuestoes : c.questoes)
        if ((assuntosDaMateria == null ||
                assuntosDaMateria.contains(q.idAssunto)) &&
            (_idAssunto == null || q.idAssunto == _idAssunto) &&
            (!_naoRevisadas || !q.revisado) &&
            (busca.isEmpty ||
                q.enunciado.toLowerCase().contains(busca) ||
                '${q.id}' == busca ||
                (q.fonte ?? '').toLowerCase().contains(busca)))
          q,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final conteudo = ref.watch(conteudoProvider).valueOrNull;
    final questoes = conteudo == null ? const <Questao>[] : _filtrar(conteudo);
    final assuntos = _idMateria == null || conteudo == null
        ? const <Assunto>[]
        : conteudo.assuntosDaMateria(_idMateria!);

    return AdminScaffold(
      titulo: 'Questões',
      subtitulo: 'Cada questão pertence a um assunto',
      rotuloAdicionar: 'Nova questão',
      aoAdicionar: () => context.push('/admin/questoes/nova'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: TextField(
              key: const Key('busca_questoes'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Buscar no enunciado, id ou fonte',
                isDense: true,
              ),
              onChanged: (v) => setState(() => _busca = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    key: const Key('filtro_materia'),
                    initialValue: _idMateria,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Matéria',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      for (final m in conteudo?.materias ?? const <Materia>[])
                        DropdownMenuItem(
                          value: m.id,
                          child: Text(m.nome, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      _idMateria = v;
                      _idAssunto = null;
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    key: ValueKey('filtro_assunto_$_idMateria'),
                    initialValue: _idAssunto,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Assunto',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      for (final a in assuntos)
                        DropdownMenuItem(
                          value: a.id,
                          child: Text(a.nome, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: _idMateria == null
                        ? null
                        : (v) => setState(() => _idAssunto = v),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Row(
              children: [
                FilterChip(
                  key: const Key('chip_nao_revisadas'),
                  label: const Text('Não revisadas'),
                  selected: _naoRevisadas,
                  onSelected: (v) => setState(() => _naoRevisadas = v),
                ),
                const SizedBox(width: 8),
                ChipInativos(
                  valor: _inativos,
                  aoMudar: (v) => setState(() => _inativos = v),
                ),
                const Spacer(),
                Text(
                  '${questoes.length}',
                  key: const Key('total_questoes_filtradas'),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: questoes.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CartaoQuestao(
                  questao: questoes[i],
                  conteudo: conteudo!,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoQuestao extends ConsumerWidget {
  final Questao questao;
  final Conteudo conteudo;
  const _CartaoQuestao({required this.questao, required this.conteudo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = questao;
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final ativa = conteudo.questoes.any((x) => x.id == q.id);

    return acinzentar(
      !ativa,
      AppCartao(
        key: Key('questao_${q.id}'),
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        aoTocar: () => context.push('/admin/questoes/${q.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: _Etiqueta(
                    conteudo.nomeDoAssunto(q.idAssunto),
                    scheme.primary,
                  ),
                ),
                const SizedBox(width: 6),
                _Etiqueta('Dif. ${q.dificuldade}/3', scheme.onSurfaceVariant),
                if (!q.revisado) ...[
                  const SizedBox(width: 6),
                  const _Etiqueta('Não revisada', Color(0xFFD97706)),
                ],
                const Spacer(),
                IconePendente(q.pendente),
                Text('#${q.id}', style: texto.labelSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              q.enunciado,
              style: texto.titleSmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Gabarito: ${q.alternativas.where((a) => a.correta).map((a) => a.letra).join()}'
                    '${q.fonte == null ? '' : ' · ${q.fonte}'}',
                    style: texto.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!q.ativo)
                  TextButton(
                    key: Key('reativar_questao_${q.id}'),
                    onPressed: () => executarAdmin(
                      context,
                      ref,
                      () => ref
                          .read(adminConteudoRepositorioProvider)
                          .definirQuestaoAtiva(q.id, true),
                    ),
                    child: const Text('Reativar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  final Color cor;
  const _Etiqueta(this.texto, this.cor);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: cor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      texto,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cor),
    ),
  );
}
