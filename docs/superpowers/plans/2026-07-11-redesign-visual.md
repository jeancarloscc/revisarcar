# Redesign Visual do App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aplicar o novo visual (baseado no protótipo Figma Make) em todas as telas do app RevisaCar — tema claro/escuro próprio, tipografia Barlow Condensed + Inter, ícone/cor por tipo de manutenção, cards em vez de listas cruas, e um acordeão para a seção de intervalos de manutenção. Nenhuma mudança de modelo de dados, provider ou regra de negócio.

**Architecture:** Um módulo de tema central (`lib/theme/app_theme.dart`) com `ThemeData` claro/escuro e constantes de cor/raio; um catálogo `TipoManutencaoVisual` (ícone+cor por tipo); um `ThemeModeProvider` (liga/desliga tema escuro, persiste em `SharedPreferences`) plugado no `MaterialApp` em `main.dart`. Cada tela/widget é então redesenhado individualmente reaproveitando esses três módulos, sem tocar em providers de dados existentes.

**Tech Stack:** Flutter/Dart, Material 3, `google_fonts`, `provider`, `shared_preferences` (já usado).

## Global Constraints

- Nenhuma mudança em models, repositories, ou regras de negócio dos providers existentes (`ManutencaoProvider`, `LembreteProvider`, `AbastecimentoProvider`, `VeiculoProvider`) — só a camada visual.
- Paleta claro: background `#F3E6D7`, foreground/primary `#162936`, card `#FFFCF8`, secondary `#EEDDD2`, muted `#E8D5C4`, accent `#CE9D78`, destructive `#C0392B`.
- Paleta escuro: background `#162936`, foreground `#F3E6D7`, card `#25343E`, secondary `#1D2F3A`, accent `#CE9D78` (igual nos dois temas), destructive `#E74C3C`.
- Cores de status de lembrete (iguais nos dois temas): Em dia texto `#16A34A`/fundo `#F0FDF4`; Alerta texto `#EA580C`/fundo `#FFF7ED`; Vencido texto `#DC2626`/fundo `#FEF2F2`.
- Raio de canto: `kCardRadius = 16.0` (cards), `kInputRadius = 12.0` (inputs/botões).
- Tipografia: `google_fonts` — `GoogleFonts.barlowCondensedTextTheme()` para títulos grandes (peso `w900`), `GoogleFonts.interTextTheme()` como base do texto.
- Catálogo ícone/cor por `TipoManutencao`: `revisao`→`Icons.assignment_turned_in`/`#059669`; `trocaOleo`→`Icons.water_drop`/`#F07810`; `trocaFiltro`→`Icons.air`/`#4A90D9`; `pneusRodizio`→`Icons.circle`/`#6B7280`; `bateria`→`Icons.battery_charging_full`/`#D97706`; `palhetas`→`Icons.cleaning_services`/`#0891B2`; `arCondicionado`→`Icons.ac_unit`/`#0EA5E9`; `alinhamentoBalanceamento`→`Icons.tune`/`#7C3AED`; `outro`→`Icons.more_horiz`/`#64748B`.
- Sem testes de widget (convenção já estabelecida — `test/` só tem `models/`, `services/`, `repositories/`, `providers/`, `utils/`, agora também `theme/`). Verificação por task: `flutter analyze` no(s) arquivo(s) tocado(s) + `flutter test` completo sem regressão.
- Projeto NÃO é um repositório git — nenhum comando `git` em nenhuma task.

---

### Task 1: Tema base (`app_theme.dart`) + dependência `google_fonts`

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/theme/app_theme.dart`
- Test: `test/theme/app_theme_test.dart`

**Interfaces:**
- Produces: `const double kCardRadius`, `const double kInputRadius`, `const Color kAccentColor`, `const Color kStatusEmDiaTexto`, `const Color kStatusEmDiaFundo`, `const Color kStatusAlertaTexto`, `const Color kStatusAlertaFundo`, `const Color kStatusVencidoTexto`, `const Color kStatusVencidoFundo`, `final ThemeData appThemeLight`, `final ThemeData appThemeDark` — todos em `lib/theme/app_theme.dart`.

- [ ] **Step 1: Adicionar a dependência**

Em `pubspec.yaml`, adicionar `google_fonts` logo após `shared_preferences: ^2.5.5`:

```yaml
  shared_preferences: ^2.5.5
  google_fonts: ^6.2.1
```

Rodar: `flutter pub get`

- [ ] **Step 2: Escrever o teste que falha**

Criar `test/theme/app_theme_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/theme/app_theme.dart';

void main() {
  group('appTheme', () {
    test('kCardRadius e kInputRadius têm os valores esperados', () {
      expect(kCardRadius, 16.0);
      expect(kInputRadius, 12.0);
    });

    test('tema claro usa a paleta esperada', () {
      expect(appThemeLight.colorScheme.primary, const Color(0xFF162936));
      expect(appThemeLight.colorScheme.surface, const Color(0xFFFFFCF8));
      expect(appThemeLight.colorScheme.error, const Color(0xFFC0392B));
      expect(appThemeLight.scaffoldBackgroundColor, const Color(0xFFF3E6D7));
    });

    test('tema escuro usa a paleta esperada', () {
      expect(appThemeDark.colorScheme.primary, kAccentColor);
      expect(appThemeDark.colorScheme.surface, const Color(0xFF25343E));
      expect(appThemeDark.colorScheme.error, const Color(0xFFE74C3C));
      expect(appThemeDark.scaffoldBackgroundColor, const Color(0xFF162936));
    });

    test('kAccentColor é igual nos dois temas', () {
      expect(kAccentColor, const Color(0xFFCE9D78));
    });
  });
}
```

- [ ] **Step 3: Rodar o teste e confirmar que falha**

Run: `flutter test test/theme/app_theme_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:revisacar/theme/app_theme.dart'`.

- [ ] **Step 4: Implementar `app_theme.dart`**

Criar `lib/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const double kCardRadius = 16.0;
const double kInputRadius = 12.0;

const Color kAccentColor = Color(0xFFCE9D78);
const Color kBackgroundLight = Color(0xFFF3E6D7);
const Color kBackgroundDark = Color(0xFF162936);

const Color kStatusEmDiaTexto = Color(0xFF16A34A);
const Color kStatusEmDiaFundo = Color(0xFFF0FDF4);
const Color kStatusAlertaTexto = Color(0xFFEA580C);
const Color kStatusAlertaFundo = Color(0xFFFFF7ED);
const Color kStatusVencidoTexto = Color(0xFFDC2626);
const Color kStatusVencidoFundo = Color(0xFFFEF2F2);

const ColorScheme _colorSchemeLight = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF162936),
  onPrimary: Color(0xFFF3E6D7),
  secondary: Color(0xFFEEDDD2),
  onSecondary: Color(0xFF162936),
  error: Color(0xFFC0392B),
  onError: Color(0xFFFFFFFF),
  surface: Color(0xFFFFFCF8),
  onSurface: Color(0xFF162936),
);

const ColorScheme _colorSchemeDark = ColorScheme(
  brightness: Brightness.dark,
  primary: kAccentColor,
  onPrimary: Color(0xFF162936),
  secondary: Color(0xFF1D2F3A),
  onSecondary: Color(0xFFEEDDD2),
  error: Color(0xFFE74C3C),
  onError: Color(0xFFFFFFFF),
  surface: Color(0xFF25343E),
  onSurface: Color(0xFFF3E6D7),
);

ThemeData _buildTheme(ColorScheme colorScheme, Color background) {
  final base = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: background,
  );
  final bodyText = GoogleFonts.interTextTheme(base.textTheme);
  final displayText = GoogleFonts.barlowCondensedTextTheme(base.textTheme);

  return base.copyWith(
    textTheme: bodyText.copyWith(
      headlineLarge: displayText.headlineLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
      ),
      headlineMedium: displayText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      ),
      headlineSmall: displayText.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      titleLarge: displayText.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kInputRadius),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kInputRadius)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: kAccentColor.withValues(alpha: 0.18),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selecionado = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selecionado ? kAccentColor : colorScheme.onSurface.withValues(alpha: 0.5),
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selecionado = states.contains(WidgetState.selected);
        return TextStyle(
          color: selecionado ? kAccentColor : colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        );
      }),
    ),
  );
}

final ThemeData appThemeLight = _buildTheme(_colorSchemeLight, kBackgroundLight);
final ThemeData appThemeDark = _buildTheme(_colorSchemeDark, kBackgroundDark);
```

