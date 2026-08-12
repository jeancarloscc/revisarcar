import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/veiculo.dart';
import 'package:revisacar/theme/app_theme.dart';
import 'package:revisacar/widgets/veiculo_card.dart';

void main() {
  testWidgets('km atual usa a cor de acento', (tester) async {
    const veiculo = Veiculo(
      id: 'v1',
      nome: 'Civic',
      modelo: 'Honda Civic EX',
      ano: 2021,
      placa: 'BRA2I21',
      kmAtual: 42850,
      tipoVeiculo: TipoVeiculo.carro,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: VeiculoCard(veiculo: veiculo, onTap: () {}, onExcluir: () {}),
      ),
    ));

    final kmText = tester.widget<Text>(find.text('42850 km'));
    expect(kmText.style?.color, kAccentColor);
  });

  testWidgets('mostra chevron indicando navegação para o detalhe', (tester) async {
    const veiculo = Veiculo(
      id: 'v1',
      nome: 'Civic',
      modelo: 'Honda Civic EX',
      ano: 2021,
      placa: 'BRA2I21',
      kmAtual: 42850,
      tipoVeiculo: TipoVeiculo.carro,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: VeiculoCard(veiculo: veiculo, onTap: () {}, onExcluir: () {}),
      ),
    ));

    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });
}
