import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dados/modelos.dart';
import '../../dados/repositorios/admin_conteudo_repositorio.dart';
import '../../dados/repositorios/conteudo_repositorio.dart';
import '../../dados/sincronizacao/servico_sincronizacao.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/imagem_questao.dart';
import 'admin_scaffold.dart';

/// Formulário de questão (RF11). [idQuestao] nulo cria uma nova.
class AdminQuestaoFormScreen extends ConsumerWidget {
  final int? idQuestao;
  const AdminQuestaoFormScreen({super.key, this.idQuestao});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conteudo = ref.watch(conteudoProvider).valueOrNull;
    if (conteudo == null) {
      return const AdminScaffold(titulo: 'Questão', child: Carregando());
    }
    final questao = idQuestao == null
        ? null
        : conteudo.questaoPorId(idQuestao!);
    if (idQuestao != null && questao == null) {
      return const AdminScaffold(
        titulo: 'Questão',
        child: Center(child: Text('Questão não encontrada.')),
      );
    }
    return _Formulario(conteudo: conteudo, questao: questao);
  }
}

class _CamposAlternativa {
  final texto = TextEditingController();
  final imagem = TextEditingController();
}

class _Formulario extends ConsumerStatefulWidget {
  final Conteudo conteudo;
  final Questao? questao;
  const _Formulario({required this.conteudo, required this.questao});