- [ ] **Step 5: Rodar o teste e confirmar que passa**

Run: `flutter test test/theme/app_theme_test.dart`
Expected: `All tests passed!`

- [ ] **Step 6: Rodar análise estática**

Run: `flutter analyze lib/theme/app_theme.dart`
Expected: `No issues found!`

- [ ] **Step 7: Commit** (pular — projeto não é um repositório git; apenas confirme que os arquivos foram salvos)

---

### Task 2: Catálogo ícone + cor por tipo de manutenção

**Files:**
- Create: `lib/utils/tipo_manutencao_visual.dart`
- Test: `test/utils/tipo_manutencao_visual_test.dart`

**Interfaces:**
- Consumes: `TipoManutencao` (`lib/models/manutencao.dart`, já existe).
- Produces: `extension TipoManutencaoVisual on TipoManutencao { IconData get icon; Color get cor; }`.

- [ ] **Step 1: Escrever o teste que falha**

Criar `test/utils/tipo_manutencao_visual_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/manutencao.dart';
import 'package:revisacar/utils/tipo_manutencao_visual.dart';

void main() {
  group('TipoManutencaoVisual', () {
    test('todo TipoManutencao tem ícone e cor definidos', () {
      for (final tipo in TipoManutencao.values) {
        expect(tipo.icon, isA<IconData>());
        expect(tipo.cor, isA<Color>());
      }
    });

    test('valores específicos batem com a tabela do design', () {
      expect(TipoManutencao.trocaOleo.icon, Icons.water_drop);
      expect(TipoManutencao.trocaOleo.cor, const Color(0xFFF07810));
      expect(TipoManutencao.revisao.icon, Icons.assignment_turned_in);
      expect(TipoManutencao.revisao.cor, const Color(0xFF059669));
      expect(TipoManutencao.outro.icon, Icons.more_horiz);
      expect(TipoManutencao.outro.cor, const Color(0xFF64748B));
    });

    test('cada tipo tem uma cor distinta dos demais', () {
      final cores = TipoManutencao.values.map((t) => t.cor).toSet();
      expect(cores.length, TipoManutencao.values.length);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/utils/tipo_manutencao_visual_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:revisacar/utils/tipo_manutencao_visual.dart'`.

- [ ] **Step 3: Implementar o catálogo**

Criar `lib/utils/tipo_manutencao_visual.dart`:

