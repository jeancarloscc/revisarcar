# Fase B: Detalhe do Veículo (Manutenções/Abastecimentos/Lembretes) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir a tela de Detalhe do Veículo com abas de Manutenções, Abastecimentos e Lembretes (CRUD completo + status calculado de lembretes), sobre o backend já pronto do Plano 1 e a navegação da Fase A.

**Architecture:** `VeiculoListScreen` abre `DetalheVeiculoScreen(veiculo)` ao tocar num card; essa tela cria (via `MultiProvider` aninhado, escopado à própria tela) os providers `ManutencaoProvider`/`AbastecimentoProvider`/`LembreteProvider` já existentes, cada um escutando o veículo corrente via `escutarVeiculo(veiculoId)`. Um `DefaultTabController` com 3 abas (`ManutencaoTab`, `AbastecimentoTab`, `LembreteTab`) lista os registros; cada aba tem seu próprio `Scaffold`+FAB para criar, `Dismissible` com diálogo de confirmação para excluir, e toque no item abre o formulário de edição correspondente. `LembreteTab` calcula o status de cada lembrete via `LembreteService` (já existente) e oferece um atalho "Marcar como resolvido" que abre `ManutencaoFormScreen` pré-preenchida.

**Tech Stack:** Flutter/Dart (SDK `^3.12.2`), `provider` (já em uso). Única dependência nova: `flutter_localizations` (SDK do Flutter, sem custo de peso), para o `DatePicker` nativo exibir em português.

## Global Constraints

- Spec de referência desta fase: `docs/superpowers/specs/2026-07-10-fase-b-detalhe-veiculo-design.md`.
- Interface em Português (Brasil).
- **Nenhuma tarefa deste plano deve executar comandos git** (`init`, `add`, `commit`, etc.) — projeto não usa controle de versão (mesma decisão das fases anteriores). Cada tarefa termina depois que os testes/análise passam; não há passo de commit.
- Sem testes de widget nesta fase — a verificação de cada tela/widget novo é `flutter analyze` limpo; mudanças de lógica em models seguem TDD com teste unitário.
- Sem pacote `intl` nesta fase — datas exibidas como `dd/mm/aaaa` formatadas manualmente; `DatePicker` nativo em português via `flutter_localizations`.
- Campos numéricos decimais (`custo`, `valorTotal`, `litros`) aceitam vírgula ou ponto como separador decimal — texto do campo passa por `.replaceAll(',', '.')` antes de `double.parse`.
- Exclusão de manutenção/abastecimento/lembrete: gesto de `Dismissible` (swipe) + diálogo de confirmação antes de chamar `remover`, mesmo padrão nas 3 abas, via helper compartilhado `confirmarExclusaoDialog`.
- Sem Dashboard, Checklist, foto do veículo, `BottomNavigationBar` ou agendamento de notificações nesta fase.

---

### Task 1: `LembreteManutencao.copyWith`

**Files:**
- Modify: `lib/models/lembrete_manutencao.dart`
- Test: `test/models/lembrete_manutencao_test.dart`

**Interfaces:**
- Consumes: `LembreteManutencao` (campos já existentes).
- Produces: `LembreteManutencao copyWith({int? intervaloKm, int? intervaloDias, int? antecedenciaKm, int? antecedenciaDias, int? intervaloRepeticaoDias, bool? ativo, DateTime? resolvidoEm})` — usado pela Task 3 (`ManutencaoFormScreen`, fluxo de resolver lembrete).

- [ ] **Step 1: Escrever o teste (falhando)**

Adicionar este teste dentro do `group('LembreteManutencao', ...)` em `test/models/lembrete_manutencao_test.dart`, logo antes do fechamento `});` do group (depois do teste `'resolvidoEm nulo é preservado'`):

```dart
    test('copyWith troca só os campos informados', () {
      final lembrete = LembreteManutencao(
        id: 'l1',
        veiculoId: 'v1',
        tipoManutencao: TipoManutencao.trocaOleo,
        intervaloKm: 10000,
        antecedenciaKm: 500,
        antecedenciaDias: 15,
        intervaloRepeticaoDias: 3,
        ativo: true,
      );

      final resolvido = DateTime(2026, 7, 10);
      final atualizado = lembrete.copyWith(resolvidoEm: resolvido);

      expect(atualizado.resolvidoEm, resolvido);
      expect(atualizado.ativo, lembrete.ativo);
      expect(atualizado.intervaloKm, lembrete.intervaloKm);
      expect(atualizado.tipoManutencao, lembrete.tipoManutencao);
    });
```

- [ ] **Step 2: Rodar o teste para confirmar que falha**

Run: `flutter test test/models/lembrete_manutencao_test.dart`
Expected: FAIL — `The method 'copyWith' isn't defined for the type 'LembreteManutencao'`.

- [ ] **Step 3: Implementar `copyWith`**

Em `lib/models/lembrete_manutencao.dart`, adicionar este método logo após o `factory LembreteManutencao.fromMap(...)` e antes de `Map<String, dynamic> toMap()`:

