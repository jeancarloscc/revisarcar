import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/checklist_item.dart';

void main() {
  group('ChecklistItem', () {
    test('fromMap/toMap round-trip preserva todos os campos', () {
      const item = ChecklistItem(
        id: 'c1',
        veiculoId: 'v1',
        descricao: 'Óleo',
        ordem: 0,
        verificado: false,
      );

      final map = item.toMap();
      final restaurado = ChecklistItem.fromMap('c1', 'v1', map);

      expect(restaurado, item);
    });

    test('copyWith alterna verificado sem afetar outros campos', () {
      const item = ChecklistItem(
        id: 'c1',
        veiculoId: 'v1',
        descricao: 'Pneus',
        ordem: 1,
        verificado: false,
      );

      final marcado = item.copyWith(verificado: true);

      expect(marcado.verificado, isTrue);
      expect(marcado.descricao, item.descricao);
      expect(marcado.ordem, item.ordem);
    });
  });
}