```dart
import 'package:flutter/material.dart';

import '../models/manutencao.dart';

extension TipoManutencaoVisual on TipoManutencao {
  IconData get icon {
    switch (this) {
      case TipoManutencao.revisao:
        return Icons.assignment_turned_in;
      case TipoManutencao.trocaOleo:
        return Icons.water_drop;
      case TipoManutencao.trocaFiltro:
        return Icons.air;
      case TipoManutencao.pneusRodizio:
        return Icons.circle;
      case TipoManutencao.bateria:
        return Icons.battery_charging_full;
      case TipoManutencao.palhetas:
        return Icons.cleaning_services;
      case TipoManutencao.arCondicionado:
        return Icons.ac_unit;
      case TipoManutencao.alinhamentoBalanceamento:
        return Icons.tune;
      case TipoManutencao.outro:
        return Icons.more_horiz;
    }
  }

  Color get cor {
    switch (this) {
      case TipoManutencao.revisao:
        return const Color(0xFF059669);
      case TipoManutencao.trocaOleo:
        return const Color(0xFFF07810);
      case TipoManutencao.trocaFiltro:
        return const Color(0xFF4A90D9);
      case TipoManutencao.pneusRodizio:
        return const Color(0xFF6B7280);
      case TipoManutencao.bateria:
        return const Color(0xFFD97706);
      case TipoManutencao.palhetas:
        return const Color(0xFF0891B2);
      case TipoManutencao.arCondicionado:
        return const Color(0xFF0EA5E9);
      case TipoManutencao.alinhamentoBalanceamento:
        return const Color(0xFF7C3AED);
      case TipoManutencao.outro:
        return const Color(0xFF64748B);
    }
  }
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/utils/tipo_manutencao_visual_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Rodar análise estática**

Run: `flutter analyze lib/utils/tipo_manutencao_visual.dart`
Expected: `No issues found!`

---

### Task 3: `ThemeModeProvider`

**Files:**
- Create: `lib/providers/theme_mode_provider.dart`
- Test: `test/providers/theme_mode_provider_test.dart`

**Interfaces:**
- Produces: `class ThemeModeProvider extends ChangeNotifier { ThemeModeProvider(SharedPreferences prefs); ThemeMode get themeMode; Future<void> alternar(); }`.

- [ ] **Step 1: Escrever o teste que falha**

Criar `test/providers/theme_mode_provider_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/providers/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('começa em ThemeMode.light quando não há preferência salva', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = ThemeModeProvider(prefs);

    expect(provider.themeMode, ThemeMode.light);
  });

  test('carrega ThemeMode.dark quando a preferência salva é true', () async {
    SharedPreferences.setMockInitialValues({'tema_escuro': true});
    final prefs = await SharedPreferences.getInstance();
    final provider = ThemeModeProvider(prefs);

    expect(provider.themeMode, ThemeMode.dark);
  });

  test('alternar() troca o tema e persiste a escolha', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = ThemeModeProvider(prefs);

    await provider.alternar();
    expect(provider.themeMode, ThemeMode.dark);
    expect(prefs.getBool('tema_escuro'), true);

    await provider.alternar();
    expect(provider.themeMode, ThemeMode.light);
    expect(prefs.getBool('tema_escuro'), false);
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/providers/theme_mode_provider_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:revisacar/providers/theme_mode_provider.dart'`.

- [ ] **Step 3: Implementar `ThemeModeProvider`**

Criar `lib/providers/theme_mode_provider.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeProvider extends ChangeNotifier {
  static const _temaEscuroKey = 'tema_escuro';

  final SharedPreferences _prefs;
  bool _escuro;

  ThemeModeProvider(SharedPreferences prefs)
      : _prefs = prefs,
        _escuro = prefs.getBool(_temaEscuroKey) ?? false;

  ThemeMode get themeMode => _escuro ? ThemeMode.dark : ThemeMode.light;

  Future<void> alternar() async {
    _escuro = !_escuro;
    await _prefs.setBool(_temaEscuroKey, _escuro);
    notifyListeners();
  }
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/providers/theme_mode_provider_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Rodar análise estática**

Run: `flutter analyze lib/providers/theme_mode_provider.dart`
Expected: `No issues found!`

---

### Task 4: Wiring do tema em `main.dart`

**Files:**
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `appThemeLight`, `appThemeDark` (Task 1), `ThemeModeProvider` (Task 3).

- [ ] **Step 1: Atualizar `main.dart`**

Arquivo completo após a mudança:

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
import 'providers/theme_mode_provider.dart';
import 'providers/veiculo_provider.dart';
import 'repositories/veiculo_repository.dart';
import 'screens/login_screen.dart';
import 'screens/veiculo_list_screen.dart';
import 'theme/app_theme.dart';

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
        ChangeNotifierProvider(create: (_) => ThemeModeProvider(prefs)),
        Provider<SharedPreferences>.value(value: prefs),
        Provider<VeiculoRepository>(create: (_) => VeiculoRepository()),
      ],
      child: Consumer2<AppAuthProvider, ThemeModeProvider>(
        builder: (context, auth, themeModeProvider, _) {
          final user = auth.user;

          if (user == null) {
            return MaterialApp(
              title: 'RevisaCar',
              theme: appThemeLight,
              darkTheme: appThemeDark,
              themeMode: themeModeProvider.themeMode,
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
              theme: appThemeLight,
              darkTheme: appThemeDark,
              themeMode: themeModeProvider.themeMode,
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

- [ ] **Step 2: Rodar análise estática**

Run: `flutter analyze lib/main.dart`
Expected: `No issues found!`

- [ ] **Step 3: Rodar a suíte completa (regressão)**

Run: `flutter test`
Expected: `All tests passed!` (mesmo número de testes de antes — este arquivo não tem teste próprio).

---

### Task 5: Redesign da tela de Login

**Files:**
- Modify: `lib/screens/login_screen.dart`

**Interfaces:**
- Consumes: `kAccentColor`, tema (`Theme.of(context)`) (Task 1). `AppAuthProvider` (já existe, inalterado).

- [ ] **Step 1: Reescrever a tela**

Arquivo completo após a mudança:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _carregando = false;

  Future<void> _entrar() async {
    setState(() => _carregando = true);
    await context.read<AppAuthProvider>().signInWithGoogle();
    if (mounted) setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    final erro = context.watch<AppAuthProvider>().errorMessage;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colorScheme.primary.withValues(alpha: 0.85), colorScheme.primary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(Icons.build, size: 46, color: colorScheme.onPrimary),
              ),
              const SizedBox(height: 24),
              Text('RevisaCar', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 6),
              Text(
                'Manutenção do seu veículo sem complicação',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              if (erro != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 18, color: colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(child: Text(erro, style: TextStyle(color: colorScheme.error))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                onPressed: _carregando ? null : _entrar,
                icon: const Icon(Icons.login),
                label: Text(_carregando ? 'Entrando...' : 'Entrar com Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Rodar análise estática**

Run: `flutter analyze lib/screens/login_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Rodar a suíte completa (regressão)**

Run: `flutter test`
Expected: `All tests passed!`

---

### Task 6: Redesign do card e da lista de veículos

**Files:**
- Modify: `lib/widgets/veiculo_card.dart`
- Modify: `lib/screens/veiculo_list_screen.dart`

**Interfaces:**
- Consumes: `LembreteRepository.getAll`, `ManutencaoRepository.getAll` (já existem), `LembreteService.manutencaoMaisRecente/calcularProximaMeta/calcularStatus`, `StatusLembrete` (`lib/services/lembrete_service.dart`, já existem), tema/`kAccentColor` (Task 1).
- Produces: `VeiculoCard` ganha parâmetro opcional `resumoAlerta` (`({int vencidos, int alertas})?`).

- [ ] **Step 1: Reescrever `VeiculoCard`**

Arquivo completo após a mudança:

```dart
import 'package:flutter/material.dart';

import '../models/veiculo.dart';

class VeiculoCard extends StatelessWidget {
  final Veiculo veiculo;
  final VoidCallback onTap;
  final VoidCallback onExcluir;
  final ({int vencidos, int alertas})? resumoAlerta;

  const VeiculoCard({
    super.key,
    required this.veiculo,
    required this.onTap,
    required this.onExcluir,
    this.resumoAlerta,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMoto = veiculo.tipoVeiculo == TipoVeiculo.moto;
    final vencidos = resumoAlerta?.vencidos ?? 0;
    final alertas = resumoAlerta?.alertas ?? 0;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isMoto
                ? colorScheme.error.withValues(alpha: 0.12)
                : colorScheme.secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isMoto ? Icons.two_wheeler : Icons.directions_car,
            size: 30,
            color: isMoto ? colorScheme.error : colorScheme.primary,
          ),
        ),
        title: Text(veiculo.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${veiculo.modelo} · ${veiculo.ano}'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.speed, size: 12, color: colorScheme.primary),
                    const SizedBox(width: 2),
                    Text(
                      '${veiculo.kmAtual} km',
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                    ),
                  ],
                ),
                if (vencidos > 0 || alertas > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: vencidos > 0 ? colorScheme.error : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vencidos > 0
                          ? '$vencidos vencido${vencidos > 1 ? 's' : ''}'
                          : '$alertas alerta${alertas > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: onTap,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Excluir',
          onPressed: onExcluir,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Reescrever `VeiculoListScreen`**

Arquivo completo após a mudança:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/veiculo.dart';
import '../providers/veiculo_provider.dart';
import '../repositories/lembrete_repository.dart';
import '../repositories/manutencao_repository.dart';
import '../services/lembrete_service.dart';
import '../widgets/veiculo_card.dart';
import 'configuracoes_screen.dart';
import 'detalhe_veiculo_screen.dart';
import 'veiculo_form_screen.dart';

class VeiculoListScreen extends StatelessWidget {
  const VeiculoListScreen({super.key});

  Future<void> _confirmarExclusao(BuildContext context, String id, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir veículo'),
        content: Text(
          'Excluir "$nome" e todos os registros associados (manutenções, abastecimentos, '
          'lembretes, checklist)? Essa ação não pode ser desfeita.',
        ),
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

    if (confirmar == true && context.mounted) {
      try {
        await context.read<VeiculoProvider>().remover(id);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível excluir. Tente novamente.')),
          );
        }
      }
    }
  }

  Future<({int vencidos, int alertas})> _calcularResumoAlerta(String uid, Veiculo veiculo) async {
    final lembretes = await LembreteRepository().getAll(uid, veiculoId: veiculo.id);
    final manutencoes = await ManutencaoRepository().getAll(uid, veiculoId: veiculo.id);
    final hoje = DateTime.now();
    var vencidos = 0;
    var alertas = 0;
    for (final lembrete in lembretes.where((l) => l.ativo)) {
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
        kmAtual: veiculo.kmAtual,
        hoje: hoje,
      );
      if (status == StatusLembrete.vencido) vencidos++;
      if (status == StatusLembrete.alertaAntecipado) alertas++;
    }
    return (vencidos: vencidos, alertas: alertas);
  }

  @override
  Widget build(BuildContext context) {
    final veiculoProvider = context.watch<VeiculoProvider>();
    final veiculos = veiculoProvider.veiculos;
    final uid = veiculoProvider.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Meus veículos', style: Theme.of(context).textTheme.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConfiguracoesScreen()),
            ),
          ),
        ],
      ),
      body: veiculos.isEmpty
          ? const Center(
              child: Text(
                'Nenhum veículo cadastrado.\nToque em + para adicionar o primeiro.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: veiculos.length,
              itemBuilder: (context, index) {
                final veiculo = veiculos[index];
                return FutureBuilder<({int vencidos, int alertas})>(
                  key: ValueKey(veiculo.id),
                  future: _calcularResumoAlerta(uid, veiculo),
                  builder: (context, snapshot) {
                    return VeiculoCard(
                      veiculo: veiculo,
                      resumoAlerta: snapshot.data,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => DetalheVeiculoScreen(veiculo: veiculo)),
                      ),
                      onExcluir: () => _confirmarExclusao(context, veiculo.id, veiculo.nome),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VeiculoFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

- [ ] **Step 3: Rodar análise estática**

Run: `flutter analyze lib/widgets/veiculo_card.dart lib/screens/veiculo_list_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: Rodar a suíte completa (regressão)**

Run: `flutter test`
Expected: `All tests passed!`

---

### Task 7: Redesign da tela de Detalhe do Veículo

**Files:**
- Modify: `lib/screens/detalhe_veiculo_screen.dart`

**Interfaces:**
- Consumes: `LembreteService`, `StatusLembrete` (para contagem de vencidos/alertas no card hero), tema (Task 1).

- [ ] **Step 1: Reescrever a tela**

Arquivo completo após a mudança:

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
import '../services/lembrete_service.dart';
import '../widgets/abastecimento_tab.dart';
import '../widgets/lembrete_tab.dart';
import '../widgets/manutencao_tab.dart';
import 'veiculo_form_screen.dart';

class DetalheVeiculoScreen extends StatefulWidget {
  final Veiculo veiculo;

  const DetalheVeiculoScreen({super.key, required this.veiculo});

  @override
  State<DetalheVeiculoScreen> createState() => _DetalheVeiculoScreenState();
}

class _DetalheVeiculoScreenState extends State<DetalheVeiculoScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final veiculoProvider = context.watch<VeiculoProvider>();
    final veiculoAtual = veiculoProvider.veiculos.firstWhere(
      (v) => v.id == widget.veiculo.id,
      orElse: () => widget.veiculo,
    );
    final uid = veiculoProvider.uid;
    final colorScheme = Theme.of(context).colorScheme;

    return MultiProvider(
      key: ValueKey(widget.veiculo.id),
      providers: [
        ChangeNotifierProvider<ManutencaoProvider>(
          create: (context) => ManutencaoProvider(
            repository: ManutencaoRepository(),
            veiculoRepository: context.read<VeiculoRepository>(),
            lembreteRepository: LembreteRepository(),
            uid: uid,
          )..escutarVeiculo(widget.veiculo.id),
        ),
        ChangeNotifierProvider<AbastecimentoProvider>(
          create: (context) => AbastecimentoProvider(
            repository: AbastecimentoRepository(),
            veiculoRepository: context.read<VeiculoRepository>(),
            uid: uid,
          )..escutarVeiculo(widget.veiculo.id),
        ),
        ChangeNotifierProvider<LembreteProvider>(
          create: (context) => LembreteProvider(
            repository: LembreteRepository(),
            uid: uid,
          )..escutarVeiculo(widget.veiculo.id),
        ),
      ],
      child: Builder(builder: (context) {
        final manutencoes = context.watch<ManutencaoProvider>().manutencoes;
        final lembretes = context.watch<LembreteProvider>().lembretes.where((l) => l.ativo);
        final hoje = DateTime.now();
        var vencidos = 0;
        var alertas = 0;
        for (final lembrete in lembretes) {
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
            kmAtual: veiculoAtual.kmAtual,
            hoje: hoje,
          );
          if (status == StatusLembrete.vencido) vencidos++;
          if (status == StatusLembrete.alertaAntecipado) alertas++;
        }
        final isMoto = veiculoAtual.tipoVeiculo == TipoVeiculo.moto;
        final corGradiente = isMoto ? colorScheme.error : colorScheme.primary;

        return Scaffold(
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
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [corGradiente.withValues(alpha: 0.85), corGradiente],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isMoto ? Icons.two_wheeler : Icons.directions_car,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              veiculoAtual.modelo,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                            Text(
                              '${veiculoAtual.ano} · ${veiculoAtual.placa}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _PillHero(
                                  icon: Icons.speed,
                                  texto: '${veiculoAtual.kmAtual} km',
                                ),
                                if (vencidos > 0)
                                  _PillHero(
                                    icon: Icons.warning_amber,
                                    texto: '$vencidos vencido${vencidos > 1 ? 's' : ''}',
                                    fundo: Colors.red.withValues(alpha: 0.3),
                                  ),
                                if (alertas > 0)
                                  _PillHero(
                                    icon: Icons.warning_amber,
                                    texto: '$alertas em alerta',
                                    fundo: Colors.orange.withValues(alpha: 0.3),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    ManutencaoTab(kmAtual: veiculoAtual.kmAtual),
                    const AbastecimentoTab(),
                    LembreteTab(kmAtual: veiculoAtual.kmAtual),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.build), label: 'Manutenções'),
              NavigationDestination(icon: Icon(Icons.local_gas_station), label: 'Abastecimentos'),
              NavigationDestination(icon: Icon(Icons.notifications), label: 'Lembretes'),
            ],
          ),
        );
      }),
    );
  }
}