```dart
  LembreteManutencao copyWith({
    int? intervaloKm,
    int? intervaloDias,
    int? antecedenciaKm,
    int? antecedenciaDias,
    int? intervaloRepeticaoDias,
    bool? ativo,
    DateTime? resolvidoEm,
  }) {
    return LembreteManutencao(
      id: id,
      veiculoId: veiculoId,
      tipoManutencao: tipoManutencao,
      intervaloKm: intervaloKm ?? this.intervaloKm,
      intervaloDias: intervaloDias ?? this.intervaloDias,
      antecedenciaKm: antecedenciaKm ?? this.antecedenciaKm,
      antecedenciaDias: antecedenciaDias ?? this.antecedenciaDias,
      intervaloRepeticaoDias: intervaloRepeticaoDias ?? this.intervaloRepeticaoDias,
      ativo: ativo ?? this.ativo,
      resolvidoEm: resolvidoEm ?? this.resolvidoEm,
    );
  }
```

- [ ] **Step 4: Rodar o teste para confirmar que passa**

Run: `flutter test test/models/lembrete_manutencao_test.dart`
Expected: PASS (todos os testes do arquivo, incluindo o novo).

---

### Task 2: Localização pt-BR (`flutter_localizations`)

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: nenhuma (config de app).
- Produces: `MaterialApp` com `locale: Locale('pt', 'BR')` — usado implicitamente por todo `showDatePicker` das Tasks 3 e 4.

- [ ] **Step 1: Adicionar a dependência**

Em `pubspec.yaml`, dentro da seção `dependencies:`, logo após o bloco `flutter:\n    sdk: flutter` (linhas 30-32), adicionar:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # The following adds the Cupertino Icons font to your application.
```

- [ ] **Step 2: Buscar as dependências**

Run: `flutter pub get`
Expected: `Got dependencies!` sem erros.

- [ ] **Step 3: Configurar localização em `main.dart`**

Substituir o conteúdo de `lib/main.dart` por:

```dart
// lib/main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/veiculo_provider.dart';
import 'repositories/veiculo_repository.dart';
import 'screens/login_screen.dart';
import 'screens/veiculo_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  final prefs = await SharedPreferences.getInstance();
  runApp(RevisaCarApp(prefs: prefs));
}

class RevisaCarApp extends StatelessWidget {
  final SharedPreferences prefs;

  const RevisaCarApp({super.key, required this.prefs});

