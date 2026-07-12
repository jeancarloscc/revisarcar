# Lembrete Automático ao Registrar Manutenção Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Quando o usuário registra uma manutenção nova de um tipo que ainda não tem lembrete configurado naquele veículo, o app cria automaticamente uma regra de lembrete (`LembreteManutencao`), usando um intervalo padrão por tipo (baseado no manual do HB20) que pode ser personalizado por veículo.

**Architecture:** Uma tabela const de intervalos padrão por `TipoManutencao` + um campo `intervalosPersonalizados` em `Veiculo` (override opcional por veículo, editável na tela de edição do veículo) são combinados por uma função pura `intervaloEfetivo`. `ManutencaoProvider.adicionar()` chama essa função depois de salvar a manutenção e, se não existir nenhum lembrete daquele tipo ainda, cria um automaticamente via um novo método de leitura pontual (`getAll`) no repositório genérico.

**Tech Stack:** Flutter/Dart, Firebase Firestore (`cloud_firestore`), `provider`, testes com `flutter_test` + `fake_cloud_firestore`.

## Global Constraints

- Tipo `outro` nunca entra na tabela de padrões, nunca aparece na tela de configuração, e nunca gera lembrete automático.
- A criação automática só acontece em `ManutencaoProvider.adicionar()` (manutenção nova) — `atualizar()` (edição) nunca cria/mexe em lembretes.
- Lembrete automático só é criado se ainda não existir **nenhum** lembrete daquele tipo naquele veículo (independente de estar ativo ou não).
- Valores fixos do lembrete criado automaticamente: `antecedenciaKm: 500`, `antecedenciaDias: 15`, `intervaloRepeticaoDias: 3`, `ativo: true` — não aparecem na tela de configuração do veículo, só editáveis depois na aba Lembretes.
- Conversão meses → dias: `dias = meses * 30` (mesma unidade de `LembreteManutencao.intervaloDias`).
- Tabela de intervalos padrão (km / meses, `—` = sem valor):
  - `revisao`: 10000 km / 12 meses
  - `trocaOleo`: 10000 km / 12 meses
  - `trocaFiltro`: 40000 km / 48 meses
  - `pneusRodizio`: 10000 km / —
  - `bateria`: — / 24 meses
  - `palhetas`: — / 12 meses
  - `arCondicionado`: 20000 km / 24 meses
  - `alinhamentoBalanceamento`: 10000 km / —
- Sem widget tests neste projeto (`test/` só tem `models/`, `services/`, `repositories/`, `providers/`, e agora `utils/`) — não criar `test/screens`.
- Testes de repository/provider usam `fake_cloud_firestore` (`FakeFirebaseFirestore`), nunca mocks manuais do Firestore.

---

### Task 1: Modelo `IntervaloManutencao`

**Files:**
- Create: `lib/models/intervalo_manutencao.dart`
- Test: `test/models/intervalo_manutencao_test.dart`

**Interfaces:**
- Produces: `class IntervaloManutencao { final int? km; final int? dias; const IntervaloManutencao({this.km, this.dias}); bool get vazio; factory IntervaloManutencao.fromMap(Map<String, dynamic> data); Map<String, dynamic> toMap(); }` com `==`/`hashCode` por valor.

- [ ] **Step 1: Escrever o teste que falha**

Criar `test/models/intervalo_manutencao_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/intervalo_manutencao.dart';

void main() {
  group('IntervaloManutencao', () {
    test('fromMap/toMap round-trip preserva km e dias', () {
      const intervalo = IntervaloManutencao(km: 10000, dias: 360);

      final map = intervalo.toMap();
      final restaurado = IntervaloManutencao.fromMap(map);

      expect(restaurado, intervalo);
    });

    test('vazio é true quando km e dias são nulos', () {
      const intervalo = IntervaloManutencao();
      expect(intervalo.vazio, isTrue);
    });

    test('vazio é false quando pelo menos um campo está preenchido', () {
      const comKm = IntervaloManutencao(km: 10000);
      const comDias = IntervaloManutencao(dias: 360);
      expect(comKm.vazio, isFalse);
      expect(comDias.vazio, isFalse);
    });

    test('dois IntervaloManutencao com os mesmos valores são iguais', () {
      const a = IntervaloManutencao(km: 10000, dias: 360);
      const b = IntervaloManutencao(km: 10000, dias: 360);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/models/intervalo_manutencao_test.dart`
Expected: FAIL — `Error: Error when reading 'lib/models/intervalo_manutencao.dart': No such file or directory` (ou `Target of URI doesn't exist`).

