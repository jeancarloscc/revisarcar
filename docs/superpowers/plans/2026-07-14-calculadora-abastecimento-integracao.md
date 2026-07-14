# Integração Calculadora de Combustível ↔ Abastecimento — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir que a calculadora de combustível (já implementada em `lib/screens/calculadora_combustivel_screen.dart`) seja aberta a partir da aba de abastecimento de um veículo, sugerindo automaticamente o consumo médio real do veículo e oferecendo um atalho para registrar o abastecimento calculado.

**Architecture:** `CalculadoraCombustivelScreen` ganha dois parâmetros opcionais — `consumoSugerido` (double?, prefill) e `aoRegistrarAbastecimento` (callback `void Function(double litros, double valorTotal)?`) — sem passar a conhecer `Provider`/Firestore, mantendo-a pura e reutilizável no acesso global (ícone da lista de veículos, sem esses parâmetros) e no acesso contextual (aba de abastecimento, com ambos preenchidos). `AbastecimentoFormScreen` ganha dois parâmetros opcionais (`litrosInicial`, `valorTotalInicial`) para prefill de um novo registro. `AbastecimentoTab` é o único lugar que conhece os três widgets e faz a ponte entre eles via `Navigator.push` + `ChangeNotifierProvider.value`, seguindo exatamente o padrão já usado ali para abrir `AbastecimentoFormScreen`.

**Tech Stack:** Flutter/Dart, `provider` (ChangeNotifier), `flutter_test` para os widget tests.

## Global Constraints

- `CalculadoraCombustivelScreen` não pode importar `provider`, `cloud_firestore` nem repositórios — ela permanece uma tela local/pura; a integração com `AbastecimentoProvider` é responsabilidade exclusiva de quem a chama (`AbastecimentoTab`).
- Reaproveitar `ConsumoService.consumoPeriodo` (já existente em `lib/services/consumo_service.dart`) para calcular o consumo sugerido — não criar um cálculo de consumo paralelo.
- Seguir o padrão de navegação já usado em `abastecimento_tab.dart`: `Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: provider, child: ...)))`.
- Todo texto de UI em português, seguindo o estilo existente (labels em maiúsculas via `_rotulo`, botões com `Icon` + `Text`).
- Não alterar o modelo `Abastecimento` nem o `AbastecimentoRepository`/`AbastecimentoProvider` — a integração é só de UI/navegação.

---

### Task 1: Prefill opcional em `AbastecimentoFormScreen`

**Files:**
- Modify: `lib/screens/abastecimento_form_screen.dart:7-36`
- Test: `test/screens/abastecimento_form_screen_test.dart` (novo arquivo e novo diretório `test/screens/`)

**Interfaces:**
- Consumes: nenhuma (task independente).
- Produces: `AbastecimentoFormScreen({super.key, Abastecimento? abastecimento, double? litrosInicial, double? valorTotalInicial})` — usado pela Task 3.

- [ ] **Step 1: Escrever o teste que falha**

Criar `test/screens/abastecimento_form_screen_test.dart`:

```dart
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
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/screens/abastecimento_form_screen_test.dart`
Expected: FAIL — `The named parameter 'litrosInicial' isn't defined` (erro de compilação, construtor ainda não aceita os parâmetros).

- [ ] **Step 3: Implementar o prefill**

Em `lib/screens/abastecimento_form_screen.dart`, trocar as linhas 7-10:

```dart
class AbastecimentoFormScreen extends StatefulWidget {
  final Abastecimento? abastecimento;
  final double? litrosInicial;
  final double? valorTotalInicial;

  const AbastecimentoFormScreen({
    super.key,
    this.abastecimento,
    this.litrosInicial,
    this.valorTotalInicial,
  });
```

E dentro de `initState` (linhas 33-34), trocar:

```dart
    _litrosController = TextEditingController(
      text: a?.litros.toString() ?? widget.litrosInicial?.toStringAsFixed(2) ?? '',
    );
    _valorTotalController = TextEditingController(
      text: a?.valorTotal.toString() ?? widget.valorTotalInicial?.toStringAsFixed(2) ?? '',
    );
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/screens/abastecimento_form_screen_test.dart`
Expected: PASS (2 testes).

- [ ] **Step 5: Commit**

```bash
git add lib/screens/abastecimento_form_screen.dart test/screens/abastecimento_form_screen_test.dart
git commit -m "feat: permitir prefill de litros/valor total ao criar abastecimento"
```

