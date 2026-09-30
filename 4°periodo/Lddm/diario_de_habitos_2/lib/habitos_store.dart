import 'package:flutter/material.dart';

class Habito {
  final String nome;
  final String meta;
  final IconData icone;

  const Habito(this.nome, this.meta, this.icone);
}

class HabitosStore extends ChangeNotifier {
  final List<Habito> _habitos = [
    const Habito('Beber água', 'Meta: 8 copos por dia', Icons.local_drink),
    const Habito('Ler', 'Meta: 20 páginas por dia', Icons.menu_book),
    const Habito('Caminhar', 'Meta: 30 minutos por dia', Icons.directions_walk),
    const Habito('Dormir cedo', 'Meta: antes das 23h', Icons.bedtime),
  ];

  List<Habito> get habitos => List.unmodifiable(_habitos);

  void adicionar(Habito h) {
    _habitos.add(h);
    notifyListeners();
  }

  void remover(Habito h) {
    _habitos.remove(h);
    notifyListeners();
  }
}
