import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/checklist_item.dart';
import 'package:revisacar/repositories/checklist_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ChecklistRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = ChecklistRepository(firestore);
  });

  test('add/update alteram verificado corretamente', () async {
    const item = ChecklistItem(
      id: '',
      veiculoId: 'v1',
      descricao: 'Óleo',
      ordem: 0,
      verificado: false,
    );

    final id = await repository.add('uid1', item, veiculoId: 'v1');
    await repository.update('uid1', id, item.copyWith(verificado: true), veiculoId: 'v1');
    final lista = await repository.watchAll('uid1', veiculoId: 'v1').first;

    expect(lista.first.verificado, isTrue);
  });
}
