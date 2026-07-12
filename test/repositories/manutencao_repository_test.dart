import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/manutencao.dart';
import 'package:revisacar/repositories/manutencao_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ManutencaoRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = ManutencaoRepository(firestore);
  });

  test('add/watchAll são escopados por veiculoId', () async {
    final manutencao = Manutencao(
      id: '',
      veiculoId: 'v1',
      tipo: TipoManutencao.trocaOleo,
      dataRealizada: DateTime(2026, 1, 1),
      kmNaData: 40000,
      custo: 200.0,
      oficina: 'Oficina',
      observacoes: '',
    );

    await repository.add('uid1', manutencao, veiculoId: 'v1');
    final listaV1 = await repository.watchAll('uid1', veiculoId: 'v1').first;
    final listaV2 = await repository.watchAll('uid1', veiculoId: 'v2').first;

    expect(listaV1, hasLength(1));
    expect(listaV1.first.veiculoId, 'v1');
    expect(listaV2, isEmpty);
  });

  test('getAll retorna todas as manutenções daquele veículo', () async {
    final manutencao1 = Manutencao(
      id: '',
      veiculoId: 'v1',
      tipo: TipoManutencao.trocaOleo,
      dataRealizada: DateTime(2026, 1, 1),
      kmNaData: 40000,
      custo: 200.0,
      oficina: 'Oficina',
      observacoes: '',
    );
    final manutencao2 = Manutencao(
      id: '',
      veiculoId: 'v1',
      tipo: TipoManutencao.revisao,
      dataRealizada: DateTime(2026, 2, 1),
      kmNaData: 41000,
      custo: 300.0,
      oficina: 'Oficina',
      observacoes: '',
    );

    await repository.add('uid1', manutencao1, veiculoId: 'v1');
    await repository.add('uid1', manutencao2, veiculoId: 'v1');
    await repository.add('uid1', manutencao1, veiculoId: 'v2');

    final lista = await repository.getAll('uid1', veiculoId: 'v1');

    expect(lista, hasLength(2));
  });
}