class _PillHero extends StatelessWidget {
  final IconData icon;
  final String texto;
  final Color? fundo;

  const _PillHero({required this.icon, required this.texto, this.fundo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fundo ?? Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            texto,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Rodar análise estática**

Run: `flutter analyze lib/screens/detalhe_veiculo_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Rodar a suíte completa (regressão)**

Run: `flutter test`
Expected: `All tests passed!`

---

### Task 8: Redesign da aba Manutenções

**Files:**
- Modify: `lib/widgets/manutencao_tab.dart`

**Interfaces:**
- Consumes: `TipoManutencaoVisual` (Task 2), cores de status (Task 1).
- Produces: `ManutencaoTab` ganha parâmetro obrigatório `kmAtual` (necessário para calcular o status real de cada lembrete no bloco "Próximas manutenções"). O único ponto de chamada (`detalhe_veiculo_screen.dart`) já foi atualizado na Task 7 para passar `kmAtual: veiculoAtual.kmAtual`.

- [ ] **Step 1: Reescrever o arquivo**

Arquivo completo após a mudança:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lembrete_manutencao.dart';
import '../models/manutencao.dart';
import '../providers/lembrete_provider.dart';
import '../providers/manutencao_provider.dart';
import '../screens/manutencao_form_screen.dart';
import '../services/lembrete_service.dart';
import '../theme/app_theme.dart';
import '../utils/tipo_manutencao_labels.dart';
import '../utils/tipo_manutencao_visual.dart';
import 'confirmar_exclusao_dialog.dart';

class ManutencaoTab extends StatelessWidget {
  final int kmAtual;

  const ManutencaoTab({super.key, required this.kmAtual});

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

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  Color _corTextoStatus(StatusLembrete status) {
    switch (status) {
      case StatusLembrete.emDia:
        return kStatusEmDiaTexto;
      case StatusLembrete.alertaAntecipado:
        return kStatusAlertaTexto;
      case StatusLembrete.vencido:
        return kStatusVencidoTexto;
    }
  }

  Color _corFundoStatus(StatusLembrete status) {
    switch (status) {
      case StatusLembrete.emDia:
        return kStatusEmDiaFundo;
      case StatusLembrete.alertaAntecipado:
        return kStatusAlertaFundo;
      case StatusLembrete.vencido:
        return kStatusVencidoFundo;
    }
  }

  Widget _proximasManutencoes(List<Manutencao> manutencoes, List<LembreteManutencao> lembretes) {
    final lembretesAtivos = lembretes.where((l) => l.ativo).toList();
    if (lembretesAtivos.isEmpty) return const SizedBox.shrink();
    final hoje = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRÓXIMAS MANUTENÇÕES',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: lembretesAtivos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final lembrete = lembretesAtivos[index];
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
                final corTexto = _corTextoStatus(status);
                final corFundo = _corFundoStatus(status);
                final partes = <String>[
                  if (meta.metaKm != null) '${meta.metaKm} km',
                  if (meta.metaData != null) _formatarData(meta.metaData!),
                ];
                return Container(
                  width: 138,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: corFundo,
                    borderRadius: BorderRadius.circular(kCardRadius),
                    border: Border(left: BorderSide(color: corTexto, width: 3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(lembrete.tipoManutencao.icon, size: 16, color: lembrete.tipoManutencao.cor),
                      const SizedBox(height: 6),
                      Text(
                        lembrete.tipoManutencao.label,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        partes.join(' ou '),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: corTexto),
                        maxLines: 2,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manutencoes = context.watch<ManutencaoProvider>().manutencoes.toList()
      ..sort((a, b) => b.dataRealizada.compareTo(a.dataRealizada));
    final lembretes = context.watch<LembreteProvider>().lembretes;
    final provider = context.read<ManutencaoProvider>();

    return Scaffold(
      body: Column(
        children: [
          _proximasManutencoes(manutencoes, lembretes),
          Expanded(
            child: manutencoes.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhuma manutenção registrada.\nToque em + para adicionar a primeira.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
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
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: manutencao.tipo.cor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(manutencao.tipo.icon, size: 18, color: manutencao.tipo.cor),
                            ),
                            title: Text(manutencao.tipo.label),
                            subtitle: Text(
                              '${manutencao.oficina} • ${manutencao.kmNaData} km • '
                              'R\$ ${manutencao.custo.toStringAsFixed(2)}',
                            ),
                            onTap: () {
                              final manutencaoProvider = context.read<ManutencaoProvider>();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider.value(
                                    value: manutencaoProvider,
                                    child: ManutencaoFormScreen(manutencao: manutencao),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_manutencao',
        onPressed: () {
          final manutencaoProvider = context.read<ManutencaoProvider>();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: manutencaoProvider,
                child: const ManutencaoFormScreen(),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

- [ ] **Step 2: Rodar análise estática**

Run: `flutter analyze lib/widgets/manutencao_tab.dart`
Expected: `No issues found!`

- [ ] **Step 3: Rodar a suíte completa (regressão)**

Run: `flutter test`
Expected: `All tests passed!`

---

### Task 9: Redesign da aba Abastecimentos

**Files:**
- Modify: `lib/widgets/abastecimento_tab.dart`

**Interfaces:**
- Consumes: tema (Task 1).

- [ ] **Step 1: Reescrever o arquivo**

Arquivo completo após a mudança:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/abastecimento.dart';
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

  Widget _resumo(BuildContext context, List<Abastecimento> abastecimentos) {
    if (abastecimentos.isEmpty) return const SizedBox.shrink();
    final totalValor = abastecimentos.fold<double>(0, (s, a) => s + a.valorTotal);
    final totalLitros = abastecimentos.fold<double>(0, (s, a) => s + a.litros);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _CardEstatistica(rotulo: 'Total gasto', valor: 'R\$ ${totalValor.toStringAsFixed(2)}')),
          const SizedBox(width: 8),
          Expanded(child: _CardEstatistica(rotulo: 'Total abastecido', valor: '${totalLitros.toStringAsFixed(0)} L')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final abastecimentos = context.watch<AbastecimentoProvider>().abastecimentos.toList()
      ..sort((a, b) => b.data.compareTo(a.data));
    final provider = context.read<AbastecimentoProvider>();

    return Scaffold(
      body: Column(
        children: [
          _resumo(context, abastecimentos),
          Expanded(
            child: abastecimentos.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum abastecimento registrado.\nToque em + para adicionar o primeiro.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.local_gas_station,
                                  size: 18, color: Theme.of(context).colorScheme.primary),
                            ),
                            title: Text(_formatarData(abastecimento.data)),
                            subtitle: Text(
                              '${abastecimento.litros.toStringAsFixed(1)} L • '
                              'R\$ ${abastecimento.valorTotal.toStringAsFixed(2)} • '
                              '${abastecimento.kmAtual} km'
                              '${abastecimento.tanqueCheio ? ' • Tanque cheio' : ''}',
                            ),
                            onTap: () {
                              final abastecimentoProvider = context.read<AbastecimentoProvider>();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider.value(
                                    value: abastecimentoProvider,
                                    child: AbastecimentoFormScreen(abastecimento: abastecimento),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_abastecimento',
        onPressed: () {
          final abastecimentoProvider = context.read<AbastecimentoProvider>();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: abastecimentoProvider,
                child: const AbastecimentoFormScreen(),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CardEstatistica extends StatelessWidget {
  final String rotulo;
  final String valor;

  const _CardEstatistica({required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rotulo.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(valor, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Rodar análise estática**

Run: `flutter analyze lib/widgets/abastecimento_tab.dart`
Expected: `No issues found!`

- [ ] **Step 3: Rodar a suíte completa (regressão)**

Run: `flutter test`
Expected: `All tests passed!`

---

### Task 10: Redesign da aba Lembretes

**Files:**
- Modify: `lib/widgets/lembrete_tab.dart`

**Interfaces:**
- Consumes: `TipoManutencaoVisual` (Task 2), cores de status (Task 1).

- [ ] **Step 1: Reescrever o arquivo**

Arquivo completo após a mudança:

```dart
// lib/widgets/lembrete_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/lembrete_provider.dart';
import '../providers/manutencao_provider.dart';
import '../screens/lembrete_form_screen.dart';
import '../screens/manutencao_form_screen.dart';
import '../services/lembrete_service.dart';
import '../theme/app_theme.dart';
import '../utils/tipo_manutencao_labels.dart';
import '../utils/tipo_manutencao_visual.dart';
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

  Color _corTextoStatus(StatusLembrete status) {
    switch (status) {
      case StatusLembrete.emDia:
        return kStatusEmDiaTexto;
      case StatusLembrete.alertaAntecipado:
        return kStatusAlertaTexto;
      case StatusLembrete.vencido:
        return kStatusVencidoTexto;
    }
  }

  Color _corFundoStatus(StatusLembrete status) {
    switch (status) {
      case StatusLembrete.emDia:
        return kStatusEmDiaFundo;
      case StatusLembrete.alertaAntecipado:
        return kStatusAlertaFundo;
      case StatusLembrete.vencido:
        return kStatusVencidoFundo;
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
              padding: const EdgeInsets.all(16),
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
                final corTexto = _corTextoStatus(status);
                final corFundo = _corFundoStatus(status);

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
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(kCardRadius),
                      border: Border(left: BorderSide(color: corTexto, width: 4)),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: lembrete.tipoManutencao.cor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(lembrete.tipoManutencao.icon,
                                    size: 16, color: lembrete.tipoManutencao.cor),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(lembrete.tipoManutencao.label,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: corFundo,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _rotuloStatus(status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: corTexto,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (meta.metaKm != null)
                            Text('Próxima: ${meta.metaKm} km', style: const TextStyle(fontSize: 12)),
                          if (meta.metaData != null)
                            Text(
                              'Prazo: ${meta.metaData!.day.toString().padLeft(2, '0')}/'
                              '${meta.metaData!.month.toString().padLeft(2, '0')}/${meta.metaData!.year}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              final lembreteProvider = context.read<LembreteProvider>();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider.value(
                                    value: lembreteProvider,
                                    child: LembreteFormScreen(lembrete: lembrete),
                                  ),
                                ),
                              );
                            },
                            child: const Text('Editar regra', style: TextStyle(fontSize: 12, decoration: TextDecoration.underline)),
                          ),
                          if (status != StatusLembrete.emDia) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonalIcon(
                                style: FilledButton.styleFrom(backgroundColor: corFundo, foregroundColor: corTexto),
                                onPressed: () {
                                  final manutencaoProvider = context.read<ManutencaoProvider>();
                                  final lembreteProvider = context.read<LembreteProvider>();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => MultiProvider(
                                        providers: [
                                          ChangeNotifierProvider.value(value: manutencaoProvider),
                                          ChangeNotifierProvider.value(value: lembreteProvider),
                                        ],
                                        child: ManutencaoFormScreen(
                                          tipoInicial: lembrete.tipoManutencao,
                                          lembreteParaResolver: lembrete,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Marcar como resolvido'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_lembrete',
        onPressed: () {
          final lembreteProvider = context.read<LembreteProvider>();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: lembreteProvider,
                child: const LembreteFormScreen(),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

**Nota:** o comportamento de tocar no item inteiro para editar (existente antes) vira um link explícito "Editar regra", já que o card agora tem um botão de ação ("Marcar como resolvido") ocupando a área inferior — evita conflito de toque entre "editar" e "resolver".

- [ ] **Step 2: Rodar análise estática**

Run: `flutter analyze lib/widgets/lembrete_tab.dart`
Expected: `No issues found!`

- [ ] **Step 3: Rodar a suíte completa (regressão)**

Run: `flutter test`
Expected: `All tests passed!`

---

### Task 11: Redesign do formulário de Manutenção

**Files:**
- Modify: `lib/screens/manutencao_form_screen.dart`

**Interfaces:**
- Consumes: `TipoManutencaoVisual` (Task 2).

- [ ] **Step 1: Reescrever o arquivo**

Arquivo completo após a mudança:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lembrete_manutencao.dart';
import '../models/manutencao.dart';
import '../providers/lembrete_provider.dart';
import '../providers/manutencao_provider.dart';
import '../utils/tipo_manutencao_labels.dart';
import '../utils/tipo_manutencao_visual.dart';

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
    if (!mounted) return;
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _dataRealizada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selecionada != null && mounted) {
      setState(() => _dataRealizada = selecionada);
    }
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  Widget _rotulo(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          texto.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey.shade600),
        ),
      );

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
      if (lembrete != null && mounted) {
        final lembreteProvider = context.read<LembreteProvider>();
        await lembreteProvider.atualizar(lembrete.copyWith(resolvidoEm: DateTime.now()));
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
            _rotulo('Tipo'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.6,
              children: TipoManutencao.values.map((tipo) {
                final selecionado = tipo == _tipo;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _tipo = tipo),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selecionado ? tipo.cor : Colors.grey.shade300,
                        width: selecionado ? 2 : 1,
                      ),
                      color: selecionado ? tipo.cor.withValues(alpha: 0.08) : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: tipo.cor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(tipo.icon, size: 16, color: tipo.cor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tipo.label,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_tipo == TipoManutencao.outro) ...[
              const SizedBox(height: 16),
              _rotulo('Descrição'),
              TextFormField(
                controller: _descricaoOutroController,
                validator: _descricaoOutroValidator,
              ),
            ],
            const SizedBox(height: 16),
            _rotulo('Data realizada'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_formatarData(_dataRealizada)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selecionarData,
            ),
            const SizedBox(height: 12),
            _rotulo('Km na data'),
            TextFormField(
              controller: _kmNaDataController,
              keyboardType: TextInputType.number,
              validator: _inteiroObrigatorio,
            ),
            const SizedBox(height: 12),
            _rotulo('Custo (R\$)'),
            TextFormField(
              controller: _custoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _decimalObrigatorio,
            ),
            const SizedBox(height: 12),
            _rotulo('Oficina'),
            TextFormField(
              controller: _oficinaController,
              validator: _obrigatorio,
            ),
            const SizedBox(height: 12),
            _rotulo('Observações'),
            TextFormField(
              controller: _observacoesController,
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

- [ ] **Step 2: Rodar análise estática**

Run: `flutter analyze lib/screens/manutencao_form_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Rodar a suíte completa (regressão)**

Run: `flutter test`
Expected: `All tests passed!`

---

### Task 12: Redesign do formulário de Abastecimento

**Files:**
- Modify: `lib/screens/abastecimento_form_screen.dart`

- [ ] **Step 1: Reescrever o arquivo**

Arquivo completo após a mudança:

```dart
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

  Widget _rotulo(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          texto.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey.shade600),
        ),
      );

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
    final litros = double.tryParse(_litrosController.text.replaceAll(',', '.'));
    final valorTotal = double.tryParse(_valorTotalController.text.replaceAll(',', '.'));

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar abastecimento' : 'Novo abastecimento')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _rotulo('Data'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_formatarData(_data)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selecionarData,
            ),
            const SizedBox(height: 12),
            _rotulo('Km atual'),
            TextFormField(
              controller: _kmAtualController,
              keyboardType: TextInputType.number,
              validator: _inteiroObrigatorio,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _rotulo('Litros'),
            TextFormField(
              controller: _litrosController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _decimalObrigatorio,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _rotulo('Valor total (R\$)'),
            TextFormField(
              controller: _valorTotalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _decimalObrigatorio,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tanque cheio'),
              value: _tanqueCheio,
              onChanged: (valor) => setState(() => _tanqueCheio = valor),
            ),
            if (litros != null && valorTotal != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_gas_station, size: 16, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Preço por litro', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Text(
                      'R\$ ${(valorTotal / litros).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
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

- [ ] **Step 2: Rodar análise estática**

Run: `flutter analyze lib/screens/abastecimento_form_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Rodar a suíte completa (regressão)**

Run: `flutter test`
Expected: `All tests passed!`

---

### Task 13: Redesign do formulário de Lembrete

**Files:**
- Modify: `lib/screens/lembrete_form_screen.dart`

**Interfaces:**
- Consumes: `TipoManutencaoVisual` (Task 2).

- [ ] **Step 1: Reescrever o arquivo**

Arquivo completo após a mudança:

```dart
// lib/screens/lembrete_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lembrete_manutencao.dart';
import '../models/manutencao.dart';
import '../providers/lembrete_provider.dart';
import '../utils/tipo_manutencao_labels.dart';
import '../utils/tipo_manutencao_visual.dart';

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

  Widget _rotulo(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          texto.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey.shade600),
        ),
      );

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
            _rotulo('Tipo de manutenção'),
            DropdownButtonFormField<TipoManutencao>(
              initialValue: _tipoManutencao,
              items: TipoManutencao.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.icon, size: 16, color: t.cor),
                            const SizedBox(width: 8),
                            Text(t.label),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (valor) =>
                  setState(() => _tipoManutencao = valor ?? TipoManutencao.revisao),
            ),
            const SizedBox(height: 12),
            _rotulo('Intervalo (km)'),
            TextFormField(
              controller: _intervaloKmController,
              keyboardType: TextInputType.number,
              validator: _validarIntervaloKm,
            ),
            const SizedBox(height: 12),
            _rotulo('Intervalo (dias)'),
            TextFormField(
              controller: _intervaloDiasController,
              keyboardType: TextInputType.number,
              validator: _validarIntervaloDias,
            ),
            const SizedBox(height: 12),
            _rotulo('Antecedência (km)'),
            TextFormField(
              controller: _antecedenciaKmController,
              keyboardType: TextInputType.number,
              validator: _inteiroOpcional,
            ),
            const SizedBox(height: 12),
            _rotulo('Antecedência (dias)'),
            TextFormField(
              controller: _antecedenciaDiasController,
              keyboardType: TextInputType.number,
              validator: _inteiroOpcional,
            ),
            const SizedBox(height: 12),
            _rotulo('Repetir notificação a cada (dias)'),
            TextFormField(
              controller: _intervaloRepeticaoDiasController,
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

- [ ] **Step 2: Rodar análise estática**

Run: `flutter analyze lib/screens/lembrete_form_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Rodar a suíte completa (regressão)**

Run: `flutter test`
Expected: `All tests passed!`

---

### Task 14: Redesign do formulário de Veículo (acordeão de intervalos)

**Files:**
- Modify: `lib/screens/veiculo_form_screen.dart`

**Interfaces:**
- Consumes: `intervaloEfetivo`, `intervalosPadraoManutencao` (`lib/utils/intervalo_padrao_manutencao.dart`, já existem), `TipoManutencaoVisual` (Task 2).

- [ ] **Step 1: Reescrever o arquivo**

Arquivo completo após a mudança:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/intervalo_manutencao.dart';
import '../models/manutencao.dart';
import '../models/veiculo.dart';
import '../providers/veiculo_provider.dart';
import '../utils/intervalo_padrao_manutencao.dart';
import '../utils/tipo_manutencao_labels.dart';
import '../utils/tipo_manutencao_visual.dart';

final _tiposComIntervalo =
    TipoManutencao.values.where((t) => t != TipoManutencao.outro).toList();

class VeiculoFormScreen extends StatefulWidget {
  final Veiculo? veiculo;

  const VeiculoFormScreen({super.key, this.veiculo});

  @override
  State<VeiculoFormScreen> createState() => _VeiculoFormScreenState();
}

class _VeiculoFormScreenState extends State<VeiculoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _modeloController;
  late final TextEditingController _anoController;
  late final TextEditingController _placaController;
  late final TextEditingController _kmAtualController;
  late TipoVeiculo _tipoVeiculo;
  late final Map<TipoManutencao, TextEditingController> _intervaloKmControllers;
  late final Map<TipoManutencao, TextEditingController> _intervaloMesesControllers;
  bool _salvando = false;

  bool get _editando => widget.veiculo != null;

  @override
  void initState() {
    super.initState();
    final v = widget.veiculo;
    _nomeController = TextEditingController(text: v?.nome ?? '');
    _modeloController = TextEditingController(text: v?.modelo ?? '');
    _anoController = TextEditingController(text: v?.ano.toString() ?? '');
    _placaController = TextEditingController(text: v?.placa ?? '');
    _kmAtualController = TextEditingController(text: v?.kmAtual.toString() ?? '');
    _tipoVeiculo = v?.tipoVeiculo ?? TipoVeiculo.carro;

    _intervaloKmControllers = {};
    _intervaloMesesControllers = {};
    for (final tipo in _tiposComIntervalo) {
      final efetivo = v != null ? intervaloEfetivo(v, tipo) : intervalosPadraoManutencao[tipo];
      _intervaloKmControllers[tipo] = TextEditingController(text: efetivo?.km?.toString() ?? '');
      final meses = efetivo?.dias == null ? null : (efetivo!.dias! ~/ 30);
      _intervaloMesesControllers[tipo] = TextEditingController(text: meses?.toString() ?? '');
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _modeloController.dispose();
    _anoController.dispose();
    _placaController.dispose();
    _kmAtualController.dispose();
    for (final controller in _intervaloKmControllers.values) {
      controller.dispose();
    }
    for (final controller in _intervaloMesesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  String? _numeroObrigatorio(String? valor) {
    final erroObrigatorio = _obrigatorio(valor);
    if (erroObrigatorio != null) return erroObrigatorio;
    if (int.tryParse(valor!.trim()) == null) return 'Informe um número válido';
    return null;
  }

  String? _inteiroOpcional(String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;
    if (int.tryParse(valor.trim()) == null) return 'Informe um número válido';
    return null;
  }

  Widget _rotulo(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          texto.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey.shade600),
        ),
      );

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    final intervalosPersonalizados = <TipoManutencao, IntervaloManutencao>{
      for (final tipo in _tiposComIntervalo)
        tipo: IntervaloManutencao(
          km: _intervaloKmControllers[tipo]!.text.trim().isEmpty
              ? null
              : int.parse(_intervaloKmControllers[tipo]!.text.trim()),
          dias: _intervaloMesesControllers[tipo]!.text.trim().isEmpty
              ? null
              : int.parse(_intervaloMesesControllers[tipo]!.text.trim()) * 30,
        ),
    };
    final veiculo = Veiculo(
      id: widget.veiculo?.id ?? '',
      nome: _nomeController.text.trim(),
      modelo: _modeloController.text.trim(),
      ano: int.parse(_anoController.text.trim()),
      placa: _placaController.text.trim(),
      kmAtual: int.parse(_kmAtualController.text.trim()),
      tipoVeiculo: _tipoVeiculo,
      fotoUrl: widget.veiculo?.fotoUrl,
      intervalosPersonalizados: intervalosPersonalizados,
    );

    try {
      final provider = context.read<VeiculoProvider>();
      if (_editando) {
        await provider.atualizar(veiculo.id, veiculo);
      } else {
        await provider.adicionar(veiculo);
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

  String _resumoIntervalo(TipoManutencao tipo) {
    final km = _intervaloKmControllers[tipo]!.text.trim();
    final meses = _intervaloMesesControllers[tipo]!.text.trim();
    final partes = <String>[
      if (km.isNotEmpty) '$km km',
      if (meses.isNotEmpty) '$meses meses',
    ];
    return partes.isEmpty ? 'Não configurado' : partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar veículo' : 'Novo veículo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _rotulo('Nome'),
            TextFormField(controller: _nomeController, validator: _obrigatorio),
            const SizedBox(height: 12),
            _rotulo('Modelo'),
            TextFormField(controller: _modeloController, validator: _obrigatorio),
            const SizedBox(height: 12),
            _rotulo('Ano'),
            TextFormField(
              controller: _anoController,
              keyboardType: TextInputType.number,
              validator: _numeroObrigatorio,
            ),
            const SizedBox(height: 12),
            _rotulo('Placa'),
            TextFormField(controller: _placaController, validator: _obrigatorio),
            const SizedBox(height: 12),
            _rotulo('Km atual'),
            TextFormField(
              controller: _kmAtualController,
              keyboardType: TextInputType.number,
              validator: _numeroObrigatorio,
            ),
            const SizedBox(height: 12),
            _rotulo('Tipo de veículo'),
            Row(
              children: [
                Expanded(
                  child: _BotaoTipoVeiculo(
                    selecionado: _tipoVeiculo == TipoVeiculo.carro,
                    icone: Icons.directions_car,
                    rotulo: 'Carro',
                    onTap: () => setState(() => _tipoVeiculo = TipoVeiculo.carro),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BotaoTipoVeiculo(
                    selecionado: _tipoVeiculo == TipoVeiculo.moto,
                    icone: Icons.two_wheeler,
                    rotulo: 'Moto',
                    onTap: () => setState(() => _tipoVeiculo = TipoVeiculo.moto),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _rotulo('Intervalos de manutenção'),
            Text(
              'Usado para criar lembretes automáticos.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            for (final tipo in _tiposComIntervalo)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tipo.cor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tipo.icon, size: 18, color: tipo.cor),
                  ),
                  title: Text(tipo.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    _resumoIntervalo(tipo),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _intervaloKmControllers[tipo],
                              decoration: const InputDecoration(labelText: 'Km'),
                              keyboardType: TextInputType.number,
                              validator: _inteiroOpcional,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _intervaloMesesControllers[tipo],
                              decoration: const InputDecoration(labelText: 'Meses'),
                              keyboardType: TextInputType.number,
                              validator: _inteiroOpcional,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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

class _BotaoTipoVeiculo extends StatelessWidget {
  final bool selecionado;
  final IconData icone;
  final String rotulo;
  final VoidCallback onTap;

  const _BotaoTipoVeiculo({
    required this.selecionado,
    required this.icone,
    required this.rotulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selecionado ? colorScheme.primary : Colors.grey.shade300, width: selecionado ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 20, color: selecionado ? colorScheme.primary : Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              rotulo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selecionado ? colorScheme.primary : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Rodar análise estática**

Run: `flutter analyze lib/screens/veiculo_form_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Rodar a suíte completa (regressão)**

Run: `flutter test`
Expected: `All tests passed!`

---

### Task 15: Redesign da tela de Configurações

**Files:**
- Modify: `lib/screens/configuracoes_screen.dart`

**Interfaces:**
- Consumes: `ThemeModeProvider` (Task 3), `VeiculoRepository.getAll` (indireto via `VeiculoProvider.veiculos`), `ManutencaoRepository.getAll`, `AbastecimentoRepository.getAll` (já existem, usados aqui via `FutureBuilder` para contagem total entre todos os veículos).

- [ ] **Step 1: Reescrever o arquivo**

Arquivo completo após a mudança:

```dart
// lib/screens/configuracoes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/veiculo.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../providers/veiculo_provider.dart';
import '../repositories/abastecimento_repository.dart';
import '../repositories/manutencao_repository.dart';

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  Future<void> _sair(BuildContext context) async {
    await context.read<AppAuthProvider>().signOut();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<({int manutencoes, int abastecimentos})> _contarRegistros(
    String uid,
    List<Veiculo> veiculos,
  ) async {
    var manutencoes = 0;
    var abastecimentos = 0;
    for (final veiculo in veiculos) {
      final listaManutencoes = await ManutencaoRepository().getAll(uid, veiculoId: veiculo.id);
      final listaAbastecimentos =
          await AbastecimentoRepository().getAll(uid, veiculoId: veiculo.id);
      manutencoes += listaManutencoes.length;
      abastecimentos += listaAbastecimentos.length;
    }
    return (manutencoes: manutencoes, abastecimentos: abastecimentos);
  }

  Widget _secao(BuildContext context, String titulo, Widget conteudo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Card(child: conteudo),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().user;
    final themeModeProvider = context.watch<ThemeModeProvider>();
    final veiculoProvider = context.watch<VeiculoProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.secondary,
                    child: Icon(Icons.person, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.displayName ?? 'Usuário',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(user?.email ?? '', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _secao(
            context,
            'Aparência',
            SwitchListTile(
              secondary: Icon(themeModeProvider.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
              title: const Text('Tema escuro'),
              value: themeModeProvider.themeMode == ThemeMode.dark,
              onChanged: (_) => themeModeProvider.alternar(),
            ),
          ),
          const SizedBox(height: 20),
          _secao(
            context,
            'Seus dados',
            Column(
              children: [
                ListTile(
                  title: const Text('Veículos cadastrados'),
                  trailing: Text('${veiculoProvider.veiculos.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                FutureBuilder<({int manutencoes, int abastecimentos})>(
                  future: _contarRegistros(veiculoProvider.uid, veiculoProvider.veiculos),
                  builder: (context, snapshot) {
                    final manutencoes = snapshot.data?.manutencoes;
                    final abastecimentos = snapshot.data?.abastecimentos;
                    return Column(
                      children: [
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Manutenções registradas'),
                          trailing: Text('${manutencoes ?? '—'}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Abastecimentos registrados'),
                          trailing: Text('${abastecimentos ?? '—'}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error.withValues(alpha: 0.1),
                foregroundColor: colorScheme.error,
              ),
              onPressed: () => _sair(context),
              icon: const Icon(Icons.logout),
              label: const Text('Sair da conta'),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Rodar análise estática**

Run: `flutter analyze lib/screens/configuracoes_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Rodar a suíte completa (regressão)**

Run: `flutter test`
Expected: `All tests passed!`

- [ ] **Step 4: Verificação manual final**

Rodar `flutter run` e navegar por todas as telas: login, lista de veículos (conferir badge de alerta), detalhe do veículo (card hero, navegação inferior), as 3 abas, todos os formulários (incluindo o acordeão de intervalos), e Configurações (alternar o tema escuro e confirmar que o app inteiro muda de paleta, inclusive depois de fechar e reabrir).

---

## Self-Review

**1. Cobertura do spec:** tema claro/escuro com tokens exatos (Task 1), catálogo ícone/cor (Task 2), toggle de tema persistido (Task 3, 4, 15), todas as telas redesenhadas (Tasks 5-15) incluindo o acordeão de intervalos (Task 14) e o badge de alerta na lista de veículos (Task 6). Nenhuma mudança de modelo/provider de dados além do novo `ThemeModeProvider` (puramente de UI) — consistente com o escopo do spec.

**2. Placeholders:** nenhum "TBD"/"TODO"; todo código está completo.

**3. Consistência de tipos:** `TipoManutencaoVisual.icon`/`.cor` (Task 2) usados com a mesma assinatura em Tasks 6, 7, 8, 10, 11, 13, 14. `ThemeModeProvider.themeMode`/`.alternar()` (Task 3) usados com a mesma assinatura em Tasks 4 e 15. Registro `({int vencidos, int alertas})` (Task 6) e `({int manutencoes, int abastecimentos})` (Task 15) são registros locais a cada arquivo, sem necessidade de tipo compartilhado.
