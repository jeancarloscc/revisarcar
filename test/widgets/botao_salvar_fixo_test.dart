import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/widgets/botao_salvar_fixo.dart';

void main() {
  testWidgets('renderiza o label recebido e chama onPressed ao tocar', (tester) async {
    var tocado = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: BotaoSalvarFixo(
          label: 'Salvar',
          labelCarregando: 'Salvando...',
          carregando: false,
          onPressed: () => tocado = true,
        ),
      ),
    ));

    expect(find.text('Salvar'), findsOneWidget);
    await tester.tap(find.text('Salvar'));
    expect(tocado, isTrue);
  });

  testWidgets('fica desabilitado e mostra o label de carregando quando carregando é true', (tester) async {
    var tocado = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: BotaoSalvarFixo(
          label: 'Salvar',
          labelCarregando: 'Salvando...',
          carregando: true,
          onPressed: () => tocado = true,
        ),
      ),
    ));

    expect(find.text('Salvando...'), findsOneWidget);
    final botao = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(botao.onPressed, isNull);

    await tester.tap(find.byType(FilledButton));
    expect(tocado, isFalse);
  });
}
