import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dados/estado_prototipo.dart';
import '../../widgets/mascote.dart';
import 'moldura_auth.dart';

/// Tela de cadastro (RF01). Valida o formulário e volta para o app; o cadastro
/// de verdade é trabalho do backend.
class CadastroScreen extends ConsumerStatefulWidget {
  const CadastroScreen({super.key});

  @override
  ConsumerState<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends ConsumerState<CadastroScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  void _cadastrar() {
    if (!_form.currentState!.validate()) return;
    final primeiro = _nome.text.trim().split(' ').first;
    ref.read(nomeAlunoProvider.notifier).state = primeiro;
    ref.read(entrouProvider.notifier).state = true;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
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
            FilledButton(
              key: const Key('botao_cadastrar'),
              onPressed: _cadastrar,
              child: const Text('Cadastrar'),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Já tem conta?', style: texto.bodyMedium),
                TextButton(
                  onPressed: () => context.pushReplacement('/login'),
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
