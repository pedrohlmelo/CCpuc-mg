import 'package:adapta/dados/banco/banco_local.dart';
import 'package:adapta/dados/modelos.dart';
import 'package:adapta/dados/repositorios/aprendizado_repositorio.dart';
import 'package:adapta/dados/repositorios/grafo_repositorio.dart';
import 'package:adapta/dados/repositorios/historico_repositorio.dart';
import 'package:adapta/dados/repositorios/usuario_repositorio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../apoio/app_teste.dart';

void main() {
  late BancoLocal banco;
  late Usuario usuario;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    banco = bancoDeTeste();
    usuario = await UsuarioRepositorio(banco).criarVisitante();
  });

  tearDown(() => banco.fechar());

  Future<List<Map<String, Object?>>> linhas(String tabela) async =>
      (await banco.db).query(tabela);

  test('resposta gravada volta na lista e fica pendente', () async {
    final repositorio = HistoricoRepositorio(banco);
    await repositorio.registrar(
      idUsuario: usuario.id,
      idQuestao: 1,
      letra: 'B',
      acertou: true,
      tempoGasto: 12,
    );

    final lista = await repositorio.listar(usuario.id);
    expect(lista.single.idQuestao, 1);
    expect(lista.single.acertou, isTrue);
    expect(lista.single.tempoGasto, 12);

    final linha = (await linhas('Historico_Estudo')).single;
    expect(linha['sincronizado'], 0);
    expect(linha['atualizado_em'], isNotNull);
    expect((linha['id'] as String).length, 36);
  });

  test('o histórico de um usuário não aparece para outro', () async {
    final outro = await UsuarioRepositorio(banco).criarVisitante();
    final repositorio = HistoricoRepositorio(banco);
    await repositorio.registrar(
      idUsuario: usuario.id,
      idQuestao: 1,
      letra: 'B',
      acertou: true,
      tempoGasto: 1,
    );
    expect(await repositorio.listar(outro.id), isEmpty);
  });

  test('memória e proficiência sobrescrevem e ficam pendentes', () async {
    final repositorio = AprendizadoRepositorio(banco);
    final dia = DateTime(2026, 11, 1);
    for (final retencao in [0.5, 0.8]) {
      await repositorio.salvarMemoria(
        usuario.id,
        NivelMemoria(
          idAssunto: 1,
          retencao: retencao,
          ultimoEstudo: dia,
          qtdRevisoes: 2,
        ),
      );
    }
    await repositorio.salvarProficiencia(usuario.id, 1, 0.4);

    expect((await repositorio.memorias(usuario.id)).single.retencao, 0.8);
    expect(await repositorio.proficiencias(usuario.id), {1: 0.4});
    expect((await linhas('Nivel_Memoria')).single['sincronizado'], 0);
    expect((await linhas('Proficiencia')).single['sincronizado'], 0);
  });

  test('aresta adicionada e removida no grafo', () async {
    final repositorio = GrafoRepositorio(banco);
    final antes = (await repositorio.listar()).length;
    await repositorio.adicionar(
      const Dependencia(prerequisito: 11, dependente: 15, peso: 0.3),
    );
    expect(await repositorio.listar(), hasLength(antes + 1));
    await repositorio.remover(11, 15);
    expect(await repositorio.listar(), hasLength(antes));
  });
}
