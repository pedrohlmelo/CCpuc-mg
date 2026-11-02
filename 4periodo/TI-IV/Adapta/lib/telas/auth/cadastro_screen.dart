import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dados/estado_app.dart';
import '../../dados/repositorios/usuario_repositorio.dart';
import '../../widgets/mascote.dart';
import 'moldura_auth.dart';

/// Tela de cadastro (RF01). A conta nasce do visitante atual, mantendo o
/// progresso dele.
///
/// [apos] é a rota que a pessoa tentou abrir antes de criar a conta.
class CadastroScreen extends ConsumerStatefulWidget {
  final String? apos;
  const CadastroScreen({this.apos, super.key});

  @override
  ConsumerState<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends ConsumerState<CadastroScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (_enviando || !_form.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      // Cadastro pelo app cria aluno; contas do grupo são criadas por fora.
      await ref
          .read(sessaoProvider.notifier)
          .cadastrar(_nome.text.trim(), _email.text.trim(), _senha.text);
    } on ErroConta catch (erro) {
      if (mounted) {
        setState(() {
          _enviando = false;
          _erro = erro.mensagem;
        });
      }
      return;
    }

    // A navegação espera o próximo frame: preencher a sessão faz o go_router
    // reavaliar as rotas, e sair antes disso desfaria a saída desta tela.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final destino = widget.apos;
      if (destino != null && destino.isNotEmpty) {
        context.pushReplacement(Uri.decodeComponent(destino));
      } else if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return MolduraAuth(
      titulo: 'Criar conta',
      subtitulo: 'Em poucos toques o Camu monta sua fila de estudo.',
      pose: PoseCamu.feliz,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('campo_nome'),
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('campo_email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('campo_senha'),
              controller: _senha,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha',
                helperText: 'Mínimo de 6 caracteres',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Mínimo de 6 caracteres' : null,
              onFieldSubmitted: (_) => _cadastrar(),
            ),
            const SizedBox(height: 22),
            if (_erro != null) ...[
              Text(
                _erro!,
                key: const Key('erro_conta'),
                style: texto.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton(
              key: const Key('botao_cadastrar'),
              onPressed: _enviando ? null : _cadastrar,
              child: const Text('Cadastrar'),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Já tem conta?', style: texto.bodyMedium),
                TextButton(
                  onPressed: () => context.pushReplacement(
                    widget.apos == null
                        ? '/login'
                        : '/login?apos=${widget.apos}',
                  ),
                  child: const Text('Entrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
