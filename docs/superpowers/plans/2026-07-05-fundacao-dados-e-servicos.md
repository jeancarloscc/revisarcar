# Fundação: Dados e Serviços — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir a camada de dados e lógica de negócio do app de manutenção veicular — models, `ConsumoService`, `LembreteService`, `ExportService`, repositórios Firestore e providers — tudo testável via testes unitários, sem nenhuma tela ainda.

**Architecture:** Camadas independentes: `models/` (Dart puro, sem dependência de Firebase) → `services/` (Dart puro, operam sobre listas de models já carregados) → `repositories/` (ponte com Cloud Firestore, testados com `fake_cloud_firestore`) → `providers/` (`ChangeNotifier` que expõem streams dos repositórios ao resto do app, testados com os repositórios reais + Firestore fake). Este plano não cria nenhuma tela; é a base sobre a qual o Plano 2 (UI) será construído.

**Tech Stack:** Flutter/Dart, `provider`, `cloud_firestore`, `firebase_auth` + `google_sign_in`, `fake_cloud_firestore` e `firebase_auth_mocks` (dev, para testes sem projeto Firebase real).

## Global Constraints

- Plataformas: apenas Android e iOS — os diretórios `linux/`, `macos/`, `windows/`, `web/` do scaffold serão removidos (Task 2).
- Fonte de dados única: **Cloud Firestore**, com persistência offline nativa habilitada — não usar `sqflite` nem qualquer outra camada de sincronização manual.
- Isolamento por conta: toda coleção vive sob `users/{uid}/...` (ver spec, "Estrutura de dados no Firestore").
- SDK: Flutter `^3.12.2` (já configurado em `pubspec.yaml`).
- **Nenhuma tarefa deste plano deve executar comandos git** (`init`, `add`, `commit`, etc.) — instrução explícita do usuário. Cada tarefa termina depois que os testes passam; não há passo de commit.
- Este plano cobre só lógica e dados — sem telas, sem testes de widget/integração (isso fica para o Plano 2).
- Nomes de campos e classes em português, consistentes com o modelo de dados da spec (`docs/superpowers/specs/2026-07-05-app-manutencao-veicular-design.md`).

---

### Task 1: Dependências do projeto

**Files:**
- Modify: `pubspec.yaml`

**Interfaces:**
- Produces: todos os pacotes usados pelas tasks seguintes (`provider`, `cloud_firestore`, `firebase_auth`, `google_sign_in`, `firebase_core`, `shared_preferences`; dev: `fake_cloud_firestore`, `firebase_auth_mocks`).

- [ ] **Step 1: Adicionar dependências de produção**

Run:
```bash
flutter pub add provider cloud_firestore firebase_auth google_sign_in firebase_core shared_preferences
```
Expected: comando termina sem erro e `pubspec.yaml` ganha essas 6 entradas em `dependencies:`.

- [ ] **Step 2: Adicionar dependências de desenvolvimento (testes)**

Run:
```bash
flutter pub add --dev fake_cloud_firestore firebase_auth_mocks
```
Expected: comando termina sem erro e `pubspec.yaml` ganha essas 2 entradas em `dev_dependencies:`.

- [ ] **Step 3: Verificar resolução de dependências**

Run: `flutter pub get`
Expected: saída termina com `Got dependencies!` sem conflitos de versão.

---

### Task 2: Restringir plataformas a Android e iOS

**Files:**
- Delete: `linux/`, `macos/`, `windows/`, `web/` (diretórios inteiros)

- [ ] **Step 1: Remover diretórios de plataformas fora de escopo**

Run:
```bash
rm -rf linux macos windows web
```

- [ ] **Step 2: Verificar que só android/ios restaram como plataformas**

Run: `ls`
Expected: a listagem não contém mais `linux`, `macos`, `windows` ou `web`; `android/` e `ios/` continuam presentes.

---

### Task 3: Projeto Firebase e `firebase_options.dart` (passo manual)

Esta tarefa não é automatizável por um agente sem credenciais interativas — requer login no Firebase/Google. Deve ser executada por uma pessoa com acesso à conta Google que será dona do projeto.

**Files:**
- Create: `lib/firebase_options.dart` (gerado pela CLI, não escrever manualmente)

- [ ] **Step 1: Instalar a Firebase CLI e o FlutterFire CLI (se ainda não instalados)**

Run:
```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

- [ ] **Step 2: Login na Firebase CLI**

Run: `firebase login`
Expected: abre o navegador para login Google; termina com "Success! Logged in as ...".

- [ ] **Step 3: Criar o projeto Firebase (via console ou CLI)**

Run: `firebase projects:create revisacar-app` (ajuste o ID se já estiver em uso)
Expected: projeto criado, ID impresso no terminal.

- [ ] **Step 4: Configurar o Flutter para esse projeto**

Run: `flutterfire configure --project=revisacar-app`
Expected: CLI pergunta quais plataformas (selecionar Android e iOS), gera `lib/firebase_options.dart` e os arquivos `google-services.json` (Android) / `GoogleService-Info.plist` (iOS).

- [ ] **Step 5: Habilitar Google Sign-In no Firebase Auth**

No console do Firebase (https://console.firebase.google.com) → projeto `revisacar-app` → Authentication → Sign-in method → habilitar "Google".

- [ ] **Step 6: Habilitar Cloud Firestore e Firebase Storage**

No console: Firestore Database → Criar banco (modo produção, região `southamerica-east1` ou a mais próxima); Storage → Começar (mesmo modo).

- [ ] **Step 7: Verificar que o arquivo foi gerado corretamente**

Run: `test -f lib/firebase_options.dart && echo "OK"`
Expected: imprime `OK`.

---

### Task 4: Inicializar Firebase no `main.dart`

**Files:**
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `DefaultFirebaseOptions` de `lib/firebase_options.dart` (gerado na Task 3).
- Produces: app inicializado com Firebase antes de rodar qualquer widget; base para o `AuthGate` que o Plano 2 vai construir.

- [ ] **Step 1: Substituir o conteúdo padrão do `main.dart` pela inicialização do Firebase**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  runApp(const RevisaCarApp());
}

class RevisaCarApp extends StatelessWidget {
  const RevisaCarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RevisaCar',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const Scaffold(body: Center(child: Text('RevisaCar'))),
    );
  }
}
```

- [ ] **Step 2: Remover o teste padrão do contador, que não se aplica mais**

Run: `rm test/widget_test.dart`

- [ ] **Step 3: Verificar que o projeto compila**

Run: `flutter analyze`
Expected: `No issues found!`

---

### Task 5: Modelo `Veiculo`

**Files:**
- Create: `lib/models/veiculo.dart`
- Test: `test/models/veiculo_test.dart`

**Interfaces:**
- Produces: `class Veiculo { id, nome, modelo, ano, placa, kmAtual, tipoVeiculo, fotoUrl }`, `enum TipoVeiculo { carro, moto }`, `Veiculo.fromMap(String id, Map<String, dynamic> data)`, `Veiculo.toMap()`, `Veiculo.copyWith(...)`.

- [ ] **Step 1: Escrever o teste (falhando)**

```dart
// test/models/veiculo_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/veiculo.dart';

void main() {
  group('Veiculo', () {
    test('fromMap/toMap round-trip preserva todos os campos', () {
      const veiculo = Veiculo(
        id: 'v1',
        nome: 'Meu HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
        fotoUrl: 'https://example.com/foto.jpg',
      );

      final map = veiculo.toMap();
      final restaurado = Veiculo.fromMap('v1', map);

      expect(restaurado, veiculo);
    });

    test('fromMap usa TipoVeiculo.carro como fallback se o valor for desconhecido', () {
      final map = {
        'nome': 'X',
        'modelo': 'Y',
        'ano': 2020,
        'placa': 'ZZZ',
        'kmAtual': 0,
        'tipoVeiculo': 'valor_invalido',
      };

      final veiculo = Veiculo.fromMap('v1', map);

      expect(veiculo.tipoVeiculo, TipoVeiculo.carro);
    });

    test('fotoUrl é nula quando ausente do map', () {
      final map = {
        'nome': 'X',
        'modelo': 'Y',
        'ano': 2020,
        'placa': 'ZZZ',
        'kmAtual': 0,
        'tipoVeiculo': 'moto',
      };

      final veiculo = Veiculo.fromMap('v1', map);

      expect(veiculo.fotoUrl, isNull);
      expect(veiculo.tipoVeiculo, TipoVeiculo.moto);
    });

    test('copyWith troca só os campos informados', () {
      const veiculo = Veiculo(
        id: 'v1',
        nome: 'Meu HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
      );

      final atualizado = veiculo.copyWith(kmAtual: 46000);

      expect(atualizado.kmAtual, 46000);
      expect(atualizado.nome, veiculo.nome);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/models/veiculo_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'revisacar'` ou `lib/models/veiculo.dart` não existe.

- [ ] **Step 3: Implementar o modelo**

```dart
// lib/models/veiculo.dart
enum TipoVeiculo { carro, moto }

class Veiculo {
  final String id;
  final String nome;
  final String modelo;
  final int ano;
  final String placa;
  final int kmAtual;
  final TipoVeiculo tipoVeiculo;
  final String? fotoUrl;

  const Veiculo({
    required this.id,
    required this.nome,
    required this.modelo,
    required this.ano,
    required this.placa,
    required this.kmAtual,
    required this.tipoVeiculo,
    this.fotoUrl,
  });

  factory Veiculo.fromMap(String id, Map<String, dynamic> data) {
    return Veiculo(
      id: id,
      nome: data['nome'] as String,
      modelo: data['modelo'] as String,
      ano: data['ano'] as int,
      placa: data['placa'] as String,
      kmAtual: data['kmAtual'] as int,
      tipoVeiculo: TipoVeiculo.values.firstWhere(
        (t) => t.name == data['tipoVeiculo'],
        orElse: () => TipoVeiculo.carro,
      ),
      fotoUrl: data['fotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'modelo': modelo,
      'ano': ano,
      'placa': placa,
      'kmAtual': kmAtual,
      'tipoVeiculo': tipoVeiculo.name,
      'fotoUrl': fotoUrl,
    };
  }

  Veiculo copyWith({
    String? nome,
    String? modelo,
    int? ano,
    String? placa,
    int? kmAtual,
    TipoVeiculo? tipoVeiculo,
    String? fotoUrl,
  }) {
    return Veiculo(
      id: id,
      nome: nome ?? this.nome,
      modelo: modelo ?? this.modelo,
      ano: ano ?? this.ano,
      placa: placa ?? this.placa,
      kmAtual: kmAtual ?? this.kmAtual,
      tipoVeiculo: tipoVeiculo ?? this.tipoVeiculo,
      fotoUrl: fotoUrl ?? this.fotoUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Veiculo &&
      other.id == id &&
      other.nome == nome &&
      other.modelo == modelo &&
      other.ano == ano &&
      other.placa == placa &&
      other.kmAtual == kmAtual &&
      other.tipoVeiculo == tipoVeiculo &&
      other.fotoUrl == fotoUrl;

  @override
  int get hashCode =>
      Object.hash(id, nome, modelo, ano, placa, kmAtual, tipoVeiculo, fotoUrl);
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/models/veiculo_test.dart`
Expected: `All tests passed!`

---

### Task 6: Modelo `Manutencao`

**Files:**
- Create: `lib/models/manutencao.dart`
- Test: `test/models/manutencao_test.dart`

**Interfaces:**
- Produces: `enum TipoManutencao { revisao, trocaOleo, trocaFiltro, pneusRodizio, bateria, palhetas, arCondicionado, alinhamentoBalanceamento, outro }`, `class Manutencao { id, veiculoId, tipo, descricaoOutro, dataRealizada, kmNaData, custo, oficina, observacoes }`, `Manutencao.fromMap(String id, String veiculoId, Map<String, dynamic> data)`, `.toMap()`.

- [ ] **Step 1: Escrever o teste (falhando)**

```dart
// test/models/manutencao_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/manutencao.dart';

void main() {
  group('Manutencao', () {
    test('fromMap/toMap round-trip preserva todos os campos', () {
      final manutencao = Manutencao(
        id: 'm1',
        veiculoId: 'v1',
        tipo: TipoManutencao.trocaOleo,
        dataRealizada: DateTime(2026, 1, 10),
        kmNaData: 40000,
        custo: 250.0,
        oficina: 'Oficina do Zé',
        observacoes: 'Óleo sintético 5W30',
      );

      final map = manutencao.toMap();
      final restaurada = Manutencao.fromMap('m1', 'v1', map);

      expect(restaurada, manutencao);
    });

    test('aceita Timestamp do Firestore em dataRealizada', () {
      final map = {
        'tipo': 'revisao',
        'descricaoOutro': null,
        'dataRealizada': Timestamp.fromDate(DateTime(2026, 2, 1)),
        'kmNaData': 41000,
        'custo': 300.0,
        'oficina': 'Concessionária',
        'observacoes': '',
      };

      final manutencao = Manutencao.fromMap('m2', 'v1', map);

      expect(manutencao.dataRealizada, DateTime(2026, 2, 1));
    });

    test('tipo desconhecido cai para outro', () {
      final map = {
        'tipo': 'valor_invalido',
        'dataRealizada': DateTime(2026, 1, 1),
        'kmNaData': 0,
        'custo': 0.0,
        'oficina': '',
        'observacoes': '',
      };

      final manutencao = Manutencao.fromMap('m3', 'v1', map);

      expect(manutencao.tipo, TipoManutencao.outro);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/models/manutencao_test.dart`
