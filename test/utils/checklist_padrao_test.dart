import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/utils/checklist_padrao.dart';

void main() {
  test('checklistPadrao não está vazia e não tem descrições duplicadas', () {
    expect(checklistPadrao, isNotEmpty);
    expect(checklistPadrao.toSet().length, checklistPadrao.length);
  });
}
