import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/sessao_controller.dart';
import 'moldura_auth.dart';

/// RF01 — login.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  String? _erro;
  bool _carregando = false;
  bool _mostrarSenha = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    final ok = await ref
        .read(sessaoProvider.notifier)
        .entrar(_email.text, _senha.text);
    if (!mounted) return;
    setState(() {
      _carregando = false;
      if (!ok) _erro = 'E-mail ou senha inválidos.';
    });
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
            if (_erro != null) ...[
              const SizedBox(height: 14),
              KeyedSubtree(
                key: const Key('erro_login'),
                child: MensagemErro(_erro!),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton(
              key: const Key('botao_entrar'),
              onPressed: _carregando ? null : _entrar,
              child: _carregando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Entrar'),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Primeira vez por aqui?', style: texto.bodyMedium),
                TextButton(
                  onPressed: () => context.go('/cadastro'),
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
