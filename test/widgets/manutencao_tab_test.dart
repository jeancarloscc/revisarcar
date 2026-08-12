import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:revisacar/models/lembrete_manutencao.dart';
import 'package:revisacar/models/manutencao.dart';
import 'package:revisacar/providers/lembrete_provider.dart';
import 'package:revisacar/providers/manutencao_provider.dart';
import 'package:revisacar/theme/app_theme.dart';
import 'package:revisacar/widgets/manutencao_tab.dart';

class _FakeManutencaoProvider extends ChangeNotifier implements ManutencaoProvider {
  _FakeManutencaoProvider(this._manutencoes);

  final List<Manutencao> _manutencoes;

  @override
  List<Manutencao> get manutencoes => _manutencoes;

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
  @override
  List<LembreteManutencao> get lembretes => const [];

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

void main() {
  testWidgets('mostra o custo em destaque, separado da oficina', (tester) async {
    final manutencao = Manutencao(
      id: 'm1',
      veiculoId: 'v1',
      tipo: TipoManutencao.trocaOleo,
      dataRealizada: DateTime(2026, 3, 1),
      kmNaData: 42000,
      custo: 180,
      oficina: 'Auto Center Souza',
      observacoes: '',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ManutencaoProvider>.value(
            value: _FakeManutencaoProvider([manutencao]),
          ),
          ChangeNotifierProvider<LembreteProvider>.value(
            value: _FakeLembreteProvider(),
          ),
        ],
        child: MaterialApp(
          theme: appThemeLight,
          home: const Scaffold(body: ManutencaoTab(kmAtual: 42000)),
        ),
      ),
    );

    expect(find.text('R\$ 180.00'), findsOneWidget);
    expect(find.text('Auto Center Souza'), findsOneWidget);

    final custoText = tester.widget<Text>(find.text('R\$ 180.00'));
    expect(custoText.style?.fontWeight, FontWeight.w800);
  });
}
