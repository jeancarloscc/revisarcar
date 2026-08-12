import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:revisacar/models/abastecimento.dart';
import 'package:revisacar/providers/abastecimento_provider.dart';
import 'package:revisacar/screens/abastecimento_form_screen.dart';

class _FakeAbastecimentoProvider extends ChangeNotifier implements AbastecimentoProvider {
  _FakeAbastecimentoProvider([this._abastecimentos = const []]);

  final List<Abastecimento> _abastecimentos;

  @override
  List<Abastecimento> get abastecimentos => _abastecimentos;

  @override
  String get uid => 'uid1';

  @override
  Future<void> adicionar(Abastecimento abastecimento) async {}

  @override
  Future<void> atualizar(Abastecimento abastecimento) async {}

  @override
  Future<void> remover(String id) async {}

  @override
  void escutarVeiculo(String veiculoId) {}
}

Widget _wrap(Widget child, {List<Abastecimento> abastecimentos = const []}) {
  return ChangeNotifierProvider<AbastecimentoProvider>.value(
    value: _FakeAbastecimentoProvider(abastecimentos),
    child: MaterialApp(home: child),
  );
}

// Tela alta o bastante pra caber o formulário inteiro sem precisar rolar durante os testes.
void _usarTelaAlta(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// Ordem dos campos no formulário: 0=km, 1=preço/L, 2=litros, 3=valor total, 4=posto.
void main() {
  testWidgets('pré-preenche litros, valor total e calcula o preço por litro quando não está editando',
      (tester) async {
    _usarTelaAlta(tester);
    await tester.pumpWidget(_wrap(
      const AbastecimentoFormScreen(litrosInicial: 12.5, valorTotalInicial: 75.0),
    ));

    final precoField = tester.widget<TextFormField>(find.byType(TextFormField).at(1));
    final litrosField = tester.widget<TextFormField>(find.byType(TextFormField).at(2));
    final valorField = tester.widget<TextFormField>(find.byType(TextFormField).at(3));

    expect(precoField.controller!.text, '6.00');
    expect(litrosField.controller!.text, '12.50');
    expect(valorField.controller!.text, '75.00');
    expect(find.text('(calculado)'), findsOneWidget);
  });

  testWidgets('ignora litrosInicial/valorTotalInicial quando está editando um abastecimento existente', (tester) async {
    _usarTelaAlta(tester);
    final abastecimento = Abastecimento(
      id: 'a1',
      veiculoId: 'v1',
      data: DateTime(2026, 1, 1),
      kmAtual: 1000,
      litros: 30,
      valorTotal: 180,
      tanqueCheio: true,
    );

    await tester.pumpWidget(_wrap(
      AbastecimentoFormScreen(
        abastecimento: abastecimento,
        litrosInicial: 12.5,
        valorTotalInicial: 75.0,
      ),
      abastecimentos: [abastecimento],
    ));

    final litrosField = tester.widget<TextFormField>(find.byType(TextFormField).at(2));
    expect(litrosField.controller!.text, '30.0');

    final valorField = tester.widget<TextFormField>(find.byType(TextFormField).at(3));
    expect(valorField.controller!.text, '180.0');
  });

  testWidgets('preencher preço por litro e litros calcula automaticamente o valor total', (tester) async {
    _usarTelaAlta(tester);
    await tester.pumpWidget(_wrap(const AbastecimentoFormScreen()));

    await tester.enterText(find.byType(TextFormField).at(1), '6');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(2), '10');
    await tester.pump();

    final valorField = tester.widget<TextFormField>(find.byType(TextFormField).at(3));
    expect(valorField.controller!.text, '60.00');
    expect(find.text('(calculado)'), findsOneWidget);
  });

  testWidgets('editar manualmente o campo calculado faz ele parar de ser recalculado', (tester) async {
    _usarTelaAlta(tester);
    await tester.pumpWidget(_wrap(const AbastecimentoFormScreen()));

    await tester.enterText(find.byType(TextFormField).at(1), '6');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(2), '10');
    await tester.pump();

    // Valor total foi calculado como 60.00; o usuário sobrescreve manualmente.
    await tester.enterText(find.byType(TextFormField).at(3), '55');
    await tester.pump();

    expect(find.text('(calculado)'), findsNothing);

    final valorField = tester.widget<TextFormField>(find.byType(TextFormField).at(3));
    expect(valorField.controller!.text, '55');
  });

  testWidgets('botão Salvar só habilita quando litros, valor total e km estão preenchidos', (tester) async {
    _usarTelaAlta(tester);
    await tester.pumpWidget(_wrap(const AbastecimentoFormScreen()));

    var botaoSalvar = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(botaoSalvar.onPressed, isNull);

    await tester.enterText(find.byType(TextFormField).at(0), '1000');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(2), '10');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(3), '60');
    await tester.pump();

    botaoSalvar = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(botaoSalvar.onPressed, isNotNull);
  });

  testWidgets('km menor ou igual ao último registro mostra aviso mas não desabilita o botão Salvar',
      (tester) async {
    _usarTelaAlta(tester);
    final ultimo = Abastecimento(
      id: 'a1',
      veiculoId: 'v1',
      data: DateTime(2026, 1, 1),
      kmAtual: 50000,
      litros: 30,
      valorTotal: 180,
      tanqueCheio: true,
    );

    await tester.pumpWidget(_wrap(
      const AbastecimentoFormScreen(),
      abastecimentos: [ultimo],
    ));

    await tester.enterText(find.byType(TextFormField).at(0), '49000');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(2), '10');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(3), '60');
    await tester.pump();

    expect(find.textContaining('Km menor ou igual ao último registro'), findsOneWidget);

    final botaoSalvar = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(botaoSalvar.onPressed, isNotNull);
  });
}