- [ ] **Step 3: Implementar `IntervaloManutencao`**

Criar `lib/models/intervalo_manutencao.dart`:

```dart
class IntervaloManutencao {
  final int? km;
  final int? dias;

  const IntervaloManutencao({this.km, this.dias});

  bool get vazio => km == null && dias == null;

  factory IntervaloManutencao.fromMap(Map<String, dynamic> data) {
    return IntervaloManutencao(
      km: data['km'] as int?,
      dias: data['dias'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'km': km, 'dias': dias};
  }

  @override
  bool operator ==(Object other) =>
      other is IntervaloManutencao && other.km == km && other.dias == dias;

  @override
  int get hashCode => Object.hash(km, dias);
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/models/intervalo_manutencao_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/models/intervalo_manutencao.dart test/models/intervalo_manutencao_test.dart
git commit -m "feat: adiciona modelo IntervaloManutencao"
```

---

### Task 2: Campo `intervalosPersonalizados` em `Veiculo`

**Files:**
- Modify: `lib/models/veiculo.dart`
- Test: `test/models/veiculo_test.dart`

**Interfaces:**
- Consumes: `IntervaloManutencao` (Task 1), `TipoManutencao` (já existe em `lib/models/manutencao.dart`).
- Produces: `Veiculo.intervalosPersonalizados` (`Map<TipoManutencao, IntervaloManutencao>`, default `{}`), presente em `fromMap`, `toMap`, `copyWith`, `==`, `hashCode`.

- [ ] **Step 1: Escrever o teste que falha**

Adicionar ao final do `group('Veiculo', ...)` em `test/models/veiculo_test.dart` (antes do `});` final):

```dart
    test('intervalosPersonalizados: fromMap/toMap round-trip preserva os valores', () {
      const veiculo = Veiculo(
        id: 'v1',
        nome: 'Meu HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
        intervalosPersonalizados: {
          TipoManutencao.trocaOleo: IntervaloManutencao(km: 8000, dias: 180),
          TipoManutencao.bateria: IntervaloManutencao(dias: 720),
        },
      );

      final map = veiculo.toMap();
      final restaurado = Veiculo.fromMap('v1', map);

      expect(restaurado, veiculo);
      expect(restaurado.intervalosPersonalizados[TipoManutencao.trocaOleo],
          const IntervaloManutencao(km: 8000, dias: 180));
    });

    test('intervalosPersonalizados é vazio quando ausente do map', () {
      final map = {
        'nome': 'X',
        'modelo': 'Y',
        'ano': 2020,
        'placa': 'ZZZ',
        'kmAtual': 0,
        'tipoVeiculo': 'carro',
      };

      final veiculo = Veiculo.fromMap('v1', map);

      expect(veiculo.intervalosPersonalizados, isEmpty);
    });
```

Adicionar os imports necessários no topo do arquivo de teste:

```dart
import 'package:revisacar/models/intervalo_manutencao.dart';
import 'package:revisacar/models/manutencao.dart';
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/models/veiculo_test.dart`
Expected: FAIL — `The named parameter 'intervalosPersonalizados' isn't defined` (erro de compilação).

- [ ] **Step 3: Implementar o campo em `Veiculo`**

Editar `lib/models/veiculo.dart` (arquivo completo após a mudança):