Expected: FAIL — `lib/models/manutencao.dart` não existe.

- [ ] **Step 3: Implementar o modelo (e o utilitário de parsing de data compartilhado)**

```dart
// lib/models/firestore_date.dart
import 'package:cloud_firestore/cloud_firestore.dart';

DateTime parseFirestoreDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  throw ArgumentError('Tipo de data inválido: ${value.runtimeType}');
}
```

```dart
// lib/models/manutencao.dart
import 'firestore_date.dart';

enum TipoManutencao {
  revisao,
  trocaOleo,
  trocaFiltro,
  pneusRodizio,
  bateria,
  palhetas,
  arCondicionado,
  alinhamentoBalanceamento,
  outro,
}

class Manutencao {
  final String id;
  final String veiculoId;
  final TipoManutencao tipo;
  final String? descricaoOutro;
  final DateTime dataRealizada;
  final int kmNaData;
  final double custo;
  final String oficina;
  final String observacoes;

  const Manutencao({
    required this.id,
    required this.veiculoId,
    required this.tipo,
    this.descricaoOutro,
    required this.dataRealizada,
    required this.kmNaData,
    required this.custo,
    required this.oficina,
    required this.observacoes,
  });

  factory Manutencao.fromMap(String id, String veiculoId, Map<String, dynamic> data) {
    return Manutencao(
      id: id,
      veiculoId: veiculoId,
      tipo: TipoManutencao.values.firstWhere(
        (t) => t.name == data['tipo'],
        orElse: () => TipoManutencao.outro,
      ),
      descricaoOutro: data['descricaoOutro'] as String?,
      dataRealizada: parseFirestoreDate(data['dataRealizada']),
      kmNaData: data['kmNaData'] as int,
      custo: (data['custo'] as num).toDouble(),
      oficina: data['oficina'] as String,
      observacoes: data['observacoes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo.name,
      'descricaoOutro': descricaoOutro,
      'dataRealizada': dataRealizada,
      'kmNaData': kmNaData,
      'custo': custo,
      'oficina': oficina,
      'observacoes': observacoes,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is Manutencao &&
      other.id == id &&
      other.veiculoId == veiculoId &&
      other.tipo == tipo &&
      other.descricaoOutro == descricaoOutro &&
      other.dataRealizada == dataRealizada &&
      other.kmNaData == kmNaData &&
      other.custo == custo &&
      other.oficina == oficina &&
      other.observacoes == observacoes;

  @override
  int get hashCode => Object.hash(
      id, veiculoId, tipo, descricaoOutro, dataRealizada, kmNaData, custo, oficina, observacoes);
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/models/manutencao_test.dart`
Expected: `All tests passed!`

---

### Task 7: Modelo `Abastecimento`

**Files:**
- Create: `lib/models/abastecimento.dart`
- Test: `test/models/abastecimento_test.dart`

**Interfaces:**
- Consumes: `parseFirestoreDate` de `lib/models/firestore_date.dart` (Task 6).
- Produces: `class Abastecimento { id, veiculoId, data, kmAtual, litros, valorTotal, tanqueCheio }`, `Abastecimento.fromMap(String id, String veiculoId, Map<String, dynamic> map)`, `.toMap()`.

- [ ] **Step 1: Escrever o teste (falhando)**

```dart
// test/models/abastecimento_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/abastecimento.dart';

void main() {
  group('Abastecimento', () {
    test('fromMap/toMap round-trip preserva todos os campos', () {
      final abastecimento = Abastecimento(
        id: 'a1',
        veiculoId: 'v1',
        data: DateTime(2026, 3, 1),
        kmAtual: 45500,
        litros: 35.5,
        valorTotal: 210.90,
        tanqueCheio: true,
      );

      final map = abastecimento.toMap();
      final restaurado = Abastecimento.fromMap('a1', 'v1', map);

      expect(restaurado, abastecimento);
    });

    test('tanqueCheio false é preservado', () {
      final map = {
        'data': DateTime(2026, 3, 5),
        'kmAtual': 45700,
        'litros': 10.0,
        'valorTotal': 60.0,
        'tanqueCheio': false,
      };

      final abastecimento = Abastecimento.fromMap('a2', 'v1', map);

      expect(abastecimento.tanqueCheio, isFalse);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/models/abastecimento_test.dart`
Expected: FAIL — `lib/models/abastecimento.dart` não existe.

- [ ] **Step 3: Implementar o modelo**

```dart
// lib/models/abastecimento.dart
import 'firestore_date.dart';

class Abastecimento {
  final String id;
  final String veiculoId;
  final DateTime data;
  final int kmAtual;
  final double litros;
  final double valorTotal;
  final bool tanqueCheio;

  const Abastecimento({
    required this.id,
    required this.veiculoId,
    required this.data,
    required this.kmAtual,
    required this.litros,
    required this.valorTotal,
    required this.tanqueCheio,
  });

  factory Abastecimento.fromMap(String id, String veiculoId, Map<String, dynamic> map) {
    return Abastecimento(
      id: id,
      veiculoId: veiculoId,
      data: parseFirestoreDate(map['data']),
      kmAtual: map['kmAtual'] as int,
      litros: (map['litros'] as num).toDouble(),
      valorTotal: (map['valorTotal'] as num).toDouble(),
      tanqueCheio: map['tanqueCheio'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'data': data,
      'kmAtual': kmAtual,
      'litros': litros,
      'valorTotal': valorTotal,
      'tanqueCheio': tanqueCheio,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is Abastecimento &&
      other.id == id &&
      other.veiculoId == veiculoId &&
      other.data == data &&
      other.kmAtual == kmAtual &&
      other.litros == litros &&
      other.valorTotal == valorTotal &&
      other.tanqueCheio == tanqueCheio;

  @override
  int get hashCode =>
      Object.hash(id, veiculoId, data, kmAtual, litros, valorTotal, tanqueCheio);
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/models/abastecimento_test.dart`
Expected: `All tests passed!`

---

### Task 8: Modelo `LembreteManutencao`

**Files:**
- Create: `lib/models/lembrete_manutencao.dart`
- Test: `test/models/lembrete_manutencao_test.dart`

**Interfaces:**
- Consumes: `TipoManutencao` de `lib/models/manutencao.dart` (Task 6), `parseFirestoreDate` de `lib/models/firestore_date.dart` (Task 6).
- Produces: `class LembreteManutencao { id, veiculoId, tipoManutencao, intervaloKm, intervaloDias, antecedenciaKm, antecedenciaDias, intervaloRepeticaoDias, ativo, resolvidoEm }`, `.fromMap(String id, String veiculoId, Map<String, dynamic> data)`, `.toMap()`.

- [ ] **Step 1: Escrever o teste (falhando)**

```dart
// test/models/lembrete_manutencao_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/lembrete_manutencao.dart';
import 'package:revisacar/models/manutencao.dart';

void main() {
  group('LembreteManutencao', () {
    test('fromMap/toMap round-trip preserva todos os campos', () {
      final lembrete = LembreteManutencao(
        id: 'l1',
        veiculoId: 'v1',
        tipoManutencao: TipoManutencao.trocaOleo,
        intervaloKm: 10000,
        intervaloDias: 180,
        antecedenciaKm: 500,
        antecedenciaDias: 15,
        intervaloRepeticaoDias: 3,
        ativo: true,
        resolvidoEm: DateTime(2026, 1, 1),
      );

      final map = lembrete.toMap();
      final restaurado = LembreteManutencao.fromMap('l1', 'v1', map);

      expect(restaurado, lembrete);
    });

    test('exige intervaloKm ou intervaloDias', () {
      expect(
        () => LembreteManutencao(
          id: 'l2',
          veiculoId: 'v1',
          tipoManutencao: TipoManutencao.revisao,
          antecedenciaKm: 0,
          antecedenciaDias: 0,
          intervaloRepeticaoDias: 3,
          ativo: true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('resolvidoEm nulo é preservado', () {
      final map = {
        'tipoManutencao': 'revisao',
        'intervaloKm': 5000,
        'intervaloDias': null,
        'antecedenciaKm': 200,
        'antecedenciaDias': 10,
        'intervaloRepeticaoDias': 5,
        'ativo': true,
        'resolvidoEm': null,
      };

      final lembrete = LembreteManutencao.fromMap('l3', 'v1', map);

      expect(lembrete.resolvidoEm, isNull);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/models/lembrete_manutencao_test.dart`
Expected: FAIL — `lib/models/lembrete_manutencao.dart` não existe.

- [ ] **Step 3: Implementar o modelo**

```dart
// lib/models/lembrete_manutencao.dart
import 'firestore_date.dart';
import 'manutencao.dart';

class LembreteManutencao {
  final String id;
  final String veiculoId;
  final TipoManutencao tipoManutencao;
  final int? intervaloKm;
  final int? intervaloDias;
  final int antecedenciaKm;
  final int antecedenciaDias;
  final int intervaloRepeticaoDias;
  final bool ativo;
  final DateTime? resolvidoEm;

  LembreteManutencao({
    required this.id,
    required this.veiculoId,
    required this.tipoManutencao,
    this.intervaloKm,
    this.intervaloDias,
    required this.antecedenciaKm,
    required this.antecedenciaDias,
    required this.intervaloRepeticaoDias,
    required this.ativo,
    this.resolvidoEm,
  }) : assert(intervaloKm != null || intervaloDias != null,
            'LembreteManutencao exige intervaloKm ou intervaloDias');

  factory LembreteManutencao.fromMap(String id, String veiculoId, Map<String, dynamic> data) {
    return LembreteManutencao(
      id: id,
      veiculoId: veiculoId,
      tipoManutencao: TipoManutencao.values.firstWhere(
        (t) => t.name == data['tipoManutencao'],
        orElse: () => TipoManutencao.outro,
      ),
      intervaloKm: data['intervaloKm'] as int?,
      intervaloDias: data['intervaloDias'] as int?,
      antecedenciaKm: data['antecedenciaKm'] as int? ?? 0,
      antecedenciaDias: data['antecedenciaDias'] as int? ?? 0,
      intervaloRepeticaoDias: data['intervaloRepeticaoDias'] as int? ?? 3,
      ativo: data['ativo'] as bool? ?? true,
      resolvidoEm:
          data['resolvidoEm'] == null ? null : parseFirestoreDate(data['resolvidoEm']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipoManutencao': tipoManutencao.name,
      'intervaloKm': intervaloKm,
      'intervaloDias': intervaloDias,
      'antecedenciaKm': antecedenciaKm,
      'antecedenciaDias': antecedenciaDias,
      'intervaloRepeticaoDias': intervaloRepeticaoDias,
      'ativo': ativo,
      'resolvidoEm': resolvidoEm,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is LembreteManutencao &&
      other.id == id &&
      other.veiculoId == veiculoId &&
      other.tipoManutencao == tipoManutencao &&
      other.intervaloKm == intervaloKm &&
      other.intervaloDias == intervaloDias &&
      other.antecedenciaKm == antecedenciaKm &&
      other.antecedenciaDias == antecedenciaDias &&
      other.intervaloRepeticaoDias == intervaloRepeticaoDias &&
      other.ativo == ativo &&
      other.resolvidoEm == resolvidoEm;

  @override
  int get hashCode => Object.hash(id, veiculoId, tipoManutencao, intervaloKm, intervaloDias,
      antecedenciaKm, antecedenciaDias, intervaloRepeticaoDias, ativo, resolvidoEm);
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/models/lembrete_manutencao_test.dart`
Expected: `All tests passed!`

---

### Task 9: Modelo `ChecklistItem`

**Files:**
- Create: `lib/models/checklist_item.dart`
- Test: `test/models/checklist_item_test.dart`

**Interfaces:**
- Produces: `class ChecklistItem { id, veiculoId, descricao, ordem, verificado }`, `.fromMap(String id, String veiculoId, Map<String, dynamic> map)`, `.toMap()`, `.copyWith({bool? verificado})`.

- [ ] **Step 1: Escrever o teste (falhando)**

```dart
// test/models/checklist_item_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/checklist_item.dart';

void main() {
  group('ChecklistItem', () {
    test('fromMap/toMap round-trip preserva todos os campos', () {
      const item = ChecklistItem(
        id: 'c1',
        veiculoId: 'v1',
        descricao: 'Óleo',
        ordem: 0,
        verificado: false,
      );

      final map = item.toMap();
      final restaurado = ChecklistItem.fromMap('c1', 'v1', map);

      expect(restaurado, item);
    });

    test('copyWith alterna verificado sem afetar outros campos', () {
      const item = ChecklistItem(
        id: 'c1',
        veiculoId: 'v1',
        descricao: 'Pneus',
        ordem: 1,
        verificado: false,
      );

      final marcado = item.copyWith(verificado: true);

      expect(marcado.verificado, isTrue);
      expect(marcado.descricao, item.descricao);
      expect(marcado.ordem, item.ordem);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/models/checklist_item_test.dart`