---

### Task 2: `consumoSugerido` + botão "Registrar este abastecimento" em `CalculadoraCombustivelScreen`

**Files:**
- Modify: `lib/screens/calculadora_combustivel_screen.dart`
- Test: `test/screens/calculadora_combustivel_screen_test.dart` (novo)

**Interfaces:**
- Consumes: nenhuma (independente da Task 1, mas ambas são consumidas pela Task 3).
- Produces: `CalculadoraCombustivelScreen({super.key, double? consumoSugerido, void Function(double litros, double valorTotal)? aoRegistrarAbastecimento})` — usado pela Task 3.

- [ ] **Step 1: Escrever o teste que falha**

Criar `test/screens/calculadora_combustivel_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/screens/calculadora_combustivel_screen.dart';

void main() {
  testWidgets('pré-preenche o consumo quando consumoSugerido é fornecido', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CalculadoraCombustivelScreen(consumoSugerido: 12.5),
    ));

    final consumoField = tester.widget<TextFormField>(find.byType(TextFormField).at(1));
    expect(consumoField.controller!.text, '12.5');
  });

  testWidgets('não mostra botão de registrar quando aoRegistrarAbastecimento não é fornecido', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CalculadoraCombustivelScreen()));

    await tester.enterText(find.byType(TextFormField).at(0), '6');
    await tester.enterText(find.byType(TextFormField).at(1), '10');
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

    await tester.enterText(find.byType(TextFormField).at(0), '6');
    await tester.enterText(find.byType(TextFormField).at(1), '10');
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

    await tester.enterText(find.byType(TextFormField).at(0), '6');
    await tester.enterText(find.byType(TextFormField).at(1), '10');
    await tester.enterText(find.byType(TextFormField).at(2), '120');
    await tester.pump();

    await tester.tap(find.text('Registrar este abastecimento'));
    await tester.pump();

    expect(litrosRecebidos, 20);
    expect(valorRecebido, 120);
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/screens/calculadora_combustivel_screen_test.dart`
Expected: FAIL — `The named parameter 'consumoSugerido' isn't defined` (construtor ainda não aceita os parâmetros).

- [ ] **Step 3: Implementar o construtor, o prefill e o botão**

Em `lib/screens/calculadora_combustivel_screen.dart`, trocar as linhas 7-8:

```dart
class CalculadoraCombustivelScreen extends StatefulWidget {
  final double? consumoSugerido;
  final void Function(double litros, double valorTotal)? aoRegistrarAbastecimento;

  const CalculadoraCombustivelScreen({
    super.key,
    this.consumoSugerido,
    this.aoRegistrarAbastecimento,
  });
```

Adicionar `initState` logo após a declaração dos controllers (depois da linha 19, antes do `dispose()` na linha 24):

```dart
  @override
  void initState() {
    super.initState();
    if (widget.consumoSugerido != null) {
      _consumoController.text = widget.consumoSugerido!.toStringAsFixed(1);
    }
  }
```

Dentro de `build`, logo após o cálculo de `resultadoOrcamento` (depois da linha 74), adicionar o resultado unificado para registro:

```dart
    final resultadoParaRegistro = resultadoDireto != null
        ? (litros: resultadoDireto.litros, valorTotal: resultadoDireto.valorTotal)
        : resultadoOrcamento != null
            ? (
                litros: resultadoOrcamento.litros,
                valorTotal: double.tryParse(_valorDisponivelController.text.replaceAll(',', '.')) ?? 0,
              )
            : null;
```

E, depois dos dois blocos `if (resultadoDireto != null) ...[...]` / `if (resultadoOrcamento != null) ...[...]` (depois da linha 152, ainda dentro da lista de `children` do `ListView`), adicionar o botão:

```dart
            if (resultadoParaRegistro != null && widget.aoRegistrarAbastecimento != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => widget.aoRegistrarAbastecimento!(
                  resultadoParaRegistro.litros,
                  resultadoParaRegistro.valorTotal,
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Registrar este abastecimento'),
              ),
            ],
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/screens/calculadora_combustivel_screen_test.dart`
Expected: PASS (4 testes).

- [ ] **Step 5: Commit**