```dart
import 'intervalo_manutencao.dart';
import 'manutencao.dart';

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
  final Map<TipoManutencao, IntervaloManutencao> intervalosPersonalizados;

  const Veiculo({
    required this.id,
    required this.nome,
    required this.modelo,
    required this.ano,
    required this.placa,
    required this.kmAtual,
    required this.tipoVeiculo,
    this.fotoUrl,
    this.intervalosPersonalizados = const {},
  });

  factory Veiculo.fromMap(String id, Map<String, dynamic> data) {
    final intervalosMap = data['intervalosPersonalizados'] as Map<String, dynamic>?;
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
      intervalosPersonalizados: intervalosMap == null
          ? const {}
          : intervalosMap.map(
              (key, value) => MapEntry(
                TipoManutencao.values.firstWhere(
                  (t) => t.name == key,
                  orElse: () => TipoManutencao.outro,
                ),
                IntervaloManutencao.fromMap(Map<String, dynamic>.from(value as Map)),
              ),
            ),
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
      'intervalosPersonalizados':
          intervalosPersonalizados.map((tipo, intervalo) => MapEntry(tipo.name, intervalo.toMap())),
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
    Map<TipoManutencao, IntervaloManutencao>? intervalosPersonalizados,
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
      intervalosPersonalizados: intervalosPersonalizados ?? this.intervalosPersonalizados,
    );
  }

  static bool _intervalosIguais(
    Map<TipoManutencao, IntervaloManutencao> a,
    Map<TipoManutencao, IntervaloManutencao> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static int _intervalosHash(Map<TipoManutencao, IntervaloManutencao> mapa) {
    var hash = 0;
    for (final entry in mapa.entries) {
      hash ^= Object.hash(entry.key, entry.value);
    }
    return hash;
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
      other.fotoUrl == fotoUrl &&
      _intervalosIguais(other.intervalosPersonalizados, intervalosPersonalizados);

  @override
  int get hashCode => Object.hash(
      id, nome, modelo, ano, placa, kmAtual, tipoVeiculo, fotoUrl, _intervalosHash(intervalosPersonalizados));
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/models/veiculo_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Rodar análise estática**

Run: `flutter analyze lib/models/veiculo.dart test/models/veiculo_test.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/models/veiculo.dart test/models/veiculo_test.dart
git commit -m "feat: adiciona intervalosPersonalizados ao modelo Veiculo"
```

---

### Task 3: Tabela de intervalos padrão + `intervaloEfetivo`

**Files:**
- Create: `lib/utils/intervalo_padrao_manutencao.dart`
- Test: `test/utils/intervalo_padrao_manutencao_test.dart`

**Interfaces:**
- Consumes: `IntervaloManutencao` (Task 1), `Veiculo.intervalosPersonalizados` (Task 2), `TipoManutencao`.
- Produces: `const Map<TipoManutencao, IntervaloManutencao> intervalosPadraoManutencao;` e `IntervaloManutencao? intervaloEfetivo(Veiculo veiculo, TipoManutencao tipo)`.

- [ ] **Step 1: Escrever o teste que falha**

Criar `test/utils/intervalo_padrao_manutencao_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/intervalo_manutencao.dart';
import 'package:revisacar/models/manutencao.dart';
import 'package:revisacar/models/veiculo.dart';
import 'package:revisacar/utils/intervalo_padrao_manutencao.dart';

Veiculo _veiculo({Map<TipoManutencao, IntervaloManutencao> intervalos = const {}}) {
  return Veiculo(
    id: 'v1',
    nome: 'Meu HB20',
    modelo: 'Hyundai HB20',
    ano: 2020,
    placa: 'ABC1D23',
    kmAtual: 45000,
    tipoVeiculo: TipoVeiculo.carro,
    intervalosPersonalizados: intervalos,
  );
}

