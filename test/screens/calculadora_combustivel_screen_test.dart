import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/screens/calculadora_combustivel_screen.dart';

void main() {
  testWidgets('pré-preenche o consumo quando consumoSugerido é fornecido', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CalculadoraCombustivelScreen(consumoSugerido: 12.5),
    ));

    final consumoField = tester.widget<TextFormField>(find.byType(TextFormField).at(0));
    expect(consumoField.controller!.text, '12.5');
  });

  testWidgets('não mostra botão de registrar quando aoRegistrarAbastecimento não é fornecido', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CalculadoraCombustivelScreen()));

    await tester.enterText(find.byType(TextFormField).at(0), '10');
    await tester.enterText(find.byType(TextFormField).at(1), '6');
    await tester.enterText(find.byType(TextFormField).at(2), '400');
    await tester.pump();

    expect(find.text('Registrar este abastecimento'), findsNothing);
  });

  testWidgets('mostra o botão e chama o callback com litros e valor total no modo direto', (tester) async {
    double? litrosRecebidos;
    double? valorRecebido;

    await tester.pumpWidget(MaterialApp(
      home: CalculadoraCombustivelScreen(
        aoRegistrarAbastecimento: (litros, valorTotal) {
          litrosRecebidos = litros;
          valorRecebido = valorTotal;
        },
      ),
    ));

    await tester.enterText(find.byType(TextFormField).at(0), '10');
    await tester.enterText(find.byType(TextFormField).at(1), '6');
    await tester.enterText(find.byType(TextFormField).at(2), '400');
    await tester.pump();

    await tester.tap(find.text('Registrar este abastecimento'));
    await tester.pump();

    expect(litrosRecebidos, 40);
    expect(valorRecebido, 240);
  });

  testWidgets('mostra o botão e chama o callback no modo orçamento', (tester) async {
    double? litrosRecebidos;
    double? valorRecebido;

    await tester.pumpWidget(MaterialApp(
      home: CalculadoraCombustivelScreen(
        aoRegistrarAbastecimento: (litros, valorTotal) {
          litrosRecebidos = litros;
          valorRecebido = valorTotal;
        },
      ),
    ));

    await tester.tap(find.text('Orçamento → alcance'));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), '10');
    await tester.enterText(find.byType(TextFormField).at(1), '6');
    await tester.enterText(find.byType(TextFormField).at(2), '120');
    await tester.pump();

    await tester.tap(find.text('Registrar este abastecimento'));
    await tester.pump();

    expect(litrosRecebidos, 20);
    expect(valorRecebido, 120);
  });
}
