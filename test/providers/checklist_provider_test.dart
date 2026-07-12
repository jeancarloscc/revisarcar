import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/checklist_item.dart';
import 'package:revisacar/providers/checklist_provider.dart';
import 'package:revisacar/repositories/checklist_repository.dart';

void main() {
  test('alternarVerificado marca e desmarca um item', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = ChecklistRepository(firestore);
    final provider = ChecklistProvider(repository: repository, uid: 'uid1');

    provider.escutarVeiculo('v1');
    await provider.adicionar(const ChecklistItem(
      id: '',
      veiculoId: 'v1',
      descricao: 'Óleo',
      ordem: 0,
      verificado: false,
    ));
    await Future<void>.delayed(Duration.zero);

    await provider.alternarVerificado(provider.checklistItems.first);
    await Future<void>.delayed(Duration.zero);

    expect(provider.checklistItems.first.verificado, isTrue);
  });

  test('resetarTodos desmarca todos os itens verificados', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = ChecklistRepository(firestore);
    final provider = ChecklistProvider(repository: repository, uid: 'uid1');

    provider.escutarVeiculo('v1');
    await provider.adicionar(const ChecklistItem(
      id: '',
      veiculoId: 'v1',
      descricao: 'Óleo',
      ordem: 0,
      verificado: true,
    ));
    await Future<void>.delayed(Duration.zero);

    await provider.resetarTodos();
    await Future<void>.delayed(Duration.zero);

    expect(provider.checklistItems.every((i) => !i.verificado), isTrue);
  });
}