Expected: FAIL — `lib/models/checklist_item.dart` não existe.

- [ ] **Step 3: Implementar o modelo**

```dart
// lib/models/checklist_item.dart
class ChecklistItem {
  final String id;
  final String veiculoId;
  final String descricao;
  final int ordem;
  final bool verificado;

  const ChecklistItem({
    required this.id,
    required this.veiculoId,
    required this.descricao,
    required this.ordem,
    required this.verificado,
  });

  factory ChecklistItem.fromMap(String id, String veiculoId, Map<String, dynamic> map) {
    return ChecklistItem(
      id: id,
      veiculoId: veiculoId,
      descricao: map['descricao'] as String,
      ordem: map['ordem'] as int,
      verificado: map['verificado'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'descricao': descricao,
      'ordem': ordem,
      'verificado': verificado,
    };
  }

  ChecklistItem copyWith({bool? verificado}) => ChecklistItem(
        id: id,
        veiculoId: veiculoId,
        descricao: descricao,
        ordem: ordem,
        verificado: verificado ?? this.verificado,
      );

  @override
  bool operator ==(Object other) =>
      other is ChecklistItem &&
      other.id == id &&
      other.veiculoId == veiculoId &&
      other.descricao == descricao &&
      other.ordem == ordem &&
      other.verificado == verificado;

  @override
  int get hashCode => Object.hash(id, veiculoId, descricao, ordem, verificado);
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/models/checklist_item_test.dart`
Expected: `All tests passed!`

---

### Task 10: `ConsumoService` — consumo por abastecimento (item 4a da spec)

**Files:**
- Create: `lib/services/consumo_service.dart`
- Test: `test/services/consumo_service_test.dart`

**Interfaces:**
- Consumes: `Abastecimento` de `lib/models/abastecimento.dart` (Task 7).
- Produces: `class ConsumoService` com `static double? consumoPorAbastecimento(Abastecimento atual, Abastecimento anterior)`.

- [ ] **Step 1: Escrever o teste (falhando)**

```dart
// test/services/consumo_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/abastecimento.dart';
import 'package:revisacar/services/consumo_service.dart';

Abastecimento _abastecimento({
  required DateTime data,
  required int km,
  required double litros,
  required double valor,
  required bool tanqueCheio,
  String id = 'a',
}) {
  return Abastecimento(
    id: id,
    veiculoId: 'v1',
    data: data,
    kmAtual: km,
    litros: litros,
    valorTotal: valor,
    tanqueCheio: tanqueCheio,
  );
}

void main() {
  group('ConsumoService.consumoPorAbastecimento (4a)', () {
    test('calcula km/l quando ambos são tanque cheio', () {
      final anterior = _abastecimento(
          data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true);
      final atual = _abastecimento(
          data: DateTime(2026, 1, 15), km: 40400, litros: 40, valor: 240, tanqueCheio: true);

      final consumo = ConsumoService.consumoPorAbastecimento(atual, anterior);

      expect(consumo, 400 / 40);
    });

    test('retorna null quando o abastecimento anterior não foi tanque cheio', () {
      final anterior = _abastecimento(
          data: DateTime(2026, 1, 1), km: 40000, litros: 20, valor: 120, tanqueCheio: false);
      final atual = _abastecimento(
          data: DateTime(2026, 1, 15), km: 40400, litros: 40, valor: 240, tanqueCheio: true);

      final consumo = ConsumoService.consumoPorAbastecimento(atual, anterior);

      expect(consumo, isNull);
    });

    test('retorna null quando o abastecimento atual não é tanque cheio', () {
      final anterior = _abastecimento(
          data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true);
      final atual = _abastecimento(
          data: DateTime(2026, 1, 15), km: 40200, litros: 15, valor: 90, tanqueCheio: false);

      final consumo = ConsumoService.consumoPorAbastecimento(atual, anterior);

      expect(consumo, isNull);
    });

    test('retorna null quando km rodado não é positivo (dado inconsistente)', () {
      final anterior = _abastecimento(
          data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true);
      final atual = _abastecimento(
          data: DateTime(2026, 1, 15), km: 40000, litros: 40, valor: 240, tanqueCheio: true);

      final consumo = ConsumoService.consumoPorAbastecimento(atual, anterior);

      expect(consumo, isNull);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/services/consumo_service_test.dart`
Expected: FAIL — `lib/services/consumo_service.dart` não existe.

- [ ] **Step 3: Implementar `consumoPorAbastecimento`**

```dart
// lib/services/consumo_service.dart
import '../models/abastecimento.dart';

class ConsumoService {
  static double? consumoPorAbastecimento(Abastecimento atual, Abastecimento anterior) {
    if (!atual.tanqueCheio || !anterior.tanqueCheio) return null;
    final kmRodado = atual.kmAtual - anterior.kmAtual;
    if (kmRodado <= 0 || atual.litros <= 0) return null;
    return kmRodado / atual.litros;
  }
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/services/consumo_service_test.dart`
Expected: `All tests passed!`

---

### Task 11: `ConsumoService` — custo por litro e custo por km (itens 4b e 4c)

**Files:**
- Modify: `lib/services/consumo_service.dart`
- Modify: `test/services/consumo_service_test.dart`

**Interfaces:**
- Produces: `static double custoPorLitro(Abastecimento abastecimento)`, `static double? custoPorKm(Abastecimento atual, Abastecimento anterior)`.

- [ ] **Step 1: Acrescentar os testes (falhando)**

Adicionar ao final do `main()` em `test/services/consumo_service_test.dart` (antes do fechamento do `group` principal ou como novos `group`s no mesmo arquivo):

```dart
  group('ConsumoService.custoPorLitro (4b)', () {
    test('calcula valor total dividido por litros', () {
      final abastecimento = _abastecimento(
          data: DateTime(2026, 1, 1), km: 40000, litros: 40, valor: 240, tanqueCheio: true);

      expect(ConsumoService.custoPorLitro(abastecimento), 6.0);
    });
  });

  group('ConsumoService.custoPorKm (4c)', () {
    test('calcula custo por km entre abastecimentos consecutivos, tanque cheio ou não', () {
      final anterior = _abastecimento(
          data: DateTime(2026, 1, 1), km: 40000, litros: 20, valor: 120, tanqueCheio: false);
      final atual = _abastecimento(
          data: DateTime(2026, 1, 10), km: 40200, litros: 15, valor: 90, tanqueCheio: false);

      final custoPorKm = ConsumoService.custoPorKm(atual, anterior);

      expect(custoPorKm, 90 / 200);
    });

    test('retorna null quando km rodado não é positivo', () {
      final anterior = _abastecimento(
          data: DateTime(2026, 1, 1), km: 40000, litros: 20, valor: 120, tanqueCheio: true);
      final atual = _abastecimento(
          data: DateTime(2026, 1, 10), km: 40000, litros: 15, valor: 90, tanqueCheio: true);

      expect(ConsumoService.custoPorKm(atual, anterior), isNull);
    });
  });
```

- [ ] **Step 2: Rodar os testes e confirmar que os novos falham**

Run: `flutter test test/services/consumo_service_test.dart`
Expected: FAIL — `custoPorLitro`/`custoPorKm` não existem em `ConsumoService`.

- [ ] **Step 3: Implementar as duas funções**

Adicionar à classe `ConsumoService` em `lib/services/consumo_service.dart`:

```dart
  static double custoPorLitro(Abastecimento abastecimento) {
    return abastecimento.valorTotal / abastecimento.litros;
  }

  static double? custoPorKm(Abastecimento atual, Abastecimento anterior) {
    final kmRodado = atual.kmAtual - anterior.kmAtual;
    if (kmRodado <= 0) return null;
    return atual.valorTotal / kmRodado;
  }
```

- [ ] **Step 4: Rodar os testes e confirmar que todos passam**

Run: `flutter test test/services/consumo_service_test.dart`
Expected: `All tests passed!`

---

### Task 12: `ConsumoService` — consumo agregado por período (item 4d)

**Files:**
- Modify: `lib/services/consumo_service.dart`
- Modify: `test/services/consumo_service_test.dart`

**Interfaces:**
- Produces: `static double? consumoPeriodo(List<Abastecimento> abastecimentosNoPeriodo)`.

- [ ] **Step 1: Acrescentar os testes (falhando)**

```dart
  group('ConsumoService.consumoPeriodo (4d)', () {
    test('usa km total do período dividido por litros exceto o primeiro abastecimento', () {
      final abastecimentos = [
        _abastecimento(id: 'a1', data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true),
        _abastecimento(id: 'a2', data: DateTime(2026, 1, 10), km: 40300, litros: 25, valor: 150, tanqueCheio: true),
        _abastecimento(id: 'a3', data: DateTime(2026, 1, 20), km: 40600, litros: 25, valor: 150, tanqueCheio: true),
      ];

      final consumo = ConsumoService.consumoPeriodo(abastecimentos);

      // km total = 40600 - 40000 = 600; litros exceto o primeiro = 25 + 25 = 50
      expect(consumo, 600 / 50);
    });

    test('funciona mesmo com abastecimentos fora de ordem de inserção', () {
      final abastecimentos = [
        _abastecimento(id: 'a3', data: DateTime(2026, 1, 20), km: 40600, litros: 25, valor: 150, tanqueCheio: true),
        _abastecimento(id: 'a1', data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true),
        _abastecimento(id: 'a2', data: DateTime(2026, 1, 10), km: 40300, litros: 25, valor: 150, tanqueCheio: true),
      ];

      final consumo = ConsumoService.consumoPeriodo(abastecimentos);

      expect(consumo, 600 / 50);
    });

    test('retorna null com 0 abastecimentos no período', () {
      expect(ConsumoService.consumoPeriodo([]), isNull);
    });

    test('retorna null com 1 abastecimento no período', () {
      final abastecimentos = [
        _abastecimento(data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true),
      ];

      expect(ConsumoService.consumoPeriodo(abastecimentos), isNull);
    });
  });
```

- [ ] **Step 2: Rodar os testes e confirmar que falham**

Run: `flutter test test/services/consumo_service_test.dart`
Expected: FAIL — `consumoPeriodo` não existe.

- [ ] **Step 3: Implementar `consumoPeriodo` e o helper de ordenação**

```dart
  static double? consumoPeriodo(List<Abastecimento> abastecimentosNoPeriodo) {
    final ordenados = _ordenarPorData(abastecimentosNoPeriodo);
    if (ordenados.length < 2) return null;
    final kmTotal = ordenados.last.kmAtual - ordenados.first.kmAtual;
    final litrosTotais = ordenados.skip(1).fold<double>(0, (soma, a) => soma + a.litros);
    if (kmTotal <= 0 || litrosTotais <= 0) return null;
    return kmTotal / litrosTotais;
  }

  static List<Abastecimento> _ordenarPorData(List<Abastecimento> abastecimentos) {
    final copia = List<Abastecimento>.of(abastecimentos);
    copia.sort((a, b) {
      final porData = a.data.compareTo(b.data);
      if (porData != 0) return porData;
      return a.kmAtual.compareTo(b.kmAtual);
    });
    return copia;
  }
```

- [ ] **Step 4: Rodar os testes e confirmar que todos passam**

Run: `flutter test test/services/consumo_service_test.dart`
Expected: `All tests passed!`

---

### Task 13: `ConsumoService` — gasto e custo por km no período (itens 4e e 4f)

**Files:**
- Modify: `lib/services/consumo_service.dart`
- Modify: `test/services/consumo_service_test.dart`

**Interfaces:**
- Consumes: `_ordenarPorData` (privado, Task 12).
- Produces: `static double gastoPeriodo(List<Abastecimento> abastecimentosNoPeriodo)`, `static double? custoPorKmPeriodo(List<Abastecimento> abastecimentosNoPeriodo)`.

- [ ] **Step 1: Acrescentar os testes (falhando)**

```dart
  group('ConsumoService.gastoPeriodo (4e)', () {
    test('soma valorTotal de todos os abastecimentos do período', () {
      final abastecimentos = [
        _abastecimento(data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true),
        _abastecimento(data: DateTime(2026, 1, 10), km: 40300, litros: 25, valor: 150, tanqueCheio: true),
      ];

      expect(ConsumoService.gastoPeriodo(abastecimentos), 330.0);
    });

    test('retorna 0 para período vazio', () {
      expect(ConsumoService.gastoPeriodo([]), 0.0);
    });
  });

  group('ConsumoService.custoPorKmPeriodo (4f)', () {
    test('divide gasto do período pelo km total rodado', () {
      final abastecimentos = [
        _abastecimento(data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true),
        _abastecimento(data: DateTime(2026, 1, 20), km: 40600, litros: 25, valor: 150, tanqueCheio: true),
      ];

      final custoPorKm = ConsumoService.custoPorKmPeriodo(abastecimentos);

      expect(custoPorKm, 330 / 600);
    });

    test('retorna null com menos de 2 abastecimentos no período', () {
      expect(ConsumoService.custoPorKmPeriodo([]), isNull);
    });
  });
```

