import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/abastecimento.dart';
import 'package:revisacar/screens/abastecimento_form_screen.dart';

void main() {
  testWidgets('pré-preenche litros e valor total quando fornecidos e não está editando', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AbastecimentoFormScreen(litrosInicial: 12.5, valorTotalInicial: 75.0),
    ));

    final litrosField = tester.widget<TextFormField>(find.byType(TextFormField).at(1));
    final valorField = tester.widget<TextFormField>(find.byType(TextFormField).at(2));

    expect(litrosField.controller!.text, '12.50');
    expect(valorField.controller!.text, '75.00');
  });

  testWidgets('ignora litrosInicial/valorTotalInicial quando está editando um abastecimento existente', (tester) async {
    final abastecimento = Abastecimento(
      id: 'a1',
      veiculoId: 'v1',
      data: DateTime(2026, 1, 1),
      kmAtual: 1000,
      litros: 30,
      valorTotal: 180,
      tanqueCheio: true,
    );

    await tester.pumpWidget(MaterialApp(
      home: AbastecimentoFormScreen(
        abastecimento: abastecimento,
        litrosInicial: 12.5,
        valorTotalInicial: 75.0,
      ),
    ));

    final litrosField = tester.widget<TextFormField>(find.byType(TextFormField).at(1));
    expect(litrosField.controller!.text, '30.0');

    final valorField = tester.widget<TextFormField>(find.byType(TextFormField).at(2));
    expect(valorField.controller!.text, '180.0');
  });
}
