import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/abastecimento.dart';
import 'package:revisacar/repositories/abastecimento_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late AbastecimentoRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = AbastecimentoRepository(firestore);
  });

  test('add/watchAll são escopados por veiculoId', () async {
    final abastecimento = Abastecimento(
      id: '',
      veiculoId: 'v1',
      data: DateTime(2026, 1, 1),
      kmAtual: 40000,
      litros: 30,
      valorTotal: 180,
      tanqueCheio: true,
    );

    await repository.add('uid1', abastecimento, veiculoId: 'v1');
    final lista = await repository.watchAll('uid1', veiculoId: 'v1').first;

    expect(lista, hasLength(1));
    expect(lista.first.veiculoId, 'v1');
  });
}