- [ ] **Step 2: Rodar os testes e confirmar que falham**

Run: `flutter test test/services/consumo_service_test.dart`
Expected: FAIL — `gastoPeriodo`/`custoPorKmPeriodo` não existem.

- [ ] **Step 3: Implementar as duas funções**

```dart
  static double gastoPeriodo(List<Abastecimento> abastecimentosNoPeriodo) {
    return abastecimentosNoPeriodo.fold<double>(0, (soma, a) => soma + a.valorTotal);
  }

  static double? custoPorKmPeriodo(List<Abastecimento> abastecimentosNoPeriodo) {
    final ordenados = _ordenarPorData(abastecimentosNoPeriodo);
    if (ordenados.length < 2) return null;
    final kmTotal = ordenados.last.kmAtual - ordenados.first.kmAtual;
    if (kmTotal <= 0) return null;
    return gastoPeriodo(abastecimentosNoPeriodo) / kmTotal;
  }
```

- [ ] **Step 4: Rodar os testes e confirmar que todos passam**

Run: `flutter test test/services/consumo_service_test.dart`
Expected: `All tests passed!`

---

### Task 14: `LembreteService` — cálculo da próxima meta

**Files:**
- Create: `lib/services/lembrete_service.dart`
- Test: `test/services/lembrete_service_test.dart`

**Interfaces:**
- Consumes: `LembreteManutencao` de `lib/models/lembrete_manutencao.dart` (Task 8), `TipoManutencao` de `lib/models/manutencao.dart` (Task 6).
- Produces: `class MetaLembrete { int? metaKm, DateTime? metaData }`, `class LembreteService` com `static MetaLembrete calcularProximaMeta({required LembreteManutencao lembrete, required int kmReferencia, required DateTime dataReferencia})`.

- [ ] **Step 1: Escrever o teste (falhando)**

```dart
// test/services/lembrete_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/lembrete_manutencao.dart';
import 'package:revisacar/models/manutencao.dart';
import 'package:revisacar/services/lembrete_service.dart';

LembreteManutencao _lembrete({
  int? intervaloKm,
  int? intervaloDias,
  int antecedenciaKm = 0,
  int antecedenciaDias = 0,
}) {
  return LembreteManutencao(
    id: 'l1',
    veiculoId: 'v1',
    tipoManutencao: TipoManutencao.trocaOleo,
    intervaloKm: intervaloKm,
    intervaloDias: intervaloDias,
    antecedenciaKm: antecedenciaKm,
    antecedenciaDias: antecedenciaDias,
    intervaloRepeticaoDias: 3,
    ativo: true,
  );
}

void main() {
  group('LembreteService.calcularProximaMeta', () {
    test('meta por km soma intervaloKm ao km de referência', () {
      final lembrete = _lembrete(intervaloKm: 10000);

      final meta = LembreteService.calcularProximaMeta(
        lembrete: lembrete,
        kmReferencia: 40000,
        dataReferencia: DateTime(2026, 1, 1),
      );

      expect(meta.metaKm, 50000);
      expect(meta.metaData, isNull);
    });

    test('meta por tempo soma intervaloDias à data de referência', () {
      final lembrete = _lembrete(intervaloDias: 180);

      final meta = LembreteService.calcularProximaMeta(
        lembrete: lembrete,
        kmReferencia: 40000,
        dataReferencia: DateTime(2026, 1, 1),
      );

      expect(meta.metaData, DateTime(2026, 1, 1).add(const Duration(days: 180)));
      expect(meta.metaKm, isNull);
    });

    test('calcula as duas metas quando ambos os intervalos estão configurados', () {
      final lembrete = _lembrete(intervaloKm: 10000, intervaloDias: 180);

      final meta = LembreteService.calcularProximaMeta(
        lembrete: lembrete,
        kmReferencia: 40000,
        dataReferencia: DateTime(2026, 1, 1),
      );

      expect(meta.metaKm, 50000);
      expect(meta.metaData, DateTime(2026, 1, 1).add(const Duration(days: 180)));
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/services/lembrete_service_test.dart`
Expected: FAIL — `lib/services/lembrete_service.dart` não existe.

- [ ] **Step 3: Implementar `MetaLembrete` e `calcularProximaMeta`**

```dart
// lib/services/lembrete_service.dart
import '../models/lembrete_manutencao.dart';

class MetaLembrete {
  final int? metaKm;
  final DateTime? metaData;
  const MetaLembrete({this.metaKm, this.metaData});
}

enum StatusLembrete { emDia, alertaAntecipado, vencido }

class LembreteService {
  static MetaLembrete calcularProximaMeta({
    required LembreteManutencao lembrete,
    required int kmReferencia,
    required DateTime dataReferencia,
  }) {
    final metaKm = lembrete.intervaloKm != null ? kmReferencia + lembrete.intervaloKm! : null;
    final metaData = lembrete.intervaloDias != null
        ? dataReferencia.add(Duration(days: lembrete.intervaloDias!))
        : null;
    return MetaLembrete(metaKm: metaKm, metaData: metaData);
  }
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/services/lembrete_service_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Escrever o teste (falhando) para encontrar a manutenção de referência**

A spec (Decisão 5) diz que a meta de cada lembrete parte "da manutenção mais recente daquele tipo (por data)". Adicionar a `test/services/lembrete_service_test.dart`:

```dart
  group('LembreteService.manutencaoMaisRecente', () {
    test('retorna a manutenção mais recente (por data) daquele tipo', () {
      final manutencoes = [
        Manutencao(
          id: 'm1',
          veiculoId: 'v1',
          tipo: TipoManutencao.trocaOleo,
          dataRealizada: DateTime(2025, 6, 1),
          kmNaData: 30000,
          custo: 200,
          oficina: 'A',
          observacoes: '',
        ),
        Manutencao(
          id: 'm2',
          veiculoId: 'v1',
          tipo: TipoManutencao.trocaOleo,
          dataRealizada: DateTime(2026, 1, 1),
          kmNaData: 40000,
          custo: 220,
          oficina: 'B',
          observacoes: '',
        ),
        Manutencao(
          id: 'm3',
          veiculoId: 'v1',
          tipo: TipoManutencao.revisao,
          dataRealizada: DateTime(2026, 2, 1),
          kmNaData: 41000,
          custo: 500,
          oficina: 'C',
          observacoes: '',
        ),
      ];

      final referencia =
          LembreteService.manutencaoMaisRecente(manutencoes, TipoManutencao.trocaOleo);

      expect(referencia?.id, 'm2');
    });

    test('retorna null quando não há manutenção daquele tipo', () {
      final referencia = LembreteService.manutencaoMaisRecente([], TipoManutencao.bateria);

      expect(referencia, isNull);
    });
  });
```

Adicionar o import de `package:revisacar/models/manutencao.dart` no topo do arquivo (já necessário para os testes de `_lembrete`).

- [ ] **Step 6: Rodar o teste e confirmar que falha**

Run: `flutter test test/services/lembrete_service_test.dart`
Expected: FAIL — `manutencaoMaisRecente` não existe.

- [ ] **Step 7: Implementar `manutencaoMaisRecente`**

Adicionar à classe `LembreteService` em `lib/services/lembrete_service.dart` (e importar `../models/manutencao.dart`):

```dart
  static Manutencao? manutencaoMaisRecente(List<Manutencao> manutencoes, TipoManutencao tipo) {
    final doTipo = manutencoes.where((m) => m.tipo == tipo).toList()
      ..sort((a, b) => a.dataRealizada.compareTo(b.dataRealizada));
    return doTipo.isEmpty ? null : doTipo.last;
  }
```

Nota para o Plano 2: quando `manutencaoMaisRecente` retornar `null` (nenhuma manutenção daquele tipo ainda), a referência a usar é `kmAtual` do veículo e `DateTime.now()` — não existe (nem é necessário) um campo de "data de cadastro" no `Veiculo`.

- [ ] **Step 8: Rodar o teste e confirmar que passa**

Run: `flutter test test/services/lembrete_service_test.dart`
Expected: `All tests passed!`

---

### Task 15: `LembreteService` — status do lembrete (antecedência / vencido)

**Files:**
- Modify: `lib/services/lembrete_service.dart`
- Modify: `test/services/lembrete_service_test.dart`

**Interfaces:**
- Consumes: `MetaLembrete`, `StatusLembrete` (Task 14).
- Produces: `static StatusLembrete calcularStatus({required LembreteManutencao lembrete, required MetaLembrete meta, required int kmAtual, required DateTime hoje})`.

- [ ] **Step 1: Acrescentar os testes (falhando)**

```dart
  group('LembreteService.calcularStatus', () {
    test('emDia quando longe da meta por km e por data', () {
      final lembrete = _lembrete(intervaloKm: 10000, antecedenciaKm: 500);
      final meta = MetaLembrete(metaKm: 50000);

      final status = LembreteService.calcularStatus(
        lembrete: lembrete,
        meta: meta,
        kmAtual: 45000,
        hoje: DateTime(2026, 1, 1),
      );

      expect(status, StatusLembrete.emDia);
    });

    test('alertaAntecipado quando km entra na faixa de antecedência', () {
      final lembrete = _lembrete(intervaloKm: 10000, antecedenciaKm: 500);
      final meta = MetaLembrete(metaKm: 50000);

      final status = LembreteService.calcularStatus(
        lembrete: lembrete,
        meta: meta,
        kmAtual: 49600,
        hoje: DateTime(2026, 1, 1),
      );

      expect(status, StatusLembrete.alertaAntecipado);
    });

    test('vencido quando km atinge ou ultrapassa a meta', () {
      final lembrete = _lembrete(intervaloKm: 10000, antecedenciaKm: 500);
      final meta = MetaLembrete(metaKm: 50000);

      final status = LembreteService.calcularStatus(
        lembrete: lembrete,
        meta: meta,
        kmAtual: 50000,
        hoje: DateTime(2026, 1, 1),
      );

      expect(status, StatusLembrete.vencido);
    });

    test('vencido por data mesmo com km longe da meta ("o que vencer primeiro")', () {
      final lembrete = _lembrete(intervaloKm: 10000, intervaloDias: 180, antecedenciaDias: 15);
      final meta = MetaLembrete(metaKm: 60000, metaData: DateTime(2026, 6, 1));

      final status = LembreteService.calcularStatus(
        lembrete: lembrete,
        meta: meta,
        kmAtual: 41000,
        hoje: DateTime(2026, 6, 1),
      );

      expect(status, StatusLembrete.vencido);
    });
  });
```

- [ ] **Step 2: Rodar os testes e confirmar que falham**

Run: `flutter test test/services/lembrete_service_test.dart`
Expected: FAIL — `calcularStatus` não existe.

- [ ] **Step 3: Implementar `calcularStatus`**

Adicionar à classe `LembreteService`:

```dart
  static StatusLembrete calcularStatus({
    required LembreteManutencao lembrete,
    required MetaLembrete meta,
    required int kmAtual,
    required DateTime hoje,
  }) {
    final vencidoPorKm = meta.metaKm != null && kmAtual >= meta.metaKm!;
    final vencidoPorData = meta.metaData != null && !hoje.isBefore(meta.metaData!);
    if (vencidoPorKm || vencidoPorData) return StatusLembrete.vencido;

    final alertaPorKm =
        meta.metaKm != null && kmAtual >= meta.metaKm! - lembrete.antecedenciaKm;
    final alertaPorData = meta.metaData != null &&
        !hoje.isBefore(meta.metaData!.subtract(Duration(days: lembrete.antecedenciaDias)));
    if (alertaPorKm || alertaPorData) return StatusLembrete.alertaAntecipado;

    return StatusLembrete.emDia;
  }
```

- [ ] **Step 4: Rodar os testes e confirmar que todos passam**

Run: `flutter test test/services/lembrete_service_test.dart`
Expected: `All tests passed!`

---

### Task 16: `ExportService` — geração de CSV

**Files:**
- Create: `lib/services/export_service.dart`
- Test: `test/services/export_service_test.dart`

**Interfaces:**
- Consumes: `Veiculo`, `Manutencao`, `Abastecimento`, `LembreteManutencao` (Tasks 5–8).
- Produces: `class ExportService` com `static String veiculosCsv(List<Veiculo>)`, `static String manutencoesCsv(List<Manutencao>)`, `static String abastecimentosCsv(List<Abastecimento>)`, `static String lembretesCsv(List<LembreteManutencao>)`.

- [ ] **Step 1: Escrever o teste (falhando)**

```dart
// test/services/export_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/abastecimento.dart';
import 'package:revisacar/models/manutencao.dart';
import 'package:revisacar/models/veiculo.dart';
import 'package:revisacar/services/export_service.dart';

