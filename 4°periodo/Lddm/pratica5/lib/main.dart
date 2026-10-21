import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'exercicio.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ExerciciosStore(ExerciciosApi()),
      child: const MaterialApp(
        title: 'Pernas de Corredor',
        home: TelaExercicios(),
      ),
    ),
  );
}

class ExerciciosApi {
  static const _base = 'https://wger.de/api/v2';

  Future<List<Exercicio>> carregar() async {
    final url = Uri.parse('$_base/exerciseinfo/?category=9&limit=300');
    final resposta = await http.get(url).timeout(const Duration(seconds: 15));

    if (resposta.statusCode != 200) {
      throw Exception('O servidor respondeu ${resposta.statusCode}');
    }

    final Map<String, dynamic> pagina = jsonDecode(resposta.body);
    final List<dynamic> bruto = pagina['results'];
    return bruto
        .map((m) => Exercicio.fromMap(m as Map<String, Object?>))
        .toList();
  }
}

enum Estado { carregando, pronto, erro }

class ExerciciosStore extends ChangeNotifier {
  ExerciciosStore(this._repo) {
    carregar();
  }
  final ExerciciosApi _repo;

  List<Exercicio> _exercicios = [];
  Estado estado = Estado.carregando;
  String? mensagemErro;
  List<Exercicio> get exercicios => List.unmodifiable(_exercicios);

  Future<void> carregar() async {
    estado = Estado.carregando;
    notifyListeners();
    try {
      _exercicios = await _repo.carregar();
      _exercicios.sort((a, b) => a.nome.compareTo(b.nome));
      estado = Estado.pronto;
    } catch (e) {
      estado = Estado.erro;
      mensagemErro = 'Não foi possível carregar os exercícios.';
    }
    notifyListeners();
  }
}

class TelaExercicios extends StatelessWidget {
  const TelaExercicios({super.key});

  @override
  Widget build(BuildContext context) {
    final loja = context.watch<ExerciciosStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pernas de Corredor'),
        actions: [
          IconButton(
            tooltip: 'Recarregar',
            icon: const Icon(Icons.refresh),
            onPressed: () => loja.carregar(),
          ),
        ],
      ),
      body: switch (loja.estado) {
        Estado.carregando => const Center(child: CircularProgressIndicator()),
        Estado.erro => TelaDeErro(
          mensagem: loja.mensagemErro!,
          aoTentarDeNovo: () => loja.carregar(),
        ),
        Estado.pronto =>
          loja.exercicios.isEmpty
              ? const TelaVazia()
              : ListaDeExercicios(itens: loja.exercicios),
      },
    );
  }
}

class TelaDeErro extends StatelessWidget {
  const TelaDeErro({
    super.key,
    required this.mensagem,
    required this.aoTentarDeNovo,
  });

  final String mensagem;
  final VoidCallback aoTentarDeNovo;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(mensagem),
        FilledButton(
          onPressed: aoTentarDeNovo,
          child: const Text('Tentar de novo'),
        ),
      ],
    ),
  );
}

class TelaVazia extends StatelessWidget {
  const TelaVazia({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Nenhum exercício encontrado.'));
}

class ListaDeExercicios extends StatelessWidget {
  const ListaDeExercicios({super.key, required this.itens});

  final List<Exercicio> itens;

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: itens.length,
    itemBuilder: (_, i) => ListTile(
      leading: const Icon(Icons.directions_run),
      title: Text(itens[i].nome),
      subtitle: Text('${itens[i].musculo} · ${itens[i].equipamento}'),
    ),
  );
}