```bash
git add lib/screens/calculadora_combustivel_screen.dart test/screens/calculadora_combustivel_screen_test.dart
git commit -m "feat: adicionar prefill de consumo e registro de abastecimento na calculadora"
```

---

### Task 3: Ponto de entrada na aba de abastecimento

**Files:**
- Modify: `lib/widgets/abastecimento_tab.dart`

**Interfaces:**
- Consumes: `CalculadoraCombustivelScreen(consumoSugerido, aoRegistrarAbastecimento)` (Task 2) e `AbastecimentoFormScreen(litrosInicial, valorTotalInicial)` (Task 1); `ConsumoService.consumoPeriodo(List<Abastecimento>)` (já existe em `lib/services/consumo_service.dart`).
- Produces: nenhuma (task final de integração, sem consumidores posteriores).

- [ ] **Step 1: Adicionar os imports**

Em `lib/widgets/abastecimento_tab.dart`, depois da linha 6 (`import '../screens/abastecimento_form_screen.dart';`), adicionar:

```dart
import '../screens/calculadora_combustivel_screen.dart';
import '../services/consumo_service.dart';
```

- [ ] **Step 2: Adicionar o botão de entrada e a navegação**

No método `build` (depois da linha 65, `_resumo(context, abastecimentos),`, e antes de `Expanded(`), adicionar:

```dart
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: OutlinedButton.icon(
              onPressed: () {
                final abastecimentoProvider = context.read<AbastecimentoProvider>();
                final navigator = Navigator.of(context);
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => CalculadoraCombustivelScreen(
                      consumoSugerido: ConsumoService.consumoPeriodo(abastecimentos),
                      aoRegistrarAbastecimento: (litros, valorTotal) {
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: abastecimentoProvider,
                              child: AbastecimentoFormScreen(
                                litrosInicial: litros,
                                valorTotalInicial: valorTotal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Calcular viagem'),
            ),
          ),
```

- [ ] **Step 3: Rodar toda a suíte de testes para garantir que nada quebrou**

Run: `flutter test`
Expected: PASS em todos os testes (os existentes + os das Tasks 1 e 2).

Run: `flutter analyze`
Expected: nenhum novo warning/erro (os avisos pré-existentes em `abastecimento_provider.dart`, `checklist_provider.dart`, `lembrete_provider.dart`, `manutencao_provider.dart`, `veiculo_provider.dart` e `veiculo_repository_test.dart` já existiam antes desta mudança e não são deste plano).

- [ ] **Step 4: Verificação manual end-to-end**

Rodar o app (`flutter run`), abrir um veículo com pelo menos 2 abastecimentos com `tanqueCheio: true` registrados, ir na aba "Abastecimentos", tocar em "Calcular viagem":
- Confirmar que o campo "Consumo do veículo (km/L)" já vem preenchido com o consumo médio do histórico.
- Preencher preço e distância, tocar em "Registrar este abastecimento".
- Confirmar que abre o formulário de novo abastecimento com litros e valor total já preenchidos, e que salvar cria o registro normalmente na lista da aba.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/abastecimento_tab.dart
git commit -m "feat: abrir calculadora de combustível a partir da aba de abastecimento"
```

## Self-Review

**Spec coverage:**
- Consumo médio sugerido a partir do histórico real → Task 3 (via `ConsumoService.consumoPeriodo`) + Task 2 (prefill).
- Calculadora continua funcionando sem contexto de veículo (acesso pelo ícone da lista) → garantido pelos parâmetros serem opcionais (`consumoSugerido`/`aoRegistrarAbastecimento` nulos não alteram o comportamento atual, coberto pelo teste "não mostra botão de registrar quando aoRegistrarAbastecimento não é fornecido").
- Botão "Registrar este abastecimento" leva ao formulário de abastecimento pré-preenchido → Task 1 (prefill no formulário) + Task 2 (callback) + Task 3 (wiring com o provider correto).
- Separação de responsabilidades (calculadora não conhece Firestore/Provider) → garantido pelas Global Constraints e pela assinatura do callback na Task 2.

**Placeholder scan:** nenhum "TBD"/"implementar depois" — todos os steps têm código completo.

**Type consistency:** `consumoSugerido` é `double?` em todas as tasks; `aoRegistrarAbastecimento` é `void Function(double litros, double valorTotal)?` em todas; `litrosInicial`/`valorTotalInicial` são `double?` tanto na Task 1 quanto no uso da Task 3.