void main() {
  group('ExportService', () {
    test('veiculosCsv gera cabeçalho e uma linha por veículo', () {
      const veiculo = Veiculo(
        id: 'v1',
        nome: 'Meu HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
      );

      final csv = ExportService.veiculosCsv([veiculo]);

      expect(csv, 'id,nome,modelo,ano,placa,km_atual\n'
          'v1,Meu HB20,Hyundai HB20,2020,ABC1D23,45000');
    });

    test('veiculosCsv com lista vazia gera só o cabeçalho', () {
      expect(ExportService.veiculosCsv([]), 'id,nome,modelo,ano,placa,km_atual');
    });

    test('escapa campos com vírgula usando aspas', () {
      const veiculo = Veiculo(
        id: 'v1',
        nome: 'Carro, apelido com vírgula',
        modelo: 'X',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 0,
        tipoVeiculo: TipoVeiculo.carro,
      );

      final csv = ExportService.veiculosCsv([veiculo]);

      expect(csv, contains('"Carro, apelido com vírgula"'));
    });

    test('manutencoesCsv formata data em ISO 8601 (aaaa-mm-dd)', () {
      final manutencao = Manutencao(
        id: 'm1',
        veiculoId: 'v1',
        tipo: TipoManutencao.trocaOleo,
        dataRealizada: DateTime(2026, 3, 5),
        kmNaData: 40000,
        custo: 200.0,
        oficina: 'Oficina',
        observacoes: '',
      );

      final csv = ExportService.manutencoesCsv([manutencao]);

      expect(csv, contains('2026-03-05'));
    });

    test('abastecimentosCsv inclui todos os campos na ordem esperada', () {
      final abastecimento = Abastecimento(
        id: 'a1',
        veiculoId: 'v1',
        data: DateTime(2026, 1, 1),
        kmAtual: 40000,
        litros: 30.0,
        valorTotal: 180.0,
        tanqueCheio: true,
      );

      final csv = ExportService.abastecimentosCsv([abastecimento]);

      expect(csv, 'id,veiculo_id,data,km_atual,litros,valor_total,tanque_cheio\n'
          'a1,v1,2026-01-01,40000,30.0,180.0,true');
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/services/export_service_test.dart`
Expected: FAIL — `lib/services/export_service.dart` não existe.

- [ ] **Step 3: Implementar `ExportService`**

```dart
// lib/services/export_service.dart
import '../models/abastecimento.dart';
import '../models/lembrete_manutencao.dart';
import '../models/manutencao.dart';
import '../models/veiculo.dart';

class ExportService {
  static String veiculosCsv(List<Veiculo> veiculos) {
    final linhas = <String>['id,nome,modelo,ano,placa,km_atual'];
    for (final v in veiculos) {
      linhas.add([
        v.id,
        _csvEscape(v.nome),
        _csvEscape(v.modelo),
        v.ano.toString(),
        _csvEscape(v.placa),
        v.kmAtual.toString(),
      ].join(','));
    }
    return linhas.join('\n');
  }

  static String manutencoesCsv(List<Manutencao> manutencoes) {
    final linhas = <String>[
      'id,veiculo_id,tipo,descricao_outro,data_realizada,km_na_data,custo,oficina,observacoes'
    ];
    for (final m in manutencoes) {
      linhas.add([
        m.id,
        m.veiculoId,
        m.tipo.name,
        _csvEscape(m.descricaoOutro ?? ''),
        _formatarData(m.dataRealizada),
        m.kmNaData.toString(),
        m.custo.toString(),
        _csvEscape(m.oficina),
        _csvEscape(m.observacoes),
      ].join(','));
    }
    return linhas.join('\n');
  }

  static String abastecimentosCsv(List<Abastecimento> abastecimentos) {
    final linhas = <String>[
      'id,veiculo_id,data,km_atual,litros,valor_total,tanque_cheio'
    ];
    for (final a in abastecimentos) {
      linhas.add([
        a.id,
        a.veiculoId,
        _formatarData(a.data),
        a.kmAtual.toString(),
        a.litros.toString(),
        a.valorTotal.toString(),
        a.tanqueCheio.toString(),
      ].join(','));
    }
    return linhas.join('\n');
  }

  static String lembretesCsv(List<LembreteManutencao> lembretes) {
    final linhas = <String>[
      'id,veiculo_id,tipo_manutencao,intervalo_km,intervalo_dias,antecedencia_km,'
          'antecedencia_dias,intervalo_repeticao_dias,ativo,resolvido_em'
    ];
    for (final l in lembretes) {
      linhas.add([
        l.id,
        l.veiculoId,
        l.tipoManutencao.name,
        l.intervaloKm?.toString() ?? '',
        l.intervaloDias?.toString() ?? '',
        l.antecedenciaKm.toString(),
        l.antecedenciaDias.toString(),
        l.intervaloRepeticaoDias.toString(),
        l.ativo.toString(),
        l.resolvidoEm != null ? _formatarData(l.resolvidoEm!) : '',
      ].join(','));
    }
    return linhas.join('\n');
  }

  static String _formatarData(DateTime data) {
    final y = data.year.toString().padLeft(4, '0');
    final m = data.month.toString().padLeft(2, '0');
    final d = data.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _csvEscape(String valor) {
    if (valor.contains(',') || valor.contains('"') || valor.contains('\n')) {
      return '"${valor.replaceAll('"', '""')}"';
    }
    return valor;
  }
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/services/export_service_test.dart`
Expected: `All tests passed!`

---

### Task 17: `FirestoreRepository<T>` genérico e `VeiculoRepository`

**Files:**
- Create: `lib/repositories/firestore_repository.dart`
- Create: `lib/repositories/veiculo_repository.dart`
- Test: `test/repositories/veiculo_repository_test.dart`

**Interfaces:**
- Consumes: `Veiculo` (Task 5), `cloud_firestore`, `fake_cloud_firestore` (dev, Task 1).
- Produces: `abstract class FirestoreRepository<T>` com `collection`, `fromMap`, `toMap`, `watchAll`, `add`, `get`, `update`, `delete`; `class VeiculoRepository extends FirestoreRepository<Veiculo>`. O método `get(uid, id, {veiculoId})` busca um único documento (usado pela Task 24 para checar o `kmAtual` antes de atualizá-lo).

- [ ] **Step 1: Escrever o teste (falhando)**

```dart
// test/repositories/veiculo_repository_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/veiculo.dart';
import 'package:revisacar/repositories/veiculo_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late VeiculoRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = VeiculoRepository(firestore);
  });

  group('VeiculoRepository', () {
    test('add grava o veículo e watchAll emite a lista atualizada', () async {
      const veiculo = Veiculo(
        id: '',
        nome: 'Meu HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
      );

      final id = await repository.add('uid1', veiculo);
      final lista = await repository.watchAll('uid1').first;

      expect(lista, hasLength(1));
      expect(lista.first.id, id);
      expect(lista.first.nome, 'Meu HB20');
    });

    test('update altera os campos do veículo', () async {
      const veiculo = Veiculo(
        id: '',
        nome: 'Meu HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
      );
      final id = await repository.add('uid1', veiculo);

      await repository.update('uid1', id, veiculo.copyWith(kmAtual: 46000));
      final lista = await repository.watchAll('uid1').first;

      expect(lista.first.kmAtual, 46000);
    });

    test('delete remove o veículo', () async {
      const veiculo = Veiculo(
        id: '',
        nome: 'X',
        modelo: 'Y',
        ano: 2020,
        placa: 'ZZZ',
        kmAtual: 0,
        tipoVeiculo: TipoVeiculo.moto,
      );
      final id = await repository.add('uid1', veiculo);

      await repository.delete('uid1', id);
      final lista = await repository.watchAll('uid1').first;

      expect(lista, isEmpty);
    });

    test('isola veículos por uid', () async {
      const veiculo = Veiculo(
        id: '',
        nome: 'X',
        modelo: 'Y',
        ano: 2020,
        placa: 'ZZZ',
        kmAtual: 0,
        tipoVeiculo: TipoVeiculo.carro,
      );
      await repository.add('uid1', veiculo);

      final listaOutroUsuario = await repository.watchAll('uid2').first;

      expect(listaOutroUsuario, isEmpty);
    });

    test('get retorna o veículo pelo id, ou null se não existir', () async {
      const veiculo = Veiculo(
        id: '',
        nome: 'Fiat Mobi',
        modelo: 'Fiat Mobi',
        ano: 2019,
        placa: 'XYZ9Z99',
        kmAtual: 30000,
        tipoVeiculo: TipoVeiculo.carro,
      );
      final id = await repository.add('uid1', veiculo);

      final encontrado = await repository.get('uid1', id);
      final inexistente = await repository.get('uid1', 'id-que-nao-existe');

      expect(encontrado?.nome, 'Fiat Mobi');
      expect(inexistente, isNull);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/repositories/veiculo_repository_test.dart`
Expected: FAIL — `lib/repositories/firestore_repository.dart` e `lib/repositories/veiculo_repository.dart` não existem.

- [ ] **Step 3: Implementar a classe base genérica**

```dart
// lib/repositories/firestore_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FirestoreRepository<T> {
  CollectionReference<Map<String, dynamic>> collection(String uid, {String? veiculoId});

  T fromMap(String id, Map<String, dynamic> data, {String? veiculoId});
  Map<String, dynamic> toMap(T item);

  Stream<List<T>> watchAll(String uid, {String? veiculoId}) {
    return collection(uid, veiculoId: veiculoId).snapshots().map(
          (snap) => snap.docs
              .map((d) => fromMap(d.id, d.data(), veiculoId: veiculoId))
              .toList(),
        );
  }

  Future<String> add(String uid, T item, {String? veiculoId}) async {
    final ref = await collection(uid, veiculoId: veiculoId).add(toMap(item));
    return ref.id;
  }

  Future<T?> get(String uid, String id, {String? veiculoId}) async {
    final snap = await collection(uid, veiculoId: veiculoId).doc(id).get();
    if (!snap.exists) return null;
    return fromMap(snap.id, snap.data()!, veiculoId: veiculoId);
  }

  Future<void> update(String uid, String id, T item, {String? veiculoId}) {
    return collection(uid, veiculoId: veiculoId).doc(id).update(toMap(item));
  }

  Future<void> delete(String uid, String id, {String? veiculoId}) {
    return collection(uid, veiculoId: veiculoId).doc(id).delete();
  }
}
```

- [ ] **Step 4: Implementar `VeiculoRepository`**

```dart
// lib/repositories/veiculo_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/veiculo.dart';
import 'firestore_repository.dart';

class VeiculoRepository extends FirestoreRepository<Veiculo> {
  final FirebaseFirestore _firestore;

  VeiculoRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  CollectionReference<Map<String, dynamic>> collection(String uid, {String? veiculoId}) {
    return _firestore.collection('users').doc(uid).collection('veiculos');
  }

  @override
  Veiculo fromMap(String id, Map<String, dynamic> data, {String? veiculoId}) =>
      Veiculo.fromMap(id, data);

  @override
  Map<String, dynamic> toMap(Veiculo item) => item.toMap();
}
```

- [ ] **Step 5: Rodar o teste e confirmar que passa**

Run: `flutter test test/repositories/veiculo_repository_test.dart`
Expected: `All tests passed!`

---

### Task 18: `ManutencaoRepository` e `AbastecimentoRepository`

**Files:**
- Create: `lib/repositories/manutencao_repository.dart`
- Create: `lib/repositories/abastecimento_repository.dart`
- Test: `test/repositories/manutencao_repository_test.dart`
- Test: `test/repositories/abastecimento_repository_test.dart`

**Interfaces:**
- Consumes: `FirestoreRepository<T>` (Task 17), `Manutencao` (Task 6), `Abastecimento` (Task 7).
- Produces: `class ManutencaoRepository extends FirestoreRepository<Manutencao>`, `class AbastecimentoRepository extends FirestoreRepository<Abastecimento>`, ambos com coleção aninhada sob `users/{uid}/veiculos/{veiculoId}/...`.

- [ ] **Step 1: Escrever os testes (falhando)**

```dart
// test/repositories/manutencao_repository_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/manutencao.dart';
import 'package:revisacar/repositories/manutencao_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ManutencaoRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = ManutencaoRepository(firestore);
  });

  test('add/watchAll são escopados por veiculoId', () async {
    final manutencao = Manutencao(
      id: '',
      veiculoId: 'v1',
      tipo: TipoManutencao.trocaOleo,
      dataRealizada: DateTime(2026, 1, 1),
      kmNaData: 40000,
      custo: 200.0,
      oficina: 'Oficina',
      observacoes: '',
    );

    await repository.add('uid1', manutencao, veiculoId: 'v1');
    final listaV1 = await repository.watchAll('uid1', veiculoId: 'v1').first;
    final listaV2 = await repository.watchAll('uid1', veiculoId: 'v2').first;

    expect(listaV1, hasLength(1));
    expect(listaV1.first.veiculoId, 'v1');
    expect(listaV2, isEmpty);
  });
}
```

```dart
// test/repositories/abastecimento_repository_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/abastecimento.dart';
import 'package:revisacar/repositories/abastecimento_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late AbastecimentoRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = AbastecimentoRepository(firestore);
  });

  test('add/watchAll são escopados por veiculoId', () async {
    final abastecimento = Abastecimento(
      id: '',
      veiculoId: 'v1',
      data: DateTime(2026, 1, 1),
      kmAtual: 40000,
      litros: 30,
      valorTotal: 180,
      tanqueCheio: true,
    );

    await repository.add('uid1', abastecimento, veiculoId: 'v1');
    final lista = await repository.watchAll('uid1', veiculoId: 'v1').first;

    expect(lista, hasLength(1));
    expect(lista.first.veiculoId, 'v1');
  });
}
```

- [ ] **Step 2: Rodar os testes e confirmar que falham**

Run: `flutter test test/repositories/manutencao_repository_test.dart test/repositories/abastecimento_repository_test.dart`
Expected: FAIL — os dois repositórios não existem.

- [ ] **Step 3: Implementar `ManutencaoRepository`**

```dart
// lib/repositories/manutencao_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/manutencao.dart';
import 'firestore_repository.dart';

class ManutencaoRepository extends FirestoreRepository<Manutencao> {
  final FirebaseFirestore _firestore;

  ManutencaoRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  CollectionReference<Map<String, dynamic>> collection(String uid, {String? veiculoId}) {
    assert(veiculoId != null, 'ManutencaoRepository requer veiculoId');
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('veiculos')
        .doc(veiculoId)
        .collection('manutencoes');
  }

  @override
  Manutencao fromMap(String id, Map<String, dynamic> data, {String? veiculoId}) =>
      Manutencao.fromMap(id, veiculoId!, data);

  @override
  Map<String, dynamic> toMap(Manutencao item) => item.toMap();
}
```

- [ ] **Step 4: Implementar `AbastecimentoRepository`**

```dart
// lib/repositories/abastecimento_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/abastecimento.dart';
import 'firestore_repository.dart';

class AbastecimentoRepository extends FirestoreRepository<Abastecimento> {
  final FirebaseFirestore _firestore;

  AbastecimentoRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  CollectionReference<Map<String, dynamic>> collection(String uid, {String? veiculoId}) {
    assert(veiculoId != null, 'AbastecimentoRepository requer veiculoId');
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('veiculos')
        .doc(veiculoId)
        .collection('abastecimentos');
  }

  @override
  Abastecimento fromMap(String id, Map<String, dynamic> data, {String? veiculoId}) =>
      Abastecimento.fromMap(id, veiculoId!, data);

  @override
  Map<String, dynamic> toMap(Abastecimento item) => item.toMap();
}
```

- [ ] **Step 5: Rodar os testes e confirmar que passam**

Run: `flutter test test/repositories/manutencao_repository_test.dart test/repositories/abastecimento_repository_test.dart`
Expected: `All tests passed!`

---

### Task 19: `LembreteRepository` e `ChecklistRepository`

**Files:**
- Create: `lib/repositories/lembrete_repository.dart`
- Create: `lib/repositories/checklist_repository.dart`
- Test: `test/repositories/lembrete_repository_test.dart`
- Test: `test/repositories/checklist_repository_test.dart`

**Interfaces:**
- Consumes: `FirestoreRepository<T>` (Task 17), `LembreteManutencao` (Task 8), `ChecklistItem` (Task 9).
- Produces: `class LembreteRepository extends FirestoreRepository<LembreteManutencao>`, `class ChecklistRepository extends FirestoreRepository<ChecklistItem>`.

- [ ] **Step 1: Escrever os testes (falhando)**

```dart
// test/repositories/lembrete_repository_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/lembrete_manutencao.dart';
import 'package:revisacar/models/manutencao.dart';
import 'package:revisacar/repositories/lembrete_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late LembreteRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = LembreteRepository(firestore);
  });

  test('add/watchAll são escopados por veiculoId', () async {
    final lembrete = LembreteManutencao(
      id: '',
      veiculoId: 'v1',
      tipoManutencao: TipoManutencao.trocaOleo,
      intervaloKm: 10000,
      antecedenciaKm: 500,
      antecedenciaDias: 0,
      intervaloRepeticaoDias: 3,
      ativo: true,
    );

    await repository.add('uid1', lembrete, veiculoId: 'v1');
    final lista = await repository.watchAll('uid1', veiculoId: 'v1').first;

    expect(lista, hasLength(1));
    expect(lista.first.veiculoId, 'v1');
  });
}
```

```dart
// test/repositories/checklist_repository_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/checklist_item.dart';
import 'package:revisacar/repositories/checklist_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ChecklistRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = ChecklistRepository(firestore);
  });

  test('add/update alteram verificado corretamente', () async {
    const item = ChecklistItem(
      id: '',
      veiculoId: 'v1',
      descricao: 'Óleo',
      ordem: 0,
      verificado: false,
    );

    final id = await repository.add('uid1', item, veiculoId: 'v1');
    await repository.update('uid1', id, item.copyWith(verificado: true), veiculoId: 'v1');
    final lista = await repository.watchAll('uid1', veiculoId: 'v1').first;

    expect(lista.first.verificado, isTrue);
  });
}
```

- [ ] **Step 2: Rodar os testes e confirmar que falham**

Run: `flutter test test/repositories/lembrete_repository_test.dart test/repositories/checklist_repository_test.dart`
Expected: FAIL — os dois repositórios não existem.

- [ ] **Step 3: Implementar `LembreteRepository`**

```dart
// lib/repositories/lembrete_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/lembrete_manutencao.dart';
import 'firestore_repository.dart';