  static final _theme = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple));

  static const _localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const _supportedLocales = [Locale('pt', 'BR')];

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        Provider<SharedPreferences>.value(value: prefs),
        Provider<VeiculoRepository>(create: (_) => VeiculoRepository()),
      ],
      child: Consumer<AppAuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;

          if (user == null) {
            return MaterialApp(
              title: 'RevisaCar',
              theme: _theme,
              localizationsDelegates: _localizationsDelegates,
              supportedLocales: _supportedLocales,
              locale: const Locale('pt', 'BR'),
              home: const LoginScreen(),
            );
          }

          return ChangeNotifierProvider<VeiculoProvider>(
            key: ValueKey(user.uid),
            create: (context) => VeiculoProvider(
              repository: context.read<VeiculoRepository>(),
              prefs: context.read<SharedPreferences>(),
              uid: user.uid,
            ),
            child: MaterialApp(
              title: 'RevisaCar',
              theme: _theme,
              localizationsDelegates: _localizationsDelegates,
              supportedLocales: _supportedLocales,
              locale: const Locale('pt', 'BR'),
              home: const VeiculoListScreen(),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Verificar que o projeto compila sem erros**

Run: `flutter analyze lib/main.dart`
Expected: `No issues found!`

---

### Task 3: Rótulos de `TipoManutencao` + `ManutencaoFormScreen`

**Files:**
- Create: `lib/utils/tipo_manutencao_labels.dart`
- Create: `lib/screens/manutencao_form_screen.dart`

**Interfaces:**
- Consumes: `TipoManutencao` (`lib/models/manutencao.dart`), `Manutencao`, `ManutencaoProvider.adicionar/atualizar` (já existentes), `LembreteManutencao.copyWith` (Task 1), `LembreteProvider.atualizar` (já existente).
- Produces: `extension TipoManutencaoLabel on TipoManutencao { String get label; }`; `class ManutencaoFormScreen extends StatefulWidget` com construtor `ManutencaoFormScreen({Key? key, Manutencao? manutencao, TipoManutencao? tipoInicial, LembreteManutencao? lembreteParaResolver})` — rótulos usados pelas Tasks 5, 6 e 8; `ManutencaoFormScreen` usada pelas Tasks 6 e 8.

- [ ] **Step 1: Criar os rótulos**

```dart
// lib/utils/tipo_manutencao_labels.dart
import '../models/manutencao.dart';

extension TipoManutencaoLabel on TipoManutencao {
  String get label {
    switch (this) {
      case TipoManutencao.revisao:
        return 'Revisão';
      case TipoManutencao.trocaOleo:
        return 'Troca de óleo';
      case TipoManutencao.trocaFiltro:
        return 'Troca de filtro';
      case TipoManutencao.pneusRodizio:
        return 'Pneus/Rodízio';
      case TipoManutencao.bateria:
        return 'Bateria';
      case TipoManutencao.palhetas:
        return 'Palhetas';
      case TipoManutencao.arCondicionado:
        return 'Ar-condicionado';
      case TipoManutencao.alinhamentoBalanceamento:
        return 'Alinhamento/Balanceamento';
      case TipoManutencao.outro:
        return 'Outro';
    }
  }
}
```

- [ ] **Step 2: Criar a tela de formulário**

```dart
// lib/screens/manutencao_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lembrete_manutencao.dart';
import '../models/manutencao.dart';
import '../providers/lembrete_provider.dart';
import '../providers/manutencao_provider.dart';
import '../utils/tipo_manutencao_labels.dart';

class ManutencaoFormScreen extends StatefulWidget {
  final Manutencao? manutencao;
  final TipoManutencao? tipoInicial;
  final LembreteManutencao? lembreteParaResolver;

  const ManutencaoFormScreen({
    super.key,
    this.manutencao,
    this.tipoInicial,
    this.lembreteParaResolver,
  });

  @override
  State<ManutencaoFormScreen> createState() => _ManutencaoFormScreenState();
}

class _ManutencaoFormScreenState extends State<ManutencaoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kmNaDataController;
  late final TextEditingController _custoController;
  late final TextEditingController _oficinaController;
  late final TextEditingController _observacoesController;
  late final TextEditingController _descricaoOutroController;
  late TipoManutencao _tipo;
  late DateTime _dataRealizada;
  bool _salvando = false;

  bool get _editando => widget.manutencao != null;

  @override
  void initState() {
    super.initState();
    final m = widget.manutencao;
    _tipo = m?.tipo ?? widget.tipoInicial ?? TipoManutencao.revisao;
    _dataRealizada = m?.dataRealizada ?? DateTime.now();
    _kmNaDataController = TextEditingController(text: m?.kmNaData.toString() ?? '');
    _custoController = TextEditingController(text: m?.custo.toString() ?? '');
    _oficinaController = TextEditingController(text: m?.oficina ?? '');
    _observacoesController = TextEditingController(text: m?.observacoes ?? '');
    _descricaoOutroController = TextEditingController(text: m?.descricaoOutro ?? '');
  }

  @override
  void dispose() {
    _kmNaDataController.dispose();
    _custoController.dispose();
    _oficinaController.dispose();
    _observacoesController.dispose();
    _descricaoOutroController.dispose();
    super.dispose();
  }

  String? _obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  String? _inteiroObrigatorio(String? valor) {
    final erro = _obrigatorio(valor);
    if (erro != null) return erro;
    if (int.tryParse(valor!.trim()) == null) return 'Informe um número válido';
    return null;
  }

  String? _decimalObrigatorio(String? valor) {
    final erro = _obrigatorio(valor);
    if (erro != null) return erro;
    if (double.tryParse(valor!.trim().replaceAll(',', '.')) == null) {
      return 'Informe um valor válido';
    }
    return null;
  }

  String? _descricaoOutroValidator(String? valor) {
    if (_tipo != TipoManutencao.outro) return null;
    return _obrigatorio(valor);
  }

  Future<void> _selecionarData() async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _dataRealizada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selecionada != null) {
      setState(() => _dataRealizada = selecionada);
    }
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    final manutencao = Manutencao(
      id: widget.manutencao?.id ?? '',
      veiculoId: widget.manutencao?.veiculoId ?? '',
      tipo: _tipo,
      descricaoOutro: _tipo == TipoManutencao.outro ? _descricaoOutroController.text.trim() : null,
      dataRealizada: _dataRealizada,
      kmNaData: int.parse(_kmNaDataController.text.trim()),
      custo: double.parse(_custoController.text.trim().replaceAll(',', '.')),
      oficina: _oficinaController.text.trim(),
      observacoes: _observacoesController.text.trim(),
    );

    try {
      final provider = context.read<ManutencaoProvider>();
      if (_editando) {
        await provider.atualizar(manutencao);
      } else {
        await provider.adicionar(manutencao);
      }
      final lembrete = widget.lembreteParaResolver;
      if (lembrete != null) {
        await context
            .read<LembreteProvider>()
            .atualizar(lembrete.copyWith(resolvidoEm: DateTime.now()));
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar. Tente novamente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar manutenção' : 'Nova manutenção')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<TipoManutencao>(
              initialValue: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: TipoManutencao.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (valor) => setState(() => _tipo = valor ?? TipoManutencao.revisao),
            ),
            if (_tipo == TipoManutencao.outro) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricaoOutroController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: _descricaoOutroValidator,
              ),
            ],
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data realizada'),
              subtitle: Text(_formatarData(_dataRealizada)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selecionarData,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _kmNaDataController,
              decoration: const InputDecoration(labelText: 'Km na data'),
              keyboardType: TextInputType.number,
              validator: _inteiroObrigatorio,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _custoController,
              decoration: const InputDecoration(labelText: 'Custo (R\$)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _decimalObrigatorio,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _oficinaController,
              decoration: const InputDecoration(labelText: 'Oficina'),
              validator: _obrigatorio,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observacoesController,
              decoration: const InputDecoration(labelText: 'Observações'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: Text(_salvando ? 'Salvando...' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Verificar que o projeto compila sem erros**

Run: `flutter analyze lib/utils/tipo_manutencao_labels.dart lib/screens/manutencao_form_screen.dart`
Expected: `No issues found!`

---

### Task 4: `AbastecimentoFormScreen`

**Files:**
- Create: `lib/screens/abastecimento_form_screen.dart`

**Interfaces:**
- Consumes: `Abastecimento` (`lib/models/abastecimento.dart`), `AbastecimentoProvider.adicionar/atualizar` (já existentes).
- Produces: `class AbastecimentoFormScreen extends StatefulWidget` com construtor `AbastecimentoFormScreen({Key? key, Abastecimento? abastecimento})` — usado pela Task 7 (`AbastecimentoTab`).

- [ ] **Step 1: Criar a tela**

```dart
// lib/screens/abastecimento_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/abastecimento.dart';
import '../providers/abastecimento_provider.dart';

class AbastecimentoFormScreen extends StatefulWidget {
  final Abastecimento? abastecimento;

  const AbastecimentoFormScreen({super.key, this.abastecimento});

  @override
  State<AbastecimentoFormScreen> createState() => _AbastecimentoFormScreenState();
}

class _AbastecimentoFormScreenState extends State<AbastecimentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kmAtualController;
  late final TextEditingController _litrosController;
  late final TextEditingController _valorTotalController;
  late DateTime _data;
  late bool _tanqueCheio;
  bool _salvando = false;

  bool get _editando => widget.abastecimento != null;

  @override
  void initState() {
    super.initState();
    final a = widget.abastecimento;
    _data = a?.data ?? DateTime.now();
    _kmAtualController = TextEditingController(text: a?.kmAtual.toString() ?? '');
    _litrosController = TextEditingController(text: a?.litros.toString() ?? '');
    _valorTotalController = TextEditingController(text: a?.valorTotal.toString() ?? '');
    _tanqueCheio = a?.tanqueCheio ?? true;
  }

  @override
  void dispose() {
    _kmAtualController.dispose();
    _litrosController.dispose();
    _valorTotalController.dispose();
    super.dispose();
  }

  String? _obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  String? _inteiroObrigatorio(String? valor) {
    final erro = _obrigatorio(valor);
    if (erro != null) return erro;
    if (int.tryParse(valor!.trim()) == null) return 'Informe um número válido';
    return null;
  }

  String? _decimalObrigatorio(String? valor) {
    final erro = _obrigatorio(valor);
    if (erro != null) return erro;
    if (double.tryParse(valor!.trim().replaceAll(',', '.')) == null) {
      return 'Informe um valor válido';
    }
    return null;
  }

  Future<void> _selecionarData() async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selecionada != null) {
      setState(() => _data = selecionada);
    }
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    final abastecimento = Abastecimento(
      id: widget.abastecimento?.id ?? '',
      veiculoId: widget.abastecimento?.veiculoId ?? '',
      data: _data,
      kmAtual: int.parse(_kmAtualController.text.trim()),
      litros: double.parse(_litrosController.text.trim().replaceAll(',', '.')),
      valorTotal: double.parse(_valorTotalController.text.trim().replaceAll(',', '.')),
      tanqueCheio: _tanqueCheio,
    );

    try {
      final provider = context.read<AbastecimentoProvider>();
      if (_editando) {
        await provider.atualizar(abastecimento);
      } else {
        await provider.adicionar(abastecimento);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar. Tente novamente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar abastecimento' : 'Novo abastecimento')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data'),
              subtitle: Text(_formatarData(_data)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selecionarData,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _kmAtualController,
              decoration: const InputDecoration(labelText: 'Km atual'),
              keyboardType: TextInputType.number,
              validator: _inteiroObrigatorio,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _litrosController,
              decoration: const InputDecoration(labelText: 'Litros'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _decimalObrigatorio,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _valorTotalController,
              decoration: const InputDecoration(labelText: 'Valor total (R\$)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _decimalObrigatorio,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tanque cheio'),
              value: _tanqueCheio,
              onChanged: (valor) => setState(() => _tanqueCheio = valor),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: Text(_salvando ? 'Salvando...' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verificar que o projeto compila sem erros**

Run: `flutter analyze lib/screens/abastecimento_form_screen.dart`
Expected: `No issues found!`

---

### Task 5: `LembreteFormScreen`

**Files:**
- Create: `lib/screens/lembrete_form_screen.dart`

**Interfaces:**
- Consumes: `LembreteManutencao`, `TipoManutencao` (`lib/models/manutencao.dart`), `LembreteProvider.adicionar/atualizar` (já existentes), `TipoManutencaoLabel.label` (Task 3).
- Produces: `class LembreteFormScreen extends StatefulWidget` com construtor `LembreteFormScreen({Key? key, LembreteManutencao? lembrete})` — usado pela Task 8 (`LembreteTab`).

- [ ] **Step 1: Criar a tela**

```dart
// lib/screens/lembrete_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lembrete_manutencao.dart';
import '../models/manutencao.dart';
import '../providers/lembrete_provider.dart';
import '../utils/tipo_manutencao_labels.dart';

class LembreteFormScreen extends StatefulWidget {
  final LembreteManutencao? lembrete;

  const LembreteFormScreen({super.key, this.lembrete});

  @override
  State<LembreteFormScreen> createState() => _LembreteFormScreenState();
}

class _LembreteFormScreenState extends State<LembreteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _intervaloKmController;
  late final TextEditingController _intervaloDiasController;
  late final TextEditingController _antecedenciaKmController;
  late final TextEditingController _antecedenciaDiasController;
  late final TextEditingController _intervaloRepeticaoDiasController;
  late TipoManutencao _tipoManutencao;
  late bool _ativo;
  bool _salvando = false;

  bool get _editando => widget.lembrete != null;

  @override
  void initState() {
    super.initState();
    final l = widget.lembrete;
    _tipoManutencao = l?.tipoManutencao ?? TipoManutencao.revisao;
    _intervaloKmController = TextEditingController(text: l?.intervaloKm?.toString() ?? '');
    _intervaloDiasController = TextEditingController(text: l?.intervaloDias?.toString() ?? '');
    _antecedenciaKmController = TextEditingController(text: l?.antecedenciaKm.toString() ?? '');
    _antecedenciaDiasController =
        TextEditingController(text: l?.antecedenciaDias.toString() ?? '');
    _intervaloRepeticaoDiasController =
        TextEditingController(text: l?.intervaloRepeticaoDias.toString() ?? '');
    _ativo = l?.ativo ?? true;
  }

  @override
  void dispose() {
    _intervaloKmController.dispose();
    _intervaloDiasController.dispose();
    _antecedenciaKmController.dispose();
    _antecedenciaDiasController.dispose();
    _intervaloRepeticaoDiasController.dispose();
    super.dispose();
  }

  String? _inteiroOpcional(String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;
    if (int.tryParse(valor.trim()) == null) return 'Informe um número válido';
    return null;
  }

  String? _validarIntervaloKm(String? valor) {
    final erroNumero = _inteiroOpcional(valor);
    if (erroNumero != null) return erroNumero;
    final semKm = valor == null || valor.trim().isEmpty;
    final semDias = _intervaloDiasController.text.trim().isEmpty;
    if (semKm && semDias) return 'Preencha km ou dias';
    return null;
  }

  String? _validarIntervaloDias(String? valor) {
    final erroNumero = _inteiroOpcional(valor);
    if (erroNumero != null) return erroNumero;
    final semDias = valor == null || valor.trim().isEmpty;
    final semKm = _intervaloKmController.text.trim().isEmpty;
    if (semKm && semDias) return 'Preencha km ou dias';
    return null;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    final lembrete = LembreteManutencao(
      id: widget.lembrete?.id ?? '',
      veiculoId: widget.lembrete?.veiculoId ?? '',
      tipoManutencao: _tipoManutencao,
      intervaloKm: _intervaloKmController.text.trim().isEmpty
          ? null
          : int.parse(_intervaloKmController.text.trim()),
      intervaloDias: _intervaloDiasController.text.trim().isEmpty
          ? null
          : int.parse(_intervaloDiasController.text.trim()),
      antecedenciaKm: _antecedenciaKmController.text.trim().isEmpty
          ? 0
          : int.parse(_antecedenciaKmController.text.trim()),
      antecedenciaDias: _antecedenciaDiasController.text.trim().isEmpty
          ? 0
          : int.parse(_antecedenciaDiasController.text.trim()),
      intervaloRepeticaoDias: _intervaloRepeticaoDiasController.text.trim().isEmpty
          ? 3
          : int.parse(_intervaloRepeticaoDiasController.text.trim()),
      ativo: _ativo,
      resolvidoEm: widget.lembrete?.resolvidoEm,
    );

    try {
      final provider = context.read<LembreteProvider>();
      if (_editando) {
        await provider.atualizar(lembrete);
      } else {
        await provider.adicionar(lembrete);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar. Tente novamente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar lembrete' : 'Novo lembrete')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<TipoManutencao>(
              initialValue: _tipoManutencao,
              decoration: const InputDecoration(labelText: 'Tipo de manutenção'),
              items: TipoManutencao.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (valor) =>
                  setState(() => _tipoManutencao = valor ?? TipoManutencao.revisao),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _intervaloKmController,
              decoration: const InputDecoration(labelText: 'Intervalo (km)'),
              keyboardType: TextInputType.number,
              validator: _validarIntervaloKm,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _intervaloDiasController,
              decoration: const InputDecoration(labelText: 'Intervalo (dias)'),
              keyboardType: TextInputType.number,
              validator: _validarIntervaloDias,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _antecedenciaKmController,
              decoration: const InputDecoration(labelText: 'Antecedência (km)'),
              keyboardType: TextInputType.number,
              validator: _inteiroOpcional,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _antecedenciaDiasController,
              decoration: const InputDecoration(labelText: 'Antecedência (dias)'),
              keyboardType: TextInputType.number,
              validator: _inteiroOpcional,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _intervaloRepeticaoDiasController,
              decoration: const InputDecoration(labelText: 'Repetir notificação a cada (dias)'),
              keyboardType: TextInputType.number,
              validator: _inteiroOpcional,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ativo'),
              value: _ativo,
              onChanged: (valor) => setState(() => _ativo = valor),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: Text(_salvando ? 'Salvando...' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verificar que o projeto compila sem erros**

Run: `flutter analyze lib/screens/lembrete_form_screen.dart`
Expected: `No issues found!`

---

### Task 6: Diálogo de exclusão compartilhado + `ManutencaoTab`

**Files:**
- Create: `lib/widgets/confirmar_exclusao_dialog.dart`
- Create: `lib/widgets/manutencao_tab.dart`

**Interfaces:**
- Consumes: `ManutencaoProvider` (`manutencoes`, `remover(String id)`, já existentes), `ManutencaoFormScreen` (Task 3), `TipoManutencaoLabel.label` (Task 3).
- Produces: `Future<bool> confirmarExclusaoDialog(BuildContext context, {required String titulo, required String mensagem})` — usado pelas Tasks 7 e 8; `class ManutencaoTab extends StatelessWidget` — usado pela Task 9 (`DetalheVeiculoScreen`).

- [ ] **Step 1: Criar o diálogo compartilhado**

```dart
// lib/widgets/confirmar_exclusao_dialog.dart
import 'package:flutter/material.dart';

Future<bool> confirmarExclusaoDialog(
  BuildContext context, {
  required String titulo,
  required String mensagem,
}) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  return confirmar ?? false;
}
```

- [ ] **Step 2: Criar a aba de Manutenções**

```dart
// lib/widgets/manutencao_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/manutencao_provider.dart';
import '../screens/manutencao_form_screen.dart';
import '../utils/tipo_manutencao_labels.dart';
import 'confirmar_exclusao_dialog.dart';

class ManutencaoTab extends StatelessWidget {
  const ManutencaoTab({super.key});

  Future<bool> _excluir(BuildContext context, ManutencaoProvider provider, String id) async {
    final confirmar = await confirmarExclusaoDialog(
      context,
      titulo: 'Excluir manutenção',
      mensagem: 'Excluir este registro de manutenção? Essa ação não pode ser desfeita.',
    );
    if (!confirmar) return false;

    try {
      await provider.remover(id);
      return true;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir. Tente novamente.')),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final manutencoes = context.watch<ManutencaoProvider>().manutencoes.toList()
      ..sort((a, b) => b.dataRealizada.compareTo(a.dataRealizada));
    final provider = context.read<ManutencaoProvider>();

    return Scaffold(
      body: manutencoes.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma manutenção registrada.\nToque em + para adicionar a primeira.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: manutencoes.length,
              itemBuilder: (context, index) {
                final manutencao = manutencoes[index];
                return Dismissible(
                  key: ValueKey(manutencao.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) => _excluir(context, provider, manutencao.id),
                  child: ListTile(
                    title: Text(manutencao.tipo.label),
                    subtitle: Text(
                      '${manutencao.oficina} • ${manutencao.kmNaData} km • '
                      'R\$ ${manutencao.custo.toStringAsFixed(2)}',
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ManutencaoFormScreen(manutencao: manutencao),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_manutencao',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ManutencaoFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

- [ ] **Step 3: Verificar que o projeto compila sem erros**

Run: `flutter analyze lib/widgets/confirmar_exclusao_dialog.dart lib/widgets/manutencao_tab.dart`
Expected: `No issues found!`

---

### Task 7: `AbastecimentoTab`

**Files:**
- Create: `lib/widgets/abastecimento_tab.dart`

**Interfaces:**
- Consumes: `AbastecimentoProvider` (`abastecimentos`, `remover(String id)`, já existentes), `AbastecimentoFormScreen` (Task 4), `confirmarExclusaoDialog` (Task 6).
- Produces: `class AbastecimentoTab extends StatelessWidget` — usado pela Task 9 (`DetalheVeiculoScreen`).

- [ ] **Step 1: Criar a aba**

```dart
// lib/widgets/abastecimento_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/abastecimento_provider.dart';
import '../screens/abastecimento_form_screen.dart';
import 'confirmar_exclusao_dialog.dart';

class AbastecimentoTab extends StatelessWidget {
  const AbastecimentoTab({super.key});

  Future<bool> _excluir(BuildContext context, AbastecimentoProvider provider, String id) async {
    final confirmar = await confirmarExclusaoDialog(
      context,
      titulo: 'Excluir abastecimento',
      mensagem: 'Excluir este registro de abastecimento? Essa ação não pode ser desfeita.',
    );
    if (!confirmar) return false;

    try {
      await provider.remover(id);
      return true;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir. Tente novamente.')),
        );
      }
      return false;
    }
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    final abastecimentos = context.watch<AbastecimentoProvider>().abastecimentos.toList()
      ..sort((a, b) => b.data.compareTo(a.data));
    final provider = context.read<AbastecimentoProvider>();

    return Scaffold(
      body: abastecimentos.isEmpty
          ? const Center(
              child: Text(
                'Nenhum abastecimento registrado.\nToque em + para adicionar o primeiro.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: abastecimentos.length,
              itemBuilder: (context, index) {
                final abastecimento = abastecimentos[index];
                return Dismissible(
                  key: ValueKey(abastecimento.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) => _excluir(context, provider, abastecimento.id),
                  child: ListTile(
                    title: Text(_formatarData(abastecimento.data)),
                    subtitle: Text(
                      '${abastecimento.litros.toStringAsFixed(1)} L • '
                      'R\$ ${abastecimento.valorTotal.toStringAsFixed(2)} • '
                      '${abastecimento.kmAtual} km'
                      '${abastecimento.tanqueCheio ? ' • Tanque cheio' : ''}',
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AbastecimentoFormScreen(abastecimento: abastecimento),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_abastecimento',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AbastecimentoFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

- [ ] **Step 2: Verificar que o projeto compila sem erros**

Run: `flutter analyze lib/widgets/abastecimento_tab.dart`
Expected: `No issues found!`

---

### Task 8: `LembreteTab`

**Files:**
- Create: `lib/widgets/lembrete_tab.dart`

**Interfaces:**
- Consumes: `LembreteProvider` (`lembretes`, `remover(String id)`), `ManutencaoProvider.manutencoes` (já existentes), `LembreteService.manutencaoMaisRecente/calcularProximaMeta/calcularStatus`, `StatusLembrete` (`lib/services/lembrete_service.dart`, já existente), `LembreteFormScreen` (Task 5), `ManutencaoFormScreen` (Task 3), `confirmarExclusaoDialog` (Task 6), `TipoManutencaoLabel.label` (Task 3).
- Produces: `class LembreteTab extends StatelessWidget` com construtor `LembreteTab({Key? key, required int kmAtual})` — usado pela Task 9 (`DetalheVeiculoScreen`).

- [ ] **Step 1: Criar a aba**

```dart
// lib/widgets/lembrete_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/lembrete_provider.dart';
import '../providers/manutencao_provider.dart';
import '../screens/lembrete_form_screen.dart';
import '../screens/manutencao_form_screen.dart';
import '../services/lembrete_service.dart';
import '../utils/tipo_manutencao_labels.dart';
import 'confirmar_exclusao_dialog.dart';

class LembreteTab extends StatelessWidget {
  final int kmAtual;

  const LembreteTab({super.key, required this.kmAtual});

  String _rotuloStatus(StatusLembrete status) {
    switch (status) {
      case StatusLembrete.emDia:
        return 'Em dia';
      case StatusLembrete.alertaAntecipado:
        return 'Alerta antecipado';
      case StatusLembrete.vencido:
        return 'Vencido';
    }
  }

  Color _corStatus(BuildContext context, StatusLembrete status) {
    switch (status) {
      case StatusLembrete.emDia:
        return Colors.green;
      case StatusLembrete.alertaAntecipado:
        return Colors.orange;
      case StatusLembrete.vencido:
        return Theme.of(context).colorScheme.error;
    }
  }

  Future<bool> _excluir(BuildContext context, LembreteProvider provider, String id) async {
    final confirmar = await confirmarExclusaoDialog(
      context,
      titulo: 'Excluir lembrete',
      mensagem: 'Excluir este lembrete? Essa ação não pode ser desfeita.',
    );
    if (!confirmar) return false;

    try {
      await provider.remover(id);
      return true;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir. Tente novamente.')),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lembretes = context.watch<LembreteProvider>().lembretes;
    final manutencoes = context.watch<ManutencaoProvider>().manutencoes;
    final provider = context.read<LembreteProvider>();
    final hoje = DateTime.now();

    return Scaffold(
      body: lembretes.isEmpty
          ? const Center(
              child: Text(
                'Nenhum lembrete cadastrado.\nToque em + para adicionar o primeiro.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: lembretes.length,
              itemBuilder: (context, index) {
                final lembrete = lembretes[index];
                final referencia =
                    LembreteService.manutencaoMaisRecente(manutencoes, lembrete.tipoManutencao);
                final meta = LembreteService.calcularProximaMeta(
                  lembrete: lembrete,
                  kmReferencia: referencia?.kmNaData ?? 0,
                  dataReferencia: referencia?.dataRealizada ?? hoje,
                );
                final status = LembreteService.calcularStatus(
                  lembrete: lembrete,
                  meta: meta,
                  kmAtual: kmAtual,
                  hoje: hoje,
                );

                return Dismissible(
                  key: ValueKey(lembrete.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) => _excluir(context, provider, lembrete.id),
                  child: ListTile(
                    leading: Icon(Icons.circle, color: _corStatus(context, status), size: 14),
                    title: Text(lembrete.tipoManutencao.label),
                    subtitle: Text(_rotuloStatus(status)),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => LembreteFormScreen(lembrete: lembrete)),
                    ),
                    trailing: status == StatusLembrete.emDia
                        ? null
                        : TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ManutencaoFormScreen(
                                  tipoInicial: lembrete.tipoManutencao,
                                  lembreteParaResolver: lembrete,
                                ),
                              ),
                            ),
                            child: const Text('Marcar como resolvido'),
                          ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_lembrete',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LembreteFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

- [ ] **Step 2: Verificar que o projeto compila sem erros**

Run: `flutter analyze lib/widgets/lembrete_tab.dart`
Expected: `No issues found!`

---

### Task 9: `DetalheVeiculoScreen`

**Files:**
- Create: `lib/screens/detalhe_veiculo_screen.dart`

**Interfaces:**
- Consumes: `Veiculo` (`lib/models/veiculo.dart`), `VeiculoProvider` (`uid`, `veiculos`, já existentes), `VeiculoRepository` (Provider já disponível em `main.dart`), `ManutencaoProvider`/`ManutencaoRepository`, `AbastecimentoProvider`/`AbastecimentoRepository`, `LembreteProvider`/`LembreteRepository` (já existentes), `VeiculoFormScreen` (Fase A), `ManutencaoTab` (Task 6), `AbastecimentoTab` (Task 7), `LembreteTab` (Task 8).
- Produces: `class DetalheVeiculoScreen extends StatelessWidget` com construtor `DetalheVeiculoScreen({Key? key, required Veiculo veiculo})` — usado pela Task 10 (`VeiculoListScreen`).

- [ ] **Step 1: Criar a tela**

```dart
// lib/screens/detalhe_veiculo_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/veiculo.dart';
import '../providers/abastecimento_provider.dart';
import '../providers/lembrete_provider.dart';
import '../providers/manutencao_provider.dart';
import '../providers/veiculo_provider.dart';
import '../repositories/abastecimento_repository.dart';
import '../repositories/lembrete_repository.dart';
import '../repositories/manutencao_repository.dart';
import '../repositories/veiculo_repository.dart';
import '../widgets/abastecimento_tab.dart';
import '../widgets/lembrete_tab.dart';
import '../widgets/manutencao_tab.dart';
import 'veiculo_form_screen.dart';

class DetalheVeiculoScreen extends StatelessWidget {
  final Veiculo veiculo;

  const DetalheVeiculoScreen({super.key, required this.veiculo});

  @override
  Widget build(BuildContext context) {
    final veiculoProvider = context.watch<VeiculoProvider>();
    final veiculoAtual = veiculoProvider.veiculos.firstWhere(
      (v) => v.id == veiculo.id,
      orElse: () => veiculo,
    );
    final uid = veiculoProvider.uid;

    return MultiProvider(
      key: ValueKey(veiculo.id),
      providers: [
        ChangeNotifierProvider<ManutencaoProvider>(
          create: (context) => ManutencaoProvider(
            repository: ManutencaoRepository(),
            veiculoRepository: context.read<VeiculoRepository>(),
            uid: uid,
          )..escutarVeiculo(veiculo.id),
        ),
        ChangeNotifierProvider<AbastecimentoProvider>(
          create: (context) => AbastecimentoProvider(
            repository: AbastecimentoRepository(),
            veiculoRepository: context.read<VeiculoRepository>(),
            uid: uid,
          )..escutarVeiculo(veiculo.id),
        ),
        ChangeNotifierProvider<LembreteProvider>(
          create: (context) => LembreteProvider(
            repository: LembreteRepository(),
            uid: uid,
          )..escutarVeiculo(veiculo.id),
        ),
      ],
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(veiculoAtual.nome),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => VeiculoFormScreen(veiculo: veiculoAtual)),
                ),
              ),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Manutenções'),
                Tab(text: 'Abastecimentos'),
                Tab(text: 'Lembretes'),
              ],
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${veiculoAtual.modelo} • ${veiculoAtual.ano} • ${veiculoAtual.placa} • '
                  '${veiculoAtual.kmAtual} km',
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    const ManutencaoTab(),
                    const AbastecimentoTab(),
                    LembreteTab(kmAtual: veiculoAtual.kmAtual),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verificar que o projeto compila sem erros**

Run: `flutter analyze lib/screens/detalhe_veiculo_screen.dart`
Expected: `No issues found!`

---

### Task 10: `VeiculoListScreen` — navegação para o Detalhe

**Files:**
- Modify: `lib/screens/veiculo_list_screen.dart`

**Interfaces:**
- Consumes: `DetalheVeiculoScreen` (Task 9).
- Produces: fluxo completo card → Detalhe.

- [ ] **Step 1: Trocar o destino do toque no card**

Em `lib/screens/veiculo_list_screen.dart`, adicionar o import (após a linha `import 'configuracoes_screen.dart';`):

```dart
import 'configuracoes_screen.dart';
import 'detalhe_veiculo_screen.dart';
import 'veiculo_form_screen.dart';
```

E trocar o `onTap` do `VeiculoCard` (dentro do `itemBuilder`) de:

```dart
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => VeiculoFormScreen(veiculo: veiculo)),
                  ),
```

para:

```dart
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DetalheVeiculoScreen(veiculo: veiculo)),
                  ),
```

O `FloatingActionButton` (cadastrar veículo novo) continua abrindo `VeiculoFormScreen()` sem alterações.

- [ ] **Step 2: Verificar que o projeto compila sem erros**

Run: `flutter analyze lib/screens/veiculo_list_screen.dart`
Expected: `No issues found!`

---

### Task 11: Verificação final e smoke test manual

**Files:** nenhum (só verificação).

**Interfaces:** nenhuma nova.

- [ ] **Step 1: Rodar a análise estática do projeto inteiro**

Run: `flutter analyze`
Expected: sem novos erros/warnings introduzidos por este plano (achados pré-existentes de fases anteriores, não relacionados a este trabalho, podem continuar aparecendo).

- [ ] **Step 2: Rodar a suíte de testes completa**

Run: `flutter test`
Expected: PASS em todos os testes (fases anteriores + o novo teste da Task 1).

- [ ] **Step 3: Smoke test manual (sem automação — fora do escopo desta fase)**

Run: `flutter run` (em emulador/dispositivo Android ou simulador/dispositivo iOS conectado)
Checklist manual:
- Tocar um card na lista de veículos abre o Detalhe (header com dados do veículo + 3 abas).
- Ícone de editar (✏️) no AppBar do Detalhe abre o formulário de edição do veículo; salvar reflete no header.
- Aba Manutenções: FAB abre o formulário; cadastrar uma manutenção faz ela aparecer na lista (mais recente primeiro); tocar um item abre em modo edição; deslizar um item pede confirmação e, ao confirmar, remove.
- Selecionar tipo "Outro" no formulário de manutenção exige preencher a descrição.
- Aba Abastecimentos: mesmo fluxo de criar/editar/excluir; alternar "Tanque cheio".
- Aba Lembretes: cadastrar um lembrete (ex: Troca de óleo, intervalo 5000 km) e verificar que aparece com status "Em dia"/"Alerta"/"Vencido" condizente com o km atual do veículo.
- Num lembrete com status "Alerta antecipado" ou "Vencido", tocar "Marcar como resolvido" abre o formulário de manutenção já com o tipo certo selecionado; salvar volta para a aba de Lembretes e o status deve refletir a nova manutenção.
- `DatePicker` (nos formulários de Manutenção e Abastecimento) abre em português (meses/dias da semana).
- Deslizar um lembrete pede confirmação e, ao confirmar, remove.

---

## Plano concluído quando

Tasks 1–11 concluídas, `flutter analyze` e `flutter test` passando, e o smoke test manual da Task 11 realizado com sucesso pelo usuário.
