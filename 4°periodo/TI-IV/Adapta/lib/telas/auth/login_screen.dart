import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dados/estado_prototipo.dart';
import 'moldura_auth.dart';

/// Tela de login (RF01). Aqui ela só valida o formulário e volta para o app:
/// não há autenticação, que é trabalho do backend.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _mostrarSenha = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  void _entrar() {
    if (!_form.currentState!.validate()) return;
    final apelido = _email.text.split('@').first.trim();
    ref.read(nomeAlunoProvider.notifier).state = apelido.isEmpty
        ? 'Bruno'
        : apelido[0].toUpperCase() + apelido.substring(1);
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
      titulo: 'Bem-vindo de volta',
      subtitulo: 'Um app que sabe o que você precisa estudar hoje.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('campo_email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
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
              obscureText: !_mostrarSenha,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _mostrarSenha
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _mostrarSenha = !_mostrarSenha),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Informe a senha' : null,
              onFieldSubmitted: (_) => _entrar(),
            ),
            const SizedBox(height: 22),
            FilledButton(
              key: const Key('botao_entrar'),
              onPressed: _entrar,
              child: const Text('Entrar'),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Primeira vez por aqui?', style: texto.bodyMedium),
                TextButton(
                  onPressed: () => context.pushReplacement('/cadastro'),
                  child: const Text('Criar conta'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