class LembreteRepository extends FirestoreRepository<LembreteManutencao> {
  final FirebaseFirestore _firestore;

  LembreteRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  CollectionReference<Map<String, dynamic>> collection(String uid, {String? veiculoId}) {
    assert(veiculoId != null, 'LembreteRepository requer veiculoId');
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('veiculos')
        .doc(veiculoId)
        .collection('lembretes');
  }

  @override
  LembreteManutencao fromMap(String id, Map<String, dynamic> data, {String? veiculoId}) =>
      LembreteManutencao.fromMap(id, veiculoId!, data);

  @override
  Map<String, dynamic> toMap(LembreteManutencao item) => item.toMap();
}
```

- [ ] **Step 4: Implementar `ChecklistRepository`**

```dart
// lib/repositories/checklist_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/checklist_item.dart';
import 'firestore_repository.dart';

class ChecklistRepository extends FirestoreRepository<ChecklistItem> {
  final FirebaseFirestore _firestore;

  ChecklistRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  CollectionReference<Map<String, dynamic>> collection(String uid, {String? veiculoId}) {
    assert(veiculoId != null, 'ChecklistRepository requer veiculoId');
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('veiculos')
        .doc(veiculoId)
        .collection('checklistItems');
  }

  @override
  ChecklistItem fromMap(String id, Map<String, dynamic> data, {String? veiculoId}) =>
      ChecklistItem.fromMap(id, veiculoId!, data);

  @override
  Map<String, dynamic> toMap(ChecklistItem item) => item.toMap();
}
```

- [ ] **Step 5: Rodar os testes e confirmar que passam**

Run: `flutter test test/repositories/lembrete_repository_test.dart test/repositories/checklist_repository_test.dart`
Expected: `All tests passed!`

---

### Task 20: `AppAuthProvider` (Google Sign-In)

**Nota pós-implementação:** a classe foi renomeada de `AuthProvider` para `AppAuthProvider` — o pacote `firebase_auth` já exporta uma classe própria chamada `AuthProvider` (usada por `GoogleAuthProvider`, `EmailAuthProvider`, etc.), e qualquer arquivo do Plano 2 que precisasse importar `firebase_auth` e este provider juntos exigiria `hide AuthProvider`. Renomear elimina o problema de vez. Além disso, a API do `google_sign_in` 7.x instalada é diferente da usada abaixo (`GoogleSignIn()` com construtor público e `.signIn()` não existem mais) — a implementação real usa `GoogleSignIn.instance.initialize()` + `.authenticate()`, documentado em `lib/auth/google_auth_client.dart`. O código abaixo é o desenho original; o código real é a fonte da verdade.

**Files:**
- Create: `lib/auth/google_auth_client.dart`
- Create: `lib/providers/auth_provider.dart`
- Test: `test/providers/auth_provider_test.dart`

**Interfaces:**
- Consumes: `firebase_auth`, `google_sign_in`, `firebase_auth_mocks` (dev, Task 1).
- Produces: `abstract class GoogleAuthClient { Future<AuthCredential?> signIn(); }`, `class GoogleSignInAuthClient implements GoogleAuthClient`, `class AppAuthProvider extends ChangeNotifier` com `user`, `errorMessage`, `signInWithGoogle()`, `signOut()`.

- [ ] **Step 1: Escrever o teste (falhando)**

```dart
// test/providers/auth_provider_test.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/auth/google_auth_client.dart';
import 'package:revisacar/providers/auth_provider.dart';

class _GoogleAuthClientFalso implements GoogleAuthClient {
  final AuthCredential? credencial;
  final Exception? erro;
  _GoogleAuthClientFalso({this.credencial, this.erro});

  @override
  Future<AuthCredential?> signIn() async {
    if (erro != null) throw erro!;
    return credencial;
  }
}

