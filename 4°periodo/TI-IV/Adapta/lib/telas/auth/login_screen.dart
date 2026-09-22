import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dados/estado_prototipo.dart';
import '../../dados/modelos.dart';
import 'moldura_auth.dart';

/// Tela de login (RF01). Aqui ela só valida o formulário e volta para o app:
/// não há autenticação, que é trabalho do backend.
///
/// [apos] é a rota que a pessoa tentou abrir antes de entrar, como `/sessao`.
/// Existindo, é para lá que ela segue ao entrar, no lugar de voltar.
class LoginScreen extends ConsumerStatefulWidget {
  final String? apos;
  const LoginScreen({this.apos, super.key});

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
    final email = _email.text.trim();
    final apelido = email.split('@').first;
    // Sem backend, o papel sai do e-mail. Quem confere credenciais e devolve
    // o tipo do usuário é o servidor, quando ele existir.
    final admin = email.toLowerCase() == emailAdminDemo;
    ref.read(usuarioProvider.notifier).state = Usuario(
      nome: admin
          ? 'Administração'
          : apelido.isEmpty
          ? 'Aluno'
          : apelido[0].toUpperCase() + apelido.substring(1),
      email: email,
      tipo: admin ? TipoUsuario.admin : TipoUsuario.aluno,
    );

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
                  onPressed: () => context.pushReplacement(
                    widget.apos == null
                        ? '/cadastro'
                        : '/cadastro?apos=${widget.apos}',
                  ),
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
