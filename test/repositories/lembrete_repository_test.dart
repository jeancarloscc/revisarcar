import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/lembrete_manutencao.dart';
import 'package:revisacar/models/manutencao.dart';
import 'package:revisacar/repositories/lembrete_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late LembreteRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = LembreteRepository(firestore);
  });

  test('add/watchAll são escopados por veiculoId', () async {
    final lembrete = LembreteManutencao(
      id: '',
      veiculoId: 'v1',
      tipoManutencao: TipoManutencao.trocaOleo,
      intervaloKm: 10000,
      antecedenciaKm: 500,
      antecedenciaDias: 0,
      intervaloRepeticaoDias: 3,
      ativo: true,
    );

    await repository.add('uid1', lembrete, veiculoId: 'v1');
    final lista = await repository.watchAll('uid1', veiculoId: 'v1').first;

    expect(lista, hasLength(1));
    expect(lista.first.veiculoId, 'v1');
  });

  test('getAll retorna todos os lembretes daquele veículo', () async {
    final lembrete = LembreteManutencao(
      id: '',
      veiculoId: 'v1',
      tipoManutencao: TipoManutencao.trocaOleo,
      intervaloKm: 10000,
      antecedenciaKm: 500,
      antecedenciaDias: 0,
      intervaloRepeticaoDias: 3,
      ativo: true,
    );

    await repository.add('uid1', lembrete, veiculoId: 'v1');
    await repository.add('uid1', lembrete, veiculoId: 'v2');

    final lista = await repository.getAll('uid1', veiculoId: 'v1');

    expect(lista, hasLength(1));
  });
}