void main() {
  group('AppAuthProvider', () {
    test('user é nulo antes do login', () {
      final auth = MockFirebaseAuth();
      final provider = AppAuthProvider(
        firebaseAuth: auth,
        googleAuthClient: _GoogleAuthClientFalso(),
      );

      expect(provider.user, isNull);
    });

    test('signInWithGoogle autentica e popula user', () async {
      final mockUser = MockUser(uid: 'u1', email: 'jean@example.com');
      final auth = MockFirebaseAuth(mockUser: mockUser);
      final provider = AppAuthProvider(
        firebaseAuth: auth,
        googleAuthClient: _GoogleAuthClientFalso(
          credencial: GoogleAuthProvider.credential(idToken: 'token'),
        ),
      );

      await provider.signInWithGoogle();

      expect(provider.user?.uid, 'u1');
      expect(provider.errorMessage, isNull);
    });

    test('signInWithGoogle não altera user quando usuário cancela (credencial nula)', () async {
      final auth = MockFirebaseAuth();
      final provider = AppAuthProvider(
        firebaseAuth: auth,
        googleAuthClient: _GoogleAuthClientFalso(credencial: null),
      );

      await provider.signInWithGoogle();

      expect(provider.user, isNull);
      expect(provider.errorMessage, isNull);
    });

    test('signInWithGoogle grava mensagem de erro em falha', () async {
      final auth = MockFirebaseAuth();
      final provider = AppAuthProvider(
        firebaseAuth: auth,
        googleAuthClient: _GoogleAuthClientFalso(erro: Exception('sem conexão')),
      );

      await provider.signInWithGoogle();

      expect(provider.errorMessage, isNotNull);
    });

    test('signOut desloga o usuário', () async {
      final mockUser = MockUser(uid: 'u1');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final provider = AppAuthProvider(
        firebaseAuth: auth,
        googleAuthClient: _GoogleAuthClientFalso(),
      );

      await provider.signOut();

      expect(auth.currentUser, isNull);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/providers/auth_provider_test.dart`
Expected: FAIL — `lib/auth/google_auth_client.dart` e `lib/providers/auth_provider.dart` não existem.

- [ ] **Step 3: Implementar `GoogleAuthClient`**

```dart
// lib/auth/google_auth_client.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class GoogleAuthClient {
  Future<AuthCredential?> signIn();
}

class GoogleSignInAuthClient implements GoogleAuthClient {
  final GoogleSignIn _googleSignIn;

  GoogleSignInAuthClient([GoogleSignIn? googleSignIn])
      : _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Future<AuthCredential?> signIn() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    return GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
  }
}
```

- [ ] **Step 4: Implementar `AppAuthProvider`**

```dart
// lib/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../auth/google_auth_client.dart';

class AppAuthProvider extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth;
  final GoogleAuthClient _googleAuthClient;
  User? _user;
  String? _errorMessage;

  AppAuthProvider({FirebaseAuth? firebaseAuth, GoogleAuthClient? googleAuthClient})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleAuthClient = googleAuthClient ?? GoogleSignInAuthClient() {
    _user = _firebaseAuth.currentUser;
    _firebaseAuth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  String? get errorMessage => _errorMessage;

  Future<void> signInWithGoogle() async {
    _errorMessage = null;
    try {
      final credential = await _googleAuthClient.signIn();
      if (credential == null) return;
      await _firebaseAuth.signInWithCredential(credential);
      _user = _firebaseAuth.currentUser;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Não foi possível entrar. Verifique sua conexão e tente novamente.';
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _user = null;
    notifyListeners();
  }
}
```

- [ ] **Step 5: Rodar o teste e confirmar que passa**

Run: `flutter test test/providers/auth_provider_test.dart`
Expected: `All tests passed!`

---

### Task 21: `VeiculoProvider`

**Files:**
- Create: `lib/providers/veiculo_provider.dart`
- Test: `test/providers/veiculo_provider_test.dart`

**Interfaces:**
- Consumes: `VeiculoRepository` (Task 17), `SharedPreferences` (Task 1).
- Produces: `class VeiculoProvider extends ChangeNotifier` com `veiculos`, `veiculoAtivo`, `selecionarVeiculo(String veiculoId)`.

- [ ] **Step 1: Escrever o teste (falhando)**

```dart
// test/providers/veiculo_provider_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/veiculo.dart';
import 'package:revisacar/providers/veiculo_provider.dart';
import 'package:revisacar/repositories/veiculo_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('carrega veículos existentes e seleciona o primeiro como ativo', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = VeiculoRepository(firestore);
    await repository.add(
      'uid1',
      const Veiculo(
        id: '',
        nome: 'Meu HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final provider = VeiculoProvider(repository: repository, prefs: prefs, uid: 'uid1');

    await Future<void>.delayed(Duration.zero);

    expect(provider.veiculos, hasLength(1));
    expect(provider.veiculoAtivo?.nome, 'Meu HB20');
  });

  test('selecionarVeiculo troca o veículo ativo e persiste a escolha', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = VeiculoRepository(firestore);
    final id1 = await repository.add(
      'uid1',
      const Veiculo(
        id: '',
        nome: 'HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
      ),
    );
    final id2 = await repository.add(
      'uid1',
      const Veiculo(
        id: '',
        nome: 'Fiat Mobi',
        modelo: 'Fiat Mobi',
        ano: 2019,
        placa: 'XYZ9Z99',
        kmAtual: 30000,
        tipoVeiculo: TipoVeiculo.carro,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final provider = VeiculoProvider(repository: repository, prefs: prefs, uid: 'uid1');
    await Future<void>.delayed(Duration.zero);

    await provider.selecionarVeiculo(id2);

    expect(provider.veiculoAtivo?.id, id2);
    expect(provider.veiculoAtivo?.id, isNot(id1));
    expect(prefs.getString('active_veiculo_id'), id2);
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/providers/veiculo_provider_test.dart`
Expected: FAIL — `lib/providers/veiculo_provider.dart` não existe.

- [ ] **Step 3: Implementar `VeiculoProvider`**

```dart
// lib/providers/veiculo_provider.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/veiculo.dart';
import '../repositories/veiculo_repository.dart';

class VeiculoProvider extends ChangeNotifier {
  static const _activeVeiculoIdKey = 'active_veiculo_id';

  final VeiculoRepository _repository;
  final SharedPreferences _prefs;
  final String uid;

  List<Veiculo> _veiculos = [];
  String? _veiculoAtivoId;
  StreamSubscription<List<Veiculo>>? _subscription;

  VeiculoProvider({
    required VeiculoRepository repository,
    required SharedPreferences prefs,
    required this.uid,
  })  : _repository = repository,
        _prefs = prefs {
    _veiculoAtivoId = _prefs.getString(_activeVeiculoIdKey);
    _subscription = _repository.watchAll(uid).listen(_onVeiculosChanged);
  }

  List<Veiculo> get veiculos => _veiculos;

  Veiculo? get veiculoAtivo {
    for (final v in _veiculos) {
      if (v.id == _veiculoAtivoId) return v;
    }
    return null;
  }

  void _onVeiculosChanged(List<Veiculo> veiculos) {
    _veiculos = veiculos;
    final aindaExiste = _veiculos.any((v) => v.id == _veiculoAtivoId);
    if (_veiculoAtivoId == null || !aindaExiste) {
      _veiculoAtivoId = _veiculos.isNotEmpty ? _veiculos.first.id : null;
    }
    notifyListeners();
  }

  Future<void> selecionarVeiculo(String veiculoId) async {
    _veiculoAtivoId = veiculoId;
    await _prefs.setString(_activeVeiculoIdKey, veiculoId);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/providers/veiculo_provider_test.dart`
Expected: `All tests passed!`

---

### Task 22: `ManutencaoProvider` e `AbastecimentoProvider`

**Files:**
- Create: `lib/providers/manutencao_provider.dart`
- Create: `lib/providers/abastecimento_provider.dart`
- Test: `test/providers/manutencao_provider_test.dart`
- Test: `test/providers/abastecimento_provider_test.dart`

**Interfaces:**
- Consumes: `ManutencaoRepository`, `AbastecimentoRepository` (Task 18).
- Produces: `class ManutencaoProvider extends ChangeNotifier` com `manutencoes`, `escutarVeiculo(String veiculoId)`, `adicionar`, `atualizar`, `remover`; `class AbastecimentoProvider` no mesmo formato para `Abastecimento`.

- [ ] **Step 1: Escrever os testes (falhando)**

```dart
// test/providers/manutencao_provider_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/manutencao.dart';
import 'package:revisacar/providers/manutencao_provider.dart';
import 'package:revisacar/repositories/manutencao_repository.dart';

void main() {
  test('escutarVeiculo carrega as manutenções daquele veículo', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = ManutencaoRepository(firestore);
    final provider = ManutencaoProvider(repository: repository, uid: 'uid1');

    provider.escutarVeiculo('v1');
    await provider.adicionar(Manutencao(
      id: '',
      veiculoId: 'v1',
      tipo: TipoManutencao.trocaOleo,
      dataRealizada: DateTime(2026, 1, 1),
      kmNaData: 40000,
      custo: 200.0,
      oficina: 'Oficina',
      observacoes: '',
    ));
    await Future<void>.delayed(Duration.zero);

    expect(provider.manutencoes, hasLength(1));
  });
}
```

```dart
// test/providers/abastecimento_provider_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/abastecimento.dart';
import 'package:revisacar/providers/abastecimento_provider.dart';
import 'package:revisacar/repositories/abastecimento_repository.dart';

void main() {
  test('escutarVeiculo carrega os abastecimentos daquele veículo', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = AbastecimentoRepository(firestore);
    final provider = AbastecimentoProvider(repository: repository, uid: 'uid1');

    provider.escutarVeiculo('v1');
    await provider.adicionar(Abastecimento(
      id: '',
      veiculoId: 'v1',
      data: DateTime(2026, 1, 1),
      kmAtual: 40000,
      litros: 30,
      valorTotal: 180,
      tanqueCheio: true,
    ));
    await Future<void>.delayed(Duration.zero);

    expect(provider.abastecimentos, hasLength(1));
  });
}
```

- [ ] **Step 2: Rodar os testes e confirmar que falham**

Run: `flutter test test/providers/manutencao_provider_test.dart test/providers/abastecimento_provider_test.dart`
Expected: FAIL — os dois providers não existem.

- [ ] **Step 3: Implementar `ManutencaoProvider`**

```dart
// lib/providers/manutencao_provider.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/manutencao.dart';
import '../repositories/manutencao_repository.dart';

class ManutencaoProvider extends ChangeNotifier {
  final ManutencaoRepository _repository;
  final String uid;

  String? _veiculoId;
  List<Manutencao> _manutencoes = [];
  StreamSubscription<List<Manutencao>>? _subscription;

  ManutencaoProvider({required ManutencaoRepository repository, required this.uid})
      : _repository = repository;

  List<Manutencao> get manutencoes => _manutencoes;

  void escutarVeiculo(String veiculoId) {
    if (_veiculoId == veiculoId) return;
    _veiculoId = veiculoId;
    _subscription?.cancel();
    _subscription = _repository.watchAll(uid, veiculoId: veiculoId).listen((lista) {
      _manutencoes = lista;
      notifyListeners();
    });
  }

  Future<void> adicionar(Manutencao manutencao) {
    return _repository.add(uid, manutencao, veiculoId: _veiculoId);
  }

  Future<void> atualizar(Manutencao manutencao) {
    return _repository.update(uid, manutencao.id, manutencao, veiculoId: _veiculoId);
  }

  Future<void> remover(String id) {
    return _repository.delete(uid, id, veiculoId: _veiculoId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 4: Implementar `AbastecimentoProvider`**

```dart
// lib/providers/abastecimento_provider.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/abastecimento.dart';
import '../repositories/abastecimento_repository.dart';

class AbastecimentoProvider extends ChangeNotifier {
  final AbastecimentoRepository _repository;
  final String uid;

  String? _veiculoId;
  List<Abastecimento> _abastecimentos = [];
  StreamSubscription<List<Abastecimento>>? _subscription;

  AbastecimentoProvider({required AbastecimentoRepository repository, required this.uid})
      : _repository = repository;

  List<Abastecimento> get abastecimentos => _abastecimentos;

  void escutarVeiculo(String veiculoId) {
    if (_veiculoId == veiculoId) return;
    _veiculoId = veiculoId;
    _subscription?.cancel();
    _subscription = _repository.watchAll(uid, veiculoId: veiculoId).listen((lista) {
      _abastecimentos = lista;
      notifyListeners();
    });
  }

  Future<void> adicionar(Abastecimento abastecimento) {
    return _repository.add(uid, abastecimento, veiculoId: _veiculoId);
  }

  Future<void> atualizar(Abastecimento abastecimento) {
    return _repository.update(uid, abastecimento.id, abastecimento, veiculoId: _veiculoId);
  }

  Future<void> remover(String id) {
    return _repository.delete(uid, id, veiculoId: _veiculoId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 5: Rodar os testes e confirmar que passam**

Run: `flutter test test/providers/manutencao_provider_test.dart test/providers/abastecimento_provider_test.dart`
Expected: `All tests passed!`

---

### Task 23: `LembreteProvider` e `ChecklistProvider`

**Files:**
- Create: `lib/providers/lembrete_provider.dart`
- Create: `lib/providers/checklist_provider.dart`
- Test: `test/providers/lembrete_provider_test.dart`
- Test: `test/providers/checklist_provider_test.dart`

**Interfaces:**
- Consumes: `LembreteRepository`, `ChecklistRepository` (Task 19).
- Produces: `class LembreteProvider extends ChangeNotifier` (mesmo formato de Task 22); `class ChecklistProvider extends ChangeNotifier` com `checklistItems`, `escutarVeiculo`, `adicionar`, `remover`, `alternarVerificado(ChecklistItem item)`, `resetarTodos()`.

- [ ] **Step 1: Escrever os testes (falhando)**

```dart
// test/providers/lembrete_provider_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/lembrete_manutencao.dart';
import 'package:revisacar/models/manutencao.dart';
import 'package:revisacar/providers/lembrete_provider.dart';
import 'package:revisacar/repositories/lembrete_repository.dart';

void main() {
  test('escutarVeiculo carrega os lembretes daquele veículo', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = LembreteRepository(firestore);
    final provider = LembreteProvider(repository: repository, uid: 'uid1');

    provider.escutarVeiculo('v1');
    await provider.adicionar(LembreteManutencao(
      id: '',
      veiculoId: 'v1',
      tipoManutencao: TipoManutencao.trocaOleo,
      intervaloKm: 10000,
      antecedenciaKm: 500,
      antecedenciaDias: 0,
      intervaloRepeticaoDias: 3,
      ativo: true,
    ));
    await Future<void>.delayed(Duration.zero);

    expect(provider.lembretes, hasLength(1));
  });
}
```

```dart
// test/providers/checklist_provider_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/checklist_item.dart';
import 'package:revisacar/providers/checklist_provider.dart';
import 'package:revisacar/repositories/checklist_repository.dart';

void main() {
  test('alternarVerificado marca e desmarca um item', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = ChecklistRepository(firestore);
    final provider = ChecklistProvider(repository: repository, uid: 'uid1');

    provider.escutarVeiculo('v1');
    await provider.adicionar(const ChecklistItem(
      id: '',
      veiculoId: 'v1',
      descricao: 'Óleo',
      ordem: 0,
      verificado: false,
    ));
    await Future<void>.delayed(Duration.zero);

    await provider.alternarVerificado(provider.checklistItems.first);
    await Future<void>.delayed(Duration.zero);

    expect(provider.checklistItems.first.verificado, isTrue);
  });

  test('resetarTodos desmarca todos os itens verificados', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = ChecklistRepository(firestore);
    final provider = ChecklistProvider(repository: repository, uid: 'uid1');

    provider.escutarVeiculo('v1');
    await provider.adicionar(const ChecklistItem(
      id: '',
      veiculoId: 'v1',
      descricao: 'Óleo',
      ordem: 0,
      verificado: true,
    ));
    await Future<void>.delayed(Duration.zero);

    await provider.resetarTodos();
    await Future<void>.delayed(Duration.zero);

    expect(provider.checklistItems.every((i) => !i.verificado), isTrue);
  });
}
```

- [ ] **Step 2: Rodar os testes e confirmar que falham**

Run: `flutter test test/providers/lembrete_provider_test.dart test/providers/checklist_provider_test.dart`
Expected: FAIL — os dois providers não existem.

- [ ] **Step 3: Implementar `LembreteProvider`**

```dart
// lib/providers/lembrete_provider.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/lembrete_manutencao.dart';
import '../repositories/lembrete_repository.dart';

class LembreteProvider extends ChangeNotifier {
  final LembreteRepository _repository;
  final String uid;

  String? _veiculoId;
  List<LembreteManutencao> _lembretes = [];
  StreamSubscription<List<LembreteManutencao>>? _subscription;

  LembreteProvider({required LembreteRepository repository, required this.uid})
      : _repository = repository;

  List<LembreteManutencao> get lembretes => _lembretes;

  void escutarVeiculo(String veiculoId) {
    if (_veiculoId == veiculoId) return;
    _veiculoId = veiculoId;
    _subscription?.cancel();
    _subscription = _repository.watchAll(uid, veiculoId: veiculoId).listen((lista) {
      _lembretes = lista;
      notifyListeners();
    });
  }

  Future<void> adicionar(LembreteManutencao lembrete) {
    return _repository.add(uid, lembrete, veiculoId: _veiculoId);
  }

  Future<void> atualizar(LembreteManutencao lembrete) {
    return _repository.update(uid, lembrete.id, lembrete, veiculoId: _veiculoId);
  }

  Future<void> remover(String id) {
    return _repository.delete(uid, id, veiculoId: _veiculoId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 4: Implementar `ChecklistProvider`**

```dart
// lib/providers/checklist_provider.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/checklist_item.dart';
import '../repositories/checklist_repository.dart';

class ChecklistProvider extends ChangeNotifier {
  final ChecklistRepository _repository;
  final String uid;

  String? _veiculoId;
  List<ChecklistItem> _checklistItems = [];
  StreamSubscription<List<ChecklistItem>>? _subscription;

  ChecklistProvider({required ChecklistRepository repository, required this.uid})
      : _repository = repository;

  List<ChecklistItem> get checklistItems => _checklistItems;

  void escutarVeiculo(String veiculoId) {
    if (_veiculoId == veiculoId) return;
    _veiculoId = veiculoId;
    _subscription?.cancel();
    _subscription = _repository.watchAll(uid, veiculoId: veiculoId).listen((lista) {
      _checklistItems = lista;
      notifyListeners();
    });
  }

  Future<void> adicionar(ChecklistItem item) {
    return _repository.add(uid, item, veiculoId: _veiculoId);
  }

  Future<void> remover(String id) {
    return _repository.delete(uid, id, veiculoId: _veiculoId);
  }

  Future<void> alternarVerificado(ChecklistItem item) {
    return _repository.update(
      uid,
      item.id,
      item.copyWith(verificado: !item.verificado),
      veiculoId: _veiculoId,
    );
  }

  Future<void> resetarTodos() async {
    for (final item in _checklistItems) {
      if (item.verificado) {
        await _repository.update(uid, item.id, item.copyWith(verificado: false),
            veiculoId: _veiculoId);
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 5: Rodar os testes e confirmar que passam**

Run: `flutter test test/providers/lembrete_provider_test.dart test/providers/checklist_provider_test.dart`
Expected: `All tests passed!`

---

### Task 24: Atualização automática de `Veiculo.kmAtual` (Decisão 3 da spec)

Implementa a regra: "o `kmAtual` do veículo é atualizado automaticamente para o maior valor entre o atual e o km informado em qualquer novo registro de manutenção ou abastecimento" — hoje nenhuma task anterior faz isso.

**Files:**
- Modify: `lib/providers/manutencao_provider.dart`
- Modify: `lib/providers/abastecimento_provider.dart`
- Modify: `test/providers/manutencao_provider_test.dart`
- Modify: `test/providers/abastecimento_provider_test.dart`

**Interfaces:**
- Consumes: `VeiculoRepository.get(uid, id)` e `.update(uid, id, veiculo)` (Task 17).
- Produces: `ManutencaoProvider` e `AbastecimentoProvider` passam a exigir `VeiculoRepository veiculoRepository` no construtor; `adicionar(...)` de ambos bumpa `Veiculo.kmAtual` quando o km do novo registro é maior que o atual.

- [ ] **Step 1: Acrescentar os testes (falhando) e corrigir os testes já existentes**

Esta task muda o construtor de `ManutencaoProvider` e `AbastecimentoProvider` para exigir `veiculoRepository` — os testes escritos na Task 22 quebram se não forem atualizados.

Em `test/providers/manutencao_provider_test.dart`, atualizar o teste já existente (da Task 22) para passar o novo parâmetro:

```dart
import 'package:revisacar/models/veiculo.dart';
import 'package:revisacar/repositories/veiculo_repository.dart';
// ... (mantém os imports já existentes da Task 22)

  test('escutarVeiculo carrega as manutenções daquele veículo', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = ManutencaoRepository(firestore);
    final provider = ManutencaoProvider(
      repository: repository,
      veiculoRepository: VeiculoRepository(firestore),
      uid: 'uid1',
    );
    // ... resto do teste inalterado
```

Em `test/providers/abastecimento_provider_test.dart`, fazer o mesmo ajuste no teste da Task 22 (acrescentar `veiculoRepository: VeiculoRepository(firestore),` na construção do `AbastecimentoProvider`, e importar `Veiculo`/`VeiculoRepository`).

Em seguida, adicionar os testes novos. Em `test/providers/manutencao_provider_test.dart`:

```dart
  test('adicionar atualiza Veiculo.kmAtual quando o km da manutenção é maior', () async {
    final firestore = FakeFirebaseFirestore();
    final veiculoRepository = VeiculoRepository(firestore);
    final veiculoId = await veiculoRepository.add(
      'uid1',
      const Veiculo(
        id: '',
        nome: 'HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 40000,
        tipoVeiculo: TipoVeiculo.carro,
      ),
    );
    final repository = ManutencaoRepository(firestore);
    final provider = ManutencaoProvider(
      repository: repository,
      veiculoRepository: veiculoRepository,
      uid: 'uid1',
    );
    provider.escutarVeiculo(veiculoId);

    await provider.adicionar(Manutencao(
      id: '',
      veiculoId: veiculoId,
      tipo: TipoManutencao.trocaOleo,
      dataRealizada: DateTime(2026, 1, 1),
      kmNaData: 41000,
      custo: 200.0,
      oficina: 'Oficina',
      observacoes: '',
    ));

    final veiculoAtualizado = await veiculoRepository.get('uid1', veiculoId);
    expect(veiculoAtualizado?.kmAtual, 41000);
  });

  test('adicionar não reduz Veiculo.kmAtual quando o km da manutenção é menor (registro atrasado)',
      () async {
    final firestore = FakeFirebaseFirestore();
    final veiculoRepository = VeiculoRepository(firestore);
    final veiculoId = await veiculoRepository.add(
      'uid1',
      const Veiculo(
        id: '',
        nome: 'HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
      ),
    );
    final repository = ManutencaoRepository(firestore);
    final provider = ManutencaoProvider(
      repository: repository,
      veiculoRepository: veiculoRepository,
      uid: 'uid1',
    );
    provider.escutarVeiculo(veiculoId);

    await provider.adicionar(Manutencao(
      id: '',
      veiculoId: veiculoId,
      tipo: TipoManutencao.trocaOleo,
      dataRealizada: DateTime(2025, 12, 1),
      kmNaData: 42000,
      custo: 200.0,
      oficina: 'Oficina',
      observacoes: '',
    ));

    final veiculoAtualizado = await veiculoRepository.get('uid1', veiculoId);
    expect(veiculoAtualizado?.kmAtual, 45000);
  });
```

Adicionar os imports necessários (`Veiculo`, `TipoVeiculo`, `VeiculoRepository`) no topo do arquivo de teste.

Adicionar a `test/providers/abastecimento_provider_test.dart` um teste equivalente:

```dart
  test('adicionar atualiza Veiculo.kmAtual quando o km do abastecimento é maior', () async {
    final firestore = FakeFirebaseFirestore();
    final veiculoRepository = VeiculoRepository(firestore);
    final veiculoId = await veiculoRepository.add(
      'uid1',
      const Veiculo(
        id: '',
        nome: 'HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 40000,
        tipoVeiculo: TipoVeiculo.carro,
      ),
    );
    final repository = AbastecimentoRepository(firestore);
    final provider = AbastecimentoProvider(
      repository: repository,
      veiculoRepository: veiculoRepository,
      uid: 'uid1',
    );
    provider.escutarVeiculo(veiculoId);

    await provider.adicionar(Abastecimento(
      id: '',
      veiculoId: veiculoId,
      data: DateTime(2026, 1, 1),
      kmAtual: 40500,
      litros: 30,
      valorTotal: 180,
      tanqueCheio: true,
    ));

    final veiculoAtualizado = await veiculoRepository.get('uid1', veiculoId);
    expect(veiculoAtualizado?.kmAtual, 40500);
  });
```

Adicionar os imports necessários (`Veiculo`, `TipoVeiculo`, `VeiculoRepository`) no topo desse arquivo também.

- [ ] **Step 2: Rodar os testes e confirmar que falham**

Run: `flutter test test/providers/manutencao_provider_test.dart test/providers/abastecimento_provider_test.dart`
Expected: FAIL — `ManutencaoProvider`/`AbastecimentoProvider` não aceitam o parâmetro `veiculoRepository`.

- [ ] **Step 3: Atualizar `ManutencaoProvider`**

Em `lib/providers/manutencao_provider.dart`, importar `veiculo_repository.dart` e alterar a classe:

```dart
import '../repositories/veiculo_repository.dart';

class ManutencaoProvider extends ChangeNotifier {
  final ManutencaoRepository _repository;
  final VeiculoRepository _veiculoRepository;
  final String uid;

  String? _veiculoId;
  List<Manutencao> _manutencoes = [];
  StreamSubscription<List<Manutencao>>? _subscription;

  ManutencaoProvider({
    required ManutencaoRepository repository,
    required VeiculoRepository veiculoRepository,
    required this.uid,
  })  : _repository = repository,
        _veiculoRepository = veiculoRepository;

  List<Manutencao> get manutencoes => _manutencoes;

  void escutarVeiculo(String veiculoId) {
    if (_veiculoId == veiculoId) return;
    _veiculoId = veiculoId;
    _subscription?.cancel();
    _subscription = _repository.watchAll(uid, veiculoId: veiculoId).listen((lista) {
      _manutencoes = lista;
      notifyListeners();
    });
  }

  Future<void> adicionar(Manutencao manutencao) async {
    await _repository.add(uid, manutencao, veiculoId: _veiculoId);
    await _atualizarKmSeNecessario(manutencao.kmNaData);
  }

  Future<void> atualizar(Manutencao manutencao) {
    return _repository.update(uid, manutencao.id, manutencao, veiculoId: _veiculoId);
  }

  Future<void> remover(String id) {
    return _repository.delete(uid, id, veiculoId: _veiculoId);
  }

  Future<void> _atualizarKmSeNecessario(int km) async {
    if (_veiculoId == null) return;
    final veiculo = await _veiculoRepository.get(uid, _veiculoId!);
    if (veiculo != null && km > veiculo.kmAtual) {
      await _veiculoRepository.update(uid, _veiculoId!, veiculo.copyWith(kmAtual: km));
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 4: Atualizar `AbastecimentoProvider`**

Em `lib/providers/abastecimento_provider.dart`, importar `veiculo_repository.dart` e alterar a classe:

```dart
import '../repositories/veiculo_repository.dart';

class AbastecimentoProvider extends ChangeNotifier {
  final AbastecimentoRepository _repository;
  final VeiculoRepository _veiculoRepository;
  final String uid;

  String? _veiculoId;
  List<Abastecimento> _abastecimentos = [];
  StreamSubscription<List<Abastecimento>>? _subscription;

  AbastecimentoProvider({
    required AbastecimentoRepository repository,
    required VeiculoRepository veiculoRepository,
    required this.uid,
  })  : _repository = repository,
        _veiculoRepository = veiculoRepository;

  List<Abastecimento> get abastecimentos => _abastecimentos;

  void escutarVeiculo(String veiculoId) {
    if (_veiculoId == veiculoId) return;
    _veiculoId = veiculoId;
    _subscription?.cancel();
    _subscription = _repository.watchAll(uid, veiculoId: veiculoId).listen((lista) {
      _abastecimentos = lista;
      notifyListeners();
    });
  }

  Future<void> adicionar(Abastecimento abastecimento) async {
    await _repository.add(uid, abastecimento, veiculoId: _veiculoId);
    await _atualizarKmSeNecessario(abastecimento.kmAtual);
  }

  Future<void> atualizar(Abastecimento abastecimento) {
    return _repository.update(uid, abastecimento.id, abastecimento, veiculoId: _veiculoId);
  }

  Future<void> remover(String id) {
    return _repository.delete(uid, id, veiculoId: _veiculoId);
  }

  Future<void> _atualizarKmSeNecessario(int km) async {
    if (_veiculoId == null) return;
    final veiculo = await _veiculoRepository.get(uid, _veiculoId!);
    if (veiculo != null && km > veiculo.kmAtual) {
      await _veiculoRepository.update(uid, _veiculoId!, veiculo.copyWith(kmAtual: km));
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 5: Rodar os testes e confirmar que passam**

Run: `flutter test test/providers/manutencao_provider_test.dart test/providers/abastecimento_provider_test.dart`
Expected: `All tests passed!`

- [ ] **Step 6: Rodar a suíte completa de testes do plano**

Run: `flutter test`
Expected: `All tests passed!` (todas as tasks 5–24).

---

## Próximo passo

Com esta fundação pronta e testada, o Plano 2 constrói: `AuthGate`, tela de Login, lista de veículos, telas de detalhe/formulários, upload de foto (`image_picker` + Storage), Dashboard (`fl_chart`), Checklist, Configurações (exportação com `path_provider`/`share_plus` + sign-out), e a integração do `LembreteService` com `flutter_local_notifications` — tudo por cima dos models/services/repositories/providers construídos aqui.