  @override
  ConsumerState<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends ConsumerState<_Formulario> {
  final _enunciado = TextEditingController();
  final _imagem = TextEditingController();
  final _imagemDescricao = TextEditingController();
  final _explicacao = TextEditingController();
  final _fonte = TextEditingController(text: fonteAutoral);
  final _alternativas = {
    for (final l in letrasAlternativas) l: _CamposAlternativa(),
  };
  int? _idMateria;
  int? _idAssunto;
  String? _correta;
  int _dificuldade = 2;
  bool _revisada = true;
  bool _ativa = true;
  bool _salvando = false;
  Map<String, String> _erros = const {};

  @override
  void initState() {
    super.initState();
    final q = widget.questao;
    if (q == null) {
      _idMateria = widget.conteudo.materias.firstOrNull?.id;
      return;
    }
    _idAssunto = q.idAssunto;
    _idMateria = widget.conteudo.assuntoPorId(q.idAssunto)?.idMateria;
    _enunciado.text = q.enunciado;
    _imagem.text = q.imagemUrl ?? '';
    _imagemDescricao.text = q.imagemDescricao ?? '';
    _explicacao.text = q.explicacao;
    _fonte.text = q.fonte ?? fonteAutoral;
    _dificuldade = q.dificuldade;
    _revisada = q.revisado;
    _ativa = q.ativo;
    for (final a in q.alternativas) {
      final campos = _alternativas[a.letra];
      if (campos == null) continue;
      campos.texto.text = a.texto ?? '';
      campos.imagem.text = a.imagemUrl ?? '';
      if (a.correta) _correta = a.letra;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _enunciado,
      _imagem,
      _imagemDescricao,
      _explicacao,
      _fonte,
      for (final a in _alternativas.values) ...[a.texto, a.imagem],
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Questao _montar() {
    final anterior = widget.questao;
    return Questao(
      id: anterior?.id ?? 0,
      idAssunto: _idAssunto ?? 0,
      enunciado: _enunciado.text,
      explicacao: _explicacao.text,
      dificuldade: _dificuldade,
      imagemUrl: _imagem.text,
      imagemDescricao: _imagemDescricao.text,
      fonte: _fonte.text,
      revisado: _revisada,
      ativo: _ativa,
      alternativas: [
        for (final MapEntry(key: letra, value: c) in _alternativas.entries)
          Alternativa(
            letra: letra,
            texto: c.texto.text,
            imagemUrl: c.imagem.text,
            imagemDescricao: anterior?.alternativas
                .where((a) => a.letra == letra)
                .firstOrNull
                ?.imagemDescricao,
            correta: letra == _correta,
          ),
      ],
    );
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      await ref.read(adminConteudoRepositorioProvider).salvarQuestao(_montar());
    } on ErroAdmin catch (erro) {
      if (!mounted) return;
      setState(() {
        _erros = erro.campos;
        _salvando = false;
      });
      avisar(context, erro.mensagem, erro: true);
      return;
    }
    final online = await ref.read(conectividadeProvider).online();
    if (!mounted) return;
    avisar(
      context,
      online ? 'Salvo' : 'Salvo no aparelho; envio à nuvem pendente',
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/admin/questoes');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conteudo;
    final texto = Theme.of(context).textTheme;
    final assuntos = _idMateria == null
        ? const <Assunto>[]
        : c.assuntosDaMateria(_idMateria!);
    final assuntoValido = assuntos.any((a) => a.id == _idAssunto);

    return AdminScaffold(
      titulo: widget.questao == null
          ? 'Nova questão'
          : 'Questão #${widget.questao!.id}',
      subtitulo: widget.questao?.pendente ?? false
          ? 'Envio à nuvem pendente'
          : null,
      child: ListView(
        key: const Key('formulario_questao'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          DropdownButtonFormField<int>(
            key: const Key('campo_materia'),
            initialValue: _idMateria,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Matéria'),
            items: [
              for (final m in c.materias)
                DropdownMenuItem(value: m.id, child: Text(m.nome)),
            ],
            onChanged: (v) => setState(() {
              _idMateria = v;
              _idAssunto = null;
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: ValueKey('campo_assunto_$_idMateria'),
            initialValue: assuntoValido ? _idAssunto : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Assunto',
              errorText: _erros['assunto'],
            ),
            items: [
              for (final a in assuntos)
                DropdownMenuItem(value: a.id, child: Text(a.nome)),
            ],
            onChanged: (v) => setState(() => _idAssunto = v),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('campo_enunciado'),
            controller: _enunciado,
            minLines: 3,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Enunciado',
              alignLabelWithHint: true,
              errorText: _erros['enunciado'],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('campo_imagem'),
            controller: _imagem,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'URL da imagem do enunciado (opcional)',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('campo_imagem_descricao'),
            controller: _imagemDescricao,
            decoration: const InputDecoration(labelText: 'Descrição da imagem'),
            onChanged: (_) => setState(() {}),
          ),
          if (_imagem.text.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            ImagemQuestao(
              key: ValueKey(_imagem.text.trim()),
              url: _imagem.text.trim(),
              descricao: _imagemDescricao.text.trim().isEmpty
                  ? null
                  : _imagemDescricao.text.trim(),
              alturaMaxima: 160,
            ),
          ],
          const SizedBox(height: 20),
          Text('Alternativas', style: texto.titleSmall),
          if (_erros['alternativas'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _erros['alternativas']!,
                key: const Key('erro_alternativas'),
                style: texto.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          RadioGroup<String>(
            groupValue: _correta,
            onChanged: (v) => setState(() => _correta = v),
            child: Column(
              children: [
                for (final MapEntry(key: letra, value: campos)
                    in _alternativas.entries)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Radio<String>(
                            key: Key('correta_$letra'),
                            value: letra,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              TextField(
                                key: Key('alternativa_$letra'),
                                controller: campos.texto,
                                minLines: 1,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: '$letra)',
                                  isDense: true,
                                  errorText: _erros['alternativa_$letra'],
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                key: Key('alternativa_imagem_$letra'),
                                controller: campos.imagem,
                                keyboardType: TextInputType.url,
                                decoration: const InputDecoration(
                                  labelText: 'URL de imagem (opcional)',
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('campo_explicacao'),
            controller: _explicacao,
            minLines: 2,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Explicação',
              alignLabelWithHint: true,
              errorText: _erros['explicacao'],
            ),
          ),
          const SizedBox(height: 16),
          Text('Dificuldade', style: texto.labelLarge),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            key: const Key('campo_dificuldade'),
            segments: const [
              ButtonSegment(value: 1, label: Text('1 · Fácil')),
              ButtonSegment(value: 2, label: Text('2 · Média')),
              ButtonSegment(value: 3, label: Text('3 · Difícil')),
            ],
            selected: {_dificuldade},
            onSelectionChanged: (v) => setState(() => _dificuldade = v.first),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('campo_fonte'),
            controller: _fonte,
            decoration: const InputDecoration(labelText: 'Fonte'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const Key('campo_revisada'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Revisada'),
            value: _revisada,
            onChanged: (v) => setState(() => _revisada = v),
          ),
          SwitchListTile(
            key: const Key('campo_ativa'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Ativa'),
            subtitle: const Text('Inativa some do app do aluno'),
            value: _ativa,
            onChanged: (v) => setState(() => _ativa = v),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('salvar_questao'),
            onPressed: _salvando ? null : _salvar,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
