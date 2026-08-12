import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:revisacar/models/checklist_item.dart';
import 'package:revisacar/providers/checklist_provider.dart';
import 'package:revisacar/repositories/checklist_repository.dart';
import 'package:revisacar/utils/checklist_padrao.dart';
import 'package:revisacar/widgets/checklist_tab.dart';

Widget _wrap(ChecklistProvider provider) {
  return ChangeNotifierProvider<ChecklistProvider>.value(
    value: provider,
    child: const MaterialApp(
      home: Scaffold(body: ChecklistTab(veiculoId: 'v1')),
    ),
  );
}

void main() {
  late ChecklistProvider provider;

  setUp(() {
    final firestore = FakeFirebaseFirestore();
    final repository = ChecklistRepository(firestore);
    provider = ChecklistProvider(repository: repository, uid: 'uid1')..escutarVeiculo('v1');
  });

  testWidgets('estado vazio mostra botão de checklist sugerido e ao tocar popula os itens padrão',
      (tester) async {
    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.text('Usar checklist sugerido'), findsOneWidget);

    await tester.tap(find.text('Usar checklist sugerido'));
    await tester.pumpAndSettle();

    for (final descricao in checklistPadrao) {
      expect(find.text(descricao), findsOneWidget);
    }
  });

  testWidgets('tocar no checkbox de um item marca como verificado', (tester) async {
    await provider.adicionar(const ChecklistItem(
      id: '',
      veiculoId: 'v1',
      descricao: 'Óleo',
      ordem: 0,
      verificado: false,
    ));
    await Future<void>.delayed(Duration.zero);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();
    expect(provider.checklistItems.single.verificado, isFalse);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await Future<void>.delayed(Duration.zero);
    await tester.pump();

    expect(provider.checklistItems.single.verificado, isTrue);
  });

  testWidgets('Reiniciar fica desabilitado quando nenhum item está marcado', (tester) async {
    await provider.adicionar(const ChecklistItem(
      id: '',
      veiculoId: 'v1',
      descricao: 'Óleo',
      ordem: 0,
      verificado: false,
    ));
    await Future<void>.delayed(Duration.zero);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    final botao = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Reiniciar'));
    expect(botao.onPressed, isNull);
  });

  testWidgets('Reiniciar desmarca todos os itens ao confirmar', (tester) async {
    await provider.adicionar(const ChecklistItem(
      id: '',
      veiculoId: 'v1',
      descricao: 'Óleo',
      ordem: 0,
      verificado: true,
    ));
    await provider.adicionar(const ChecklistItem(
      id: '',
      veiculoId: 'v1',
      descricao: 'Pneus',
      ordem: 1,
      verificado: false,
    ));
    await Future<void>.delayed(Duration.zero);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    final botao = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Reiniciar'));
    expect(botao.onPressed, isNotNull);

    await tester.tap(find.text('Reiniciar'));
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Reiniciar'),
    ));
    await tester.pumpAndSettle();
    await Future<void>.delayed(Duration.zero);
    await tester.pump();

    expect(provider.checklistItems.every((i) => !i.verificado), isTrue);
  });
}
