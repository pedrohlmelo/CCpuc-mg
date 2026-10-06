import 'package:flutter/foundation.dart';

import '../dados/habitos_repositorio.dart';
import 'habito.dart';

class HabitosStore extends ChangeNotifier {
  HabitosStore(this._repo);

  final HabitosRepositorio _repo;
  List<Habito> _habitos = [];

  List<Habito> get habitos => List.unmodifiable(_habitos);

  int get total => _habitos.length;

  Future<void> carregar() async {
    _habitos = await _repo.carregar();
    notifyListeners();
  }

  Future<void> adicionar(Habito h) async {
    await _repo.salvar(h);
    _habitos = await _repo.carregar();
    notifyListeners();
  }

  Future<void> remover(Habito h) async {
    await _repo.remover(h);
    _habitos = await _repo.carregar();
    notifyListeners();
  }
}
