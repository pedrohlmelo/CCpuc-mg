import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'habitos_store.dart';

class TelaNovoHabito extends StatefulWidget {
  const TelaNovoHabito({super.key});

  @override
  State<TelaNovoHabito> createState() => _TelaNovoHabitoState();
}

class _TelaNovoHabitoState extends State<TelaNovoHabito> {
  final _chave = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _meta = TextEditingController();

  @override
  void dispose() {
    _nome.dispose();
    _meta.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Novo hábito')),
    body: Form(
      key: _chave,
      child: Column(
        children: [
          TextFormField(
            controller: _nome,
            decoration: const InputDecoration(labelText: 'Nome'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Informe o nome';
              if (v.trim().length < 3) return 'Use ao menos 3 letras';
              return null;
            },
          ),
          TextFormField(
            controller: _meta,
            decoration: const InputDecoration(labelText: 'Meta'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Informe a meta';
              return null;
            },
          ),
          FilledButton(
            onPressed: () {
              if (_chave.currentState!.validate()) {
                context.read<HabitosStore>().adicionar(
                  Habito(_nome.text, _meta.text, Icons.check_circle),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ),
  );
}