void main() {
  group('intervaloEfetivo', () {
    test('retorna null para TipoManutencao.outro', () {
      expect(intervaloEfetivo(_veiculo(), TipoManutencao.outro), isNull);
    });

    test('cai no padrão da tabela quando o veículo não tem override', () {
      final intervalo = intervaloEfetivo(_veiculo(), TipoManutencao.trocaOleo);
      expect(intervalo, intervalosPadraoManutencao[TipoManutencao.trocaOleo]);
      expect(intervalo?.km, 10000);
      expect(intervalo?.dias, 360);
    });

    test('usa o override do veículo quando presente', () {
      final veiculo = _veiculo(intervalos: const {
        TipoManutencao.trocaOleo: IntervaloManutencao(km: 8000, dias: 180),
      });

      final intervalo = intervaloEfetivo(veiculo, TipoManutencao.trocaOleo);

      expect(intervalo, const IntervaloManutencao(km: 8000, dias: 180));
    });

    test('override com km e dias nulos conta como vazio (desliga o tipo)', () {
      final veiculo = _veiculo(intervalos: const {
        TipoManutencao.trocaOleo: IntervaloManutencao(),
      });

      final intervalo = intervaloEfetivo(veiculo, TipoManutencao.trocaOleo);

      expect(intervalo?.vazio, isTrue);
    });

    test('tabela padrão não tem entrada para Outro', () {
      expect(intervalosPadraoManutencao.containsKey(TipoManutencao.outro), isFalse);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/utils/intervalo_padrao_manutencao_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:revisacar/utils/intervalo_padrao_manutencao.dart'`.

- [ ] **Step 3: Implementar a tabela e `intervaloEfetivo`**

Criar `lib/utils/intervalo_padrao_manutencao.dart`:

```dart
import '../models/intervalo_manutencao.dart';
import '../models/manutencao.dart';
import '../models/veiculo.dart';

const Map<TipoManutencao, IntervaloManutencao> intervalosPadraoManutencao = {
  TipoManutencao.revisao: IntervaloManutencao(km: 10000, dias: 360),
  TipoManutencao.trocaOleo: IntervaloManutencao(km: 10000, dias: 360),
  TipoManutencao.trocaFiltro: IntervaloManutencao(km: 40000, dias: 1440),
  TipoManutencao.pneusRodizio: IntervaloManutencao(km: 10000),
  TipoManutencao.bateria: IntervaloManutencao(dias: 720),
  TipoManutencao.palhetas: IntervaloManutencao(dias: 360),
  TipoManutencao.arCondicionado: IntervaloManutencao(km: 20000, dias: 720),
  TipoManutencao.alinhamentoBalanceamento: IntervaloManutencao(km: 10000),
};

IntervaloManutencao? intervaloEfetivo(Veiculo veiculo, TipoManutencao tipo) {
  if (tipo == TipoManutencao.outro) return null;
  return veiculo.intervalosPersonalizados[tipo] ?? intervalosPadraoManutencao[tipo];
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/utils/intervalo_padrao_manutencao_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/utils/intervalo_padrao_manutencao.dart test/utils/intervalo_padrao_manutencao_test.dart
git commit -m "feat: adiciona tabela de intervalos padrao e intervaloEfetivo"
```

---

### Task 4: `getAll` no repositório genérico

**Files:**
- Modify: `lib/repositories/firestore_repository.dart`
- Test: `test/repositories/manutencao_repository_test.dart`, `test/repositories/lembrete_repository_test.dart`

**Interfaces:**
- Produces: `Future<List<T>> getAll(String uid, {String? veiculoId})` em `FirestoreRepository<T>`, herdado por todos os repositórios concretos (`ManutencaoRepository`, `LembreteRepository`, etc.) sem nenhuma mudança nos arquivos desses repositórios.

- [ ] **Step 1: Escrever os testes que falham**

Adicionar ao final de `test/repositories/manutencao_repository_test.dart` (dentro do `void main() { ... }`, depois do teste existente):

```dart
  test('getAll retorna todas as manutenções daquele veículo', () async {
    final manutencao1 = Manutencao(
      id: '',
      veiculoId: 'v1',
      tipo: TipoManutencao.trocaOleo,
      dataRealizada: DateTime(2026, 1, 1),
      kmNaData: 40000,
      custo: 200.0,
      oficina: 'Oficina',
      observacoes: '',
    );
    final manutencao2 = Manutencao(
      id: '',
      veiculoId: 'v1',
      tipo: TipoManutencao.revisao,
      dataRealizada: DateTime(2026, 2, 1),
      kmNaData: 41000,
      custo: 300.0,
      oficina: 'Oficina',
      observacoes: '',
    );

    await repository.add('uid1', manutencao1, veiculoId: 'v1');
    await repository.add('uid1', manutencao2, veiculoId: 'v1');
    await repository.add('uid1', manutencao1, veiculoId: 'v2');

    final lista = await repository.getAll('uid1', veiculoId: 'v1');

    expect(lista, hasLength(2));
  });
```

Adicionar ao final de `test/repositories/lembrete_repository_test.dart` (dentro do `void main() { ... }`, depois do teste existente):

```dart
  test('getAll retorna todos os lembretes daquele veículo', () async {
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
    await repository.add('uid1', lembrete, veiculoId: 'v2');

    final lista = await repository.getAll('uid1', veiculoId: 'v1');

    expect(lista, hasLength(1));
  });
```

- [ ] **Step 2: Rodar os testes e confirmar que falham**

Run: `flutter test test/repositories/manutencao_repository_test.dart test/repositories/lembrete_repository_test.dart`
Expected: FAIL — `The method 'getAll' isn't defined for the type 'ManutencaoRepository'` (e o mesmo para `LembreteRepository`).

- [ ] **Step 3: Implementar `getAll`**

Editar `lib/repositories/firestore_repository.dart`, adicionando o método depois de `watchAll` (arquivo completo após a mudança):

```dart
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

  Future<List<T>> getAll(String uid, {String? veiculoId}) async {
    final snap = await collection(uid, veiculoId: veiculoId).get();
    return snap.docs.map((d) => fromMap(d.id, d.data(), veiculoId: veiculoId)).toList();
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

- [ ] **Step 4: Rodar os testes e confirmar que passam**

Run: `flutter test test/repositories/manutencao_repository_test.dart test/repositories/lembrete_repository_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/repositories/firestore_repository.dart test/repositories/manutencao_repository_test.dart test/repositories/lembrete_repository_test.dart
git commit -m "feat: adiciona getAll ao FirestoreRepository"
```

---

### Task 5: Criação automática de lembrete em `ManutencaoProvider`

**Files:**
- Modify: `lib/providers/manutencao_provider.dart`
- Test: `test/providers/manutencao_provider_test.dart`

**Interfaces:**
- Consumes: `intervaloEfetivo` (Task 3), `FirestoreRepository.getAll` (Task 4), `LembreteRepository` (já existe em `lib/repositories/lembrete_repository.dart`), `LembreteManutencao` (já existe em `lib/models/lembrete_manutencao.dart`).
- Produces: `ManutencaoProvider` agora exige `required LembreteRepository lembreteRepository` no construtor. Comportamento público (`adicionar`, `atualizar`, `remover`, `manutencoes`, `escutarVeiculo`) inalterado na assinatura, exceto pelo novo efeito colateral de `adicionar()`.

- [ ] **Step 1: Atualizar os testes existentes para o novo construtor**

Em `test/providers/manutencao_provider_test.dart`, adicionar o import e passar `lembreteRepository` nas 3 chamadas existentes de `ManutencaoProvider(...)`. Arquivo completo após a mudança:

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/lembrete_manutencao.dart';
import 'package:revisacar/models/manutencao.dart';
import 'package:revisacar/models/veiculo.dart';
import 'package:revisacar/providers/manutencao_provider.dart';
import 'package:revisacar/repositories/lembrete_repository.dart';
import 'package:revisacar/repositories/manutencao_repository.dart';
import 'package:revisacar/repositories/veiculo_repository.dart';

void main() {
  test('escutarVeiculo carrega as manutenções daquele veículo', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = ManutencaoRepository(firestore);
    final provider = ManutencaoProvider(
      repository: repository,
      veiculoRepository: VeiculoRepository(firestore),
      lembreteRepository: LembreteRepository(firestore),
      uid: 'uid1',
    );

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
      lembreteRepository: LembreteRepository(firestore),
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
      lembreteRepository: LembreteRepository(firestore),
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

  test('adicionar cria lembrete automático quando não existe nenhum daquele tipo', () async {
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
    final lembreteRepository = LembreteRepository(firestore);
    final provider = ManutencaoProvider(
      repository: ManutencaoRepository(firestore),
      veiculoRepository: veiculoRepository,
      lembreteRepository: lembreteRepository,
      uid: 'uid1',
    );
    provider.escutarVeiculo(veiculoId);

    await provider.adicionar(Manutencao(
      id: '',
      veiculoId: veiculoId,
      tipo: TipoManutencao.trocaOleo,
      dataRealizada: DateTime(2026, 1, 1),
      kmNaData: 40500,
      custo: 200.0,
      oficina: 'Oficina',
      observacoes: '',
    ));

    final lembretes = await lembreteRepository.getAll('uid1', veiculoId: veiculoId);
    expect(lembretes, hasLength(1));
    final lembrete = lembretes.first;
    expect(lembrete.tipoManutencao, TipoManutencao.trocaOleo);
    expect(lembrete.intervaloKm, 10000);
    expect(lembrete.intervaloDias, 360);
    expect(lembrete.antecedenciaKm, 500);
    expect(lembrete.antecedenciaDias, 15);
    expect(lembrete.intervaloRepeticaoDias, 3);
    expect(lembrete.ativo, isTrue);
  });

  test('adicionar não cria um segundo lembrete quando já existe um daquele tipo', () async {
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
    final lembreteRepository = LembreteRepository(firestore);
    await lembreteRepository.add(
      'uid1',
      LembreteManutencao(
        id: '',
        veiculoId: veiculoId,
        tipoManutencao: TipoManutencao.trocaOleo,
        intervaloKm: 12000,
        antecedenciaKm: 0,
        antecedenciaDias: 0,
        intervaloRepeticaoDias: 3,
        ativo: false,
      ),
      veiculoId: veiculoId,
    );
    final provider = ManutencaoProvider(
      repository: ManutencaoRepository(firestore),
      veiculoRepository: veiculoRepository,
      lembreteRepository: lembreteRepository,
      uid: 'uid1',
    );
    provider.escutarVeiculo(veiculoId);

    await provider.adicionar(Manutencao(
      id: '',
      veiculoId: veiculoId,
      tipo: TipoManutencao.trocaOleo,
      dataRealizada: DateTime(2026, 1, 1),
      kmNaData: 40500,
      custo: 200.0,
      oficina: 'Oficina',
      observacoes: '',
    ));

    final lembretes = await lembreteRepository.getAll('uid1', veiculoId: veiculoId);
    expect(lembretes, hasLength(1));
    expect(lembretes.first.intervaloKm, 12000);
  });

  test('adicionar não cria lembrete para o tipo Outro', () async {
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
    final lembreteRepository = LembreteRepository(firestore);
    final provider = ManutencaoProvider(
      repository: ManutencaoRepository(firestore),
      veiculoRepository: veiculoRepository,
      lembreteRepository: lembreteRepository,
      uid: 'uid1',
    );
    provider.escutarVeiculo(veiculoId);

    await provider.adicionar(Manutencao(
      id: '',
      veiculoId: veiculoId,
      tipo: TipoManutencao.outro,
      descricaoOutro: 'Troca de parabrisa',
      dataRealizada: DateTime(2026, 1, 1),
      kmNaData: 40500,
      custo: 200.0,
      oficina: 'Oficina',
      observacoes: '',
    ));

    final lembretes = await lembreteRepository.getAll('uid1', veiculoId: veiculoId);
    expect(lembretes, isEmpty);
  });

  test('adicionar não cria lembrete quando o intervalo efetivo do veículo está vazio', () async {
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
        intervalosPersonalizados: {
          TipoManutencao.trocaOleo: IntervaloManutencao(),
        },
      ),
    );
    final lembreteRepository = LembreteRepository(firestore);
    final provider = ManutencaoProvider(
      repository: ManutencaoRepository(firestore),
      veiculoRepository: veiculoRepository,
      lembreteRepository: lembreteRepository,
      uid: 'uid1',
    );
    provider.escutarVeiculo(veiculoId);

    await provider.adicionar(Manutencao(
      id: '',
      veiculoId: veiculoId,
      tipo: TipoManutencao.trocaOleo,
      dataRealizada: DateTime(2026, 1, 1),
      kmNaData: 40500,
      custo: 200.0,
      oficina: 'Oficina',
      observacoes: '',
    ));

    final lembretes = await lembreteRepository.getAll('uid1', veiculoId: veiculoId);
    expect(lembretes, isEmpty);
  });

  test('atualizar não cria lembrete', () async {
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
    final manutencaoRepository = ManutencaoRepository(firestore);
    final manutencaoId = await manutencaoRepository.add(
      'uid1',
      Manutencao(
        id: '',
        veiculoId: veiculoId,
        tipo: TipoManutencao.trocaOleo,
        dataRealizada: DateTime(2026, 1, 1),
        kmNaData: 40500,
        custo: 200.0,
        oficina: 'Oficina',
        observacoes: '',
      ),
      veiculoId: veiculoId,
    );
    final lembreteRepository = LembreteRepository(firestore);
    final provider = ManutencaoProvider(
      repository: manutencaoRepository,
      veiculoRepository: veiculoRepository,
      lembreteRepository: lembreteRepository,
      uid: 'uid1',
    );
    provider.escutarVeiculo(veiculoId);

    await provider.atualizar(Manutencao(
      id: manutencaoId,
      veiculoId: veiculoId,
      tipo: TipoManutencao.trocaOleo,
      dataRealizada: DateTime(2026, 1, 1),
      kmNaData: 41000,
      custo: 250.0,
      oficina: 'Oficina 2',
      observacoes: '',
    ));

    final lembretes = await lembreteRepository.getAll('uid1', veiculoId: veiculoId);
    expect(lembretes, isEmpty);
  });
}
```

Adicionar também o import de `IntervaloManutencao` no topo do arquivo:

```dart
import 'package:revisacar/models/intervalo_manutencao.dart';
```

- [ ] **Step 2: Rodar os testes e confirmar que falham**

Run: `flutter test test/providers/manutencao_provider_test.dart`
Expected: FAIL — `No named parameter with the name 'lembreteRepository'`.

- [ ] **Step 3: Implementar a criação automática em `ManutencaoProvider`**

Editar `lib/providers/manutencao_provider.dart` (arquivo completo após a mudança):

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/manutencao.dart';
import '../models/veiculo.dart';
import '../models/lembrete_manutencao.dart';
import '../repositories/manutencao_repository.dart';
import '../repositories/lembrete_repository.dart';
import '../repositories/veiculo_repository.dart';
import '../utils/intervalo_padrao_manutencao.dart';

class ManutencaoProvider extends ChangeNotifier {
  final ManutencaoRepository _repository;
  final VeiculoRepository _veiculoRepository;
  final LembreteRepository _lembreteRepository;
  final String uid;

  String? _veiculoId;
  List<Manutencao> _manutencoes = [];
  StreamSubscription<List<Manutencao>>? _subscription;

  ManutencaoProvider({
    required ManutencaoRepository repository,
    required VeiculoRepository veiculoRepository,
    required LembreteRepository lembreteRepository,
    required this.uid,
  })  : _repository = repository,
        _veiculoRepository = veiculoRepository,
        _lembreteRepository = lembreteRepository;

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
    final veiculoId = _veiculoId;
    if (veiculoId == null) return;
    final veiculo = await _veiculoRepository.get(uid, veiculoId);
    if (veiculo == null) return;
    if (manutencao.kmNaData > veiculo.kmAtual) {
      await _veiculoRepository.update(uid, veiculoId, veiculo.copyWith(kmAtual: manutencao.kmNaData));
    }
    await _criarLembreteSeNecessario(veiculo, manutencao.tipo);
  }

  Future<void> _criarLembreteSeNecessario(Veiculo veiculo, TipoManutencao tipo) async {
    final intervalo = intervaloEfetivo(veiculo, tipo);
    if (intervalo == null || intervalo.vazio) return;
    final existentes = await _lembreteRepository.getAll(uid, veiculoId: veiculo.id);
    final jaExiste = existentes.any((l) => l.tipoManutencao == tipo);
    if (jaExiste) return;
    await _lembreteRepository.add(
      uid,
      LembreteManutencao(
        id: '',
        veiculoId: veiculo.id,
        tipoManutencao: tipo,
        intervaloKm: intervalo.km,
        intervaloDias: intervalo.dias,
        antecedenciaKm: 500,
        antecedenciaDias: 15,
        intervaloRepeticaoDias: 3,
        ativo: true,
      ),
      veiculoId: veiculo.id,
    );
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

- [ ] **Step 4: Rodar os testes e confirmar que passam**

Run: `flutter test test/providers/manutencao_provider_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/providers/manutencao_provider.dart test/providers/manutencao_provider_test.dart
git commit -m "feat: cria lembrete automatico ao adicionar manutencao"
```

---

### Task 6: Wiring do `LembreteRepository` em `DetalheVeiculoScreen`

**Files:**
- Modify: `lib/screens/detalhe_veiculo_screen.dart`

**Interfaces:**
- Consumes: `ManutencaoProvider` com o novo parâmetro obrigatório `lembreteRepository` (Task 5).

- [ ] **Step 1: Atualizar a instanciação do `ManutencaoProvider`**

Em `lib/screens/detalhe_veiculo_screen.dart`, dentro do `MultiProvider`, alterar:

```dart
        ChangeNotifierProvider<ManutencaoProvider>(
          create: (context) => ManutencaoProvider(
            repository: ManutencaoRepository(),
            veiculoRepository: context.read<VeiculoRepository>(),
            uid: uid,
          )..escutarVeiculo(veiculo.id),
        ),
```

para:

```dart
        ChangeNotifierProvider<ManutencaoProvider>(
          create: (context) => ManutencaoProvider(
            repository: ManutencaoRepository(),
            veiculoRepository: context.read<VeiculoRepository>(),
            lembreteRepository: LembreteRepository(),
            uid: uid,
          )..escutarVeiculo(veiculo.id),
        ),
```

O import de `LembreteRepository` já existe no arquivo (usado pelo `LembreteProvider` logo abaixo) — não precisa adicionar.

- [ ] **Step 2: Rodar análise estática**

Run: `flutter analyze lib/screens/detalhe_veiculo_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Rodar toda a suíte de testes para garantir que nada quebrou**

Run: `flutter test`
Expected: `All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add lib/screens/detalhe_veiculo_screen.dart
git commit -m "feat: injeta LembreteRepository no ManutencaoProvider da tela de detalhe"
```

---

### Task 7: Seção "Intervalos de manutenção" em `VeiculoFormScreen`

**Files:**
- Modify: `lib/screens/veiculo_form_screen.dart`

**Interfaces:**
- Consumes: `intervaloEfetivo`, `intervalosPadraoManutencao` (Task 3), `IntervaloManutencao` (Task 1), `Veiculo.intervalosPersonalizados` (Task 2), `TipoManutencaoLabel.label` (já existe em `lib/utils/tipo_manutencao_labels.dart`).

- [ ] **Step 1: Implementar a seção de configuração**

Editar `lib/screens/veiculo_form_screen.dart` (arquivo completo após a mudança):

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/intervalo_manutencao.dart';
import '../models/manutencao.dart';
import '../models/veiculo.dart';
import '../providers/veiculo_provider.dart';
import '../utils/intervalo_padrao_manutencao.dart';
import '../utils/tipo_manutencao_labels.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar veículo' : 'Novo veículo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: _obrigatorio,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _modeloController,
              decoration: const InputDecoration(labelText: 'Modelo'),
              validator: _obrigatorio,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _anoController,
              decoration: const InputDecoration(labelText: 'Ano'),
              keyboardType: TextInputType.number,
              validator: _numeroObrigatorio,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _placaController,
              decoration: const InputDecoration(labelText: 'Placa'),
              validator: _obrigatorio,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _kmAtualController,
              decoration: const InputDecoration(labelText: 'Km atual'),
              keyboardType: TextInputType.number,
              validator: _numeroObrigatorio,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TipoVeiculo>(
              initialValue: _tipoVeiculo,
              decoration: const InputDecoration(labelText: 'Tipo de veículo'),
              items: const [
                DropdownMenuItem(value: TipoVeiculo.carro, child: Text('Carro')),
                DropdownMenuItem(value: TipoVeiculo.moto, child: Text('Moto')),
              ],
              onChanged: (valor) => setState(() => _tipoVeiculo = valor ?? TipoVeiculo.carro),
            ),
            const SizedBox(height: 24),
            Text('Intervalos de manutenção', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Usado para criar lembretes automáticos. Deixe em branco para não gerar lembrete automático daquele tipo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            for (final tipo in _tiposComIntervalo) ...[
              const SizedBox(height: 12),
              Text(tipo.label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _intervaloKmControllers[tipo],
                      decoration: const InputDecoration(labelText: 'Km'),
                      keyboardType: TextInputType.number,
                      validator: _inteiroOpcional,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _intervaloMesesControllers[tipo],
                      decoration: const InputDecoration(labelText: 'Meses'),
                      keyboardType: TextInputType.number,
                      validator: _inteiroOpcional,
                    ),
                  ),
                ],
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

Run: `flutter analyze lib/screens/veiculo_form_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Rodar toda a suíte de testes para garantir que nada quebrou**

Run: `flutter test`
Expected: `All tests passed!`

- [ ] **Step 4: Verificação manual no app**

Rodar `flutter run`, abrir "Editar veículo" de um veículo existente, confirmar que a seção "Intervalos de manutenção" aparece com os 8 tipos pré-preenchidos com os valores padrão (ou personalizados, se já configurados), editar um valor, salvar, reabrir a tela e confirmar que o valor editado persistiu. Depois, na aba Manutenções, registrar uma manutenção de um tipo sem lembrete ainda e confirmar (na aba Lembretes) que a regra apareceu automaticamente com o intervalo esperado.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/veiculo_form_screen.dart
git commit -m "feat: adiciona configuracao de intervalos de manutencao por veiculo"
```

---

## Self-Review

**1. Cobertura do spec:**
- Tabela de intervalos padrão (HB20 + mercado) → Task 3.
- `intervalosPersonalizados` em `Veiculo` → Task 2.
- Tela de configuração em `VeiculoFormScreen` → Task 7.
- Criação automática em `ManutencaoProvider.adicionar()`, ignorando "Outro", não duplicando, não mexendo em `atualizar()` → Task 5.
- `getAll` no repositório genérico → Task 4.
- Wiring do novo parâmetro do provider na tela de detalhe → Task 6.
- Testes por camada seguindo o padrão existente (model/utils/repository/provider, sem widget tests) → Tasks 1, 2, 3, 4, 5.

**2. Placeholders:** nenhum "TBD"/"TODO" nas tasks; todo código está completo e executável.

**3. Consistência de tipos:** `IntervaloManutencao` (Task 1) é usado com os mesmos nomes de campo (`km`, `dias`, `vazio`) em todas as tasks seguintes. `intervaloEfetivo(Veiculo veiculo, TipoManutencao tipo)` (Task 3) é chamado com essa mesma assinatura em `ManutencaoProvider` (Task 5) e `VeiculoFormScreen` (Task 7). `LembreteRepository.getAll` e `ManutencaoRepository.getAll` (Task 4) usados com a mesma assinatura em Task 5.
