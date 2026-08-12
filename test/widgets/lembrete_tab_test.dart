import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:revisacar/models/lembrete_manutencao.dart';
import 'package:revisacar/models/manutencao.dart';
import 'package:revisacar/providers/lembrete_provider.dart';
import 'package:revisacar/providers/manutencao_provider.dart';
import 'package:revisacar/screens/lembrete_form_screen.dart';
import 'package:revisacar/theme/app_theme.dart';
import 'package:revisacar/widgets/lembrete_tab.dart';

class _FakeManutencaoProvider extends ChangeNotifier implements ManutencaoProvider {
  @override
  List<Manutencao> get manutencoes => const [];

  @override
  String get uid => 'uid1';

  @override
  Future<void> adicionar(Manutencao manutencao) async {}

  @override
  Future<void> atualizar(Manutencao manutencao) async {}

  @override
  Future<void> remover(String id) async {}

  @override
  void escutarVeiculo(String veiculoId) {}
}

class _FakeLembreteProvider extends ChangeNotifier implements LembreteProvider {
  _FakeLembreteProvider(this._lembretes);

  final List<LembreteManutencao> _lembretes;

  @override
  List<LembreteManutencao> get lembretes => _lembretes;

  @override
  String get uid => 'uid1';

  @override
  Future<void> adicionar(LembreteManutencao lembrete) async {}

  @override
  Future<void> atualizar(LembreteManutencao lembrete) async {}

  @override
  Future<void> remover(String id) async {}

  @override
  void escutarVeiculo(String veiculoId) {}
}

Widget _wrap(LembreteManutencao lembrete, {int kmAtual = 1000}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ManutencaoProvider>.value(value: _FakeManutencaoProvider()),
      ChangeNotifierProvider<LembreteProvider>.value(value: _FakeLembreteProvider([lembrete])),
    ],
    child: MaterialApp(
      theme: appThemeLight,
      home: Scaffold(body: LembreteTab(kmAtual: kmAtual)),
    ),
  );
}

void main() {
  final lembreteEmDia = LembreteManutencao(
    id: 'l1',
    veiculoId: 'v1',
    tipoManutencao: TipoManutencao.trocaOleo,
    intervaloKm: 10000,
    antecedenciaKm: 0,
    antecedenciaDias: 0,
    intervaloRepeticaoDias: 3,
    ativo: true,
  );

  testWidgets('card "Em dia" também mostra o botão "Marcar como feito"', (tester) async {
    await tester.pumpWidget(_wrap(lembreteEmDia));

    expect(find.text('Em dia'), findsOneWidget);
    expect(find.text('Marcar como feito'), findsOneWidget);
  });

  testWidgets('mostra chip de intervalo quando intervaloKm não é nulo', (tester) async {
    await tester.pumpWidget(_wrap(lembreteEmDia));

    expect(find.text('cada 10000 km'), findsOneWidget);
  });

  testWidgets('toque no card fora do botão navega para LembreteFormScreen', (tester) async {
    await tester.pumpWidget(_wrap(lembreteEmDia));

    await tester.tap(find.text('Troca de óleo'));
    await tester.pumpAndSettle();

    expect(find.byType(LembreteFormScreen), findsOneWidget);
  });
}
