import '../dominio/habito.dart';

class HabitosRepositorio {
  final List<Habito> _memoria = [
    const Habito('Beber água', 'Meta: 8 copos por dia', icone: 'agua'),
    const Habito('Ler', 'Meta: 20 páginas por dia', icone: 'leitura'),
    const Habito('Caminhar', 'Meta: 30 minutos por dia', icone: 'caminhada'),
    const Habito('Dormir cedo', 'Meta: antes das 23h', icone: 'sono'),
  ];

  Future<List<Habito>> carregar() async => List.of(_memoria);

  Future<void> salvar(Habito h) async {
    _memoria.add(h);
  }

  Future<void> remover(Habito h) async {
    _memoria.remove(h);
  }

  Future<void> arquivar(Habito h) async {
    if (_memoria.remove(h)) {
      _memoria.add(h);
    }
  }

}
