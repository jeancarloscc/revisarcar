# Fase A: Autenticação + Navegação + CRUD de Veículos — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir a primeira fatia de UI do app — login com Google, esqueleto de navegação e CRUD completo (criar/editar/excluir) de veículos — sobre o backend já pronto do Plano 1 (Fundação: Dados e Serviços).

**Architecture:** `AuthGate` na raiz decide entre `LoginScreen` (sem usuário) e `VeiculoListScreen` (autenticado), esta última criando um `VeiculoProvider` escopado ao `uid` do usuário logado. Navegação com `Navigator` padrão (push/pop), sem pacote de roteamento. Exclusão de veículo é feita client-side em `VeiculoRepository`, apagando as 4 subcoleções em lote antes do documento do veículo (sem Cloud Functions).

**Tech Stack:** Flutter/Dart (SDK `^3.12.2`), `provider` (já em uso), `firebase_auth`/`cloud_firestore`/`firebase_core` (já em uso), `shared_preferences` (já em uso). Nenhuma dependência nova.

## Global Constraints

- Spec de referência desta fase: `docs/superpowers/specs/2026-07-06-fase-a-auth-navegacao-veiculos-design.md`.
- Interface em Português (Brasil).
- Sem foto do veículo nesta fase — `fotoUrl` permanece nulo; UI usa ícone genérico por `tipoVeiculo` (carro/moto).
- Sem `BottomNavigationBar` nesta fase — só existe a tela de Veículos como topo.
- Navegação: `Navigator` padrão (`MaterialPageRoute`), sem `go_router` nem rotas nomeadas.
- Tema: manter `ColorScheme.fromSeed(seedColor: Colors.deepPurple)` já presente em `main.dart`.
- Sem testes de widget nesta fase — a verificação de cada tela é `flutter analyze` limpo; a lógica de dados (repository/provider) segue com testes unitários, como no Plano 1.
- **Nenhuma tarefa deste plano deve executar comandos git** (`init`, `add`, `commit`, etc.) — projeto não usa controle de versão (mesma decisão do Plano 1). Cada tarefa termina depois que os testes/análise passam; não há passo de commit.
- Exclusão de veículo apaga as subcoleções (`manutencoes`, `abastecimentos`, `lembretes`, `checklistItems`) em lotes de até 500 documentos antes de apagar o documento do veículo; não é atômico entre subcoleções (limitação aceita, ver spec).

---

### Task 1: `VeiculoRepository.remover` — exclusão em cascata

**Files:**
- Modify: `lib/repositories/veiculo_repository.dart`
- Test: `test/repositories/veiculo_repository_test.dart`

**Interfaces:**
- Consumes: `FirestoreRepository<Veiculo>` (base já existente), `Veiculo` model.
- Produces: `Future<void> remover(String uid, String veiculoId)` em `VeiculoRepository` — usado pela Task 2 (`VeiculoProvider.remover`).

- [ ] **Step 1: Escrever os testes (falhando)**

Adicionar estes dois testes dentro do `group('VeiculoRepository', ...)` existente em `test/repositories/veiculo_repository_test.dart` (após o teste `'get retorna o veículo pelo id, ou null se não existir'`):

```dart
    test('remover apaga o veículo e todos os documentos das subcoleções', () async {
      const veiculo = Veiculo(
        id: '',
        nome: 'Meu HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
      );
      final veiculoId = await repository.add('uid1', veiculo);

      final veiculoDoc = firestore
          .collection('users')
          .doc('uid1')
          .collection('veiculos')
          .doc(veiculoId);
      await veiculoDoc.collection('manutencoes').add({'tipo': 'trocaOleo'});
      await veiculoDoc.collection('abastecimentos').add({'litros': 40});
      await veiculoDoc.collection('lembretes').add({'ativo': true});
      await veiculoDoc.collection('checklistItems').add({'descricao': 'Óleo'});

      await repository.remover('uid1', veiculoId);

      final veiculoRestante = await repository.get('uid1', veiculoId);
      expect(veiculoRestante, isNull);
      expect((await veiculoDoc.collection('manutencoes').get()).docs, isEmpty);
      expect((await veiculoDoc.collection('abastecimentos').get()).docs, isEmpty);
      expect((await veiculoDoc.collection('lembretes').get()).docs, isEmpty);
      expect((await veiculoDoc.collection('checklistItems').get()).docs, isEmpty);
    });

    test('remover funciona mesmo quando o veículo não tem nenhum registro nas subcoleções', () async {
      const veiculo = Veiculo(
        id: '',
        nome: 'Sem registros',
        modelo: 'Y',
        ano: 2020,
        placa: 'ZZZ',
        kmAtual: 0,
        tipoVeiculo: TipoVeiculo.moto,
      );
      final veiculoId = await repository.add('uid1', veiculo);

      await repository.remover('uid1', veiculoId);

      final veiculoRestante = await repository.get('uid1', veiculoId);
      expect(veiculoRestante, isNull);
    });
```

O import `package:cloud_firestore/cloud_firestore.dart` já existe no topo do arquivo (necessário para `firestore.collection(...)` usado no primeiro teste novo).

- [ ] **Step 2: Rodar os testes para confirmar que falham**

Run: `flutter test test/repositories/veiculo_repository_test.dart`
Expected: FAIL — `The method 'remover' isn't defined for the type 'VeiculoRepository'`.

- [ ] **Step 3: Implementar `remover` em `VeiculoRepository`**

Substituir o conteúdo de `lib/repositories/veiculo_repository.dart` por:

```dart
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

  static const _subcolecoes = [
    'manutencoes',
    'abastecimentos',
    'lembretes',
    'checklistItems',
  ];

  Future<void> remover(String uid, String veiculoId) async {
    final veiculoDoc = collection(uid).doc(veiculoId);

    for (final nome in _subcolecoes) {
      final snapshot = await veiculoDoc.collection(nome).get();
      for (var i = 0; i < snapshot.docs.length; i += 500) {
        final lote = _firestore.batch();
        for (final doc in snapshot.docs.skip(i).take(500)) {
          lote.delete(doc.reference);
        }
        await lote.commit();
      }
    }

    await veiculoDoc.delete();
  }
}
```

- [ ] **Step 4: Rodar os testes para confirmar que passam**

Run: `flutter test test/repositories/veiculo_repository_test.dart`
Expected: PASS (todos os testes do arquivo, incluindo os 2 novos).

---

### Task 2: `VeiculoProvider` — `adicionar`/`atualizar`/`remover`

**Files:**
- Modify: `lib/providers/veiculo_provider.dart`
- Test: `test/providers/veiculo_provider_test.dart`

**Interfaces:**
- Consumes: `VeiculoRepository.add/update/remover` (Task 1 para `remover`; `add`/`update` já existem).
- Produces: `Future<void> adicionar(Veiculo veiculo)`, `Future<void> atualizar(String id, Veiculo veiculo)`, `Future<void> remover(String id)` em `VeiculoProvider` — usados pela Task 4 (`VeiculoFormScreen`) e Task 6 (`VeiculoListScreen`).

- [ ] **Step 1: Escrever os testes (falhando)**

Adicionar estes 3 testes em `test/providers/veiculo_provider_test.dart`, dentro do `void main() { ... }`, após o teste `'selecionarVeiculo troca o veículo ativo e persiste a escolha'`:

```dart
  test('adicionar grava um novo veículo e ele aparece na lista', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = VeiculoRepository(firestore);
    final prefs = await SharedPreferences.getInstance();
    final provider = VeiculoProvider(repository: repository, prefs: prefs, uid: 'uid1');
    await Future<void>.delayed(Duration.zero);

    await provider.adicionar(
      const Veiculo(
        id: '',
        nome: 'Nova Moto',
        modelo: 'Honda CG',
        ano: 2022,
        placa: 'MOT0123',
        kmAtual: 1000,
        tipoVeiculo: TipoVeiculo.moto,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(provider.veiculos, hasLength(1));
    expect(provider.veiculos.first.nome, 'Nova Moto');
  });

  test('atualizar altera os dados de um veículo existente', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = VeiculoRepository(firestore);
    final id = await repository.add(
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
    final prefs = await SharedPreferences.getInstance();
    final provider = VeiculoProvider(repository: repository, prefs: prefs, uid: 'uid1');
    await Future<void>.delayed(Duration.zero);

    await provider.atualizar(id, provider.veiculos.first.copyWith(kmAtual: 46000));
    await Future<void>.delayed(Duration.zero);

    expect(provider.veiculos.first.kmAtual, 46000);
  });

  test('remover exclui o veículo e ele some da lista', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = VeiculoRepository(firestore);
    final id = await repository.add(
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
    final prefs = await SharedPreferences.getInstance();
    final provider = VeiculoProvider(repository: repository, prefs: prefs, uid: 'uid1');
    await Future<void>.delayed(Duration.zero);

    await provider.remover(id);
    await Future<void>.delayed(Duration.zero);

    expect(provider.veiculos, isEmpty);
  });
```

- [ ] **Step 2: Rodar os testes para confirmar que falham**

Run: `flutter test test/providers/veiculo_provider_test.dart`
Expected: FAIL — os métodos `adicionar`, `atualizar` e `remover` não existem em `VeiculoProvider`.

- [ ] **Step 3: Implementar os métodos em `VeiculoProvider`**

Em `lib/providers/veiculo_provider.dart`, adicionar estes 3 métodos na classe `VeiculoProvider` (por exemplo, logo após `selecionarVeiculo`):

```dart
  Future<void> adicionar(Veiculo veiculo) {
    return _repository.add(uid, veiculo);
  }

  Future<void> atualizar(String id, Veiculo veiculo) {
    return _repository.update(uid, id, veiculo);
  }

  Future<void> remover(String id) {
    return _repository.remover(uid, id);
  }
```

- [ ] **Step 4: Rodar os testes para confirmar que passam**

Run: `flutter test test/providers/veiculo_provider_test.dart`
Expected: PASS (todos os testes do arquivo, incluindo os 3 novos).

---

### Task 3: `LoginScreen`

**Files:**
- Create: `lib/screens/login_screen.dart`

**Interfaces:**
- Consumes: `AppAuthProvider` (`lib/providers/auth_provider.dart`) — `User? user`, `String? errorMessage`, `Future<void> signInWithGoogle()`.
- Produces: `class LoginScreen extends StatefulWidget` — usado pela Task 7 (`AuthGate`) quando `user == null`.

- [ ] **Step 1: Criar a tela**

```dart
// lib/screens/login_screen.dart
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

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'RevisaCar',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              if (erro != null) ...[
                Text(erro, style: const TextStyle(color: Colors.red)),
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

- [ ] **Step 2: Verificar que o projeto compila sem erros**

Run: `flutter analyze lib/screens/login_screen.dart`
Expected: `No issues found!`

---

### Task 4: `VeiculoFormScreen` (criar/editar)

**Files:**
- Create: `lib/screens/veiculo_form_screen.dart`

**Interfaces:**
- Consumes: `Veiculo`/`TipoVeiculo` (`lib/models/veiculo.dart`), `VeiculoProvider.adicionar(Veiculo)` / `VeiculoProvider.atualizar(String id, Veiculo veiculo)` (Task 2).
- Produces: `class VeiculoFormScreen extends StatefulWidget` com construtor `VeiculoFormScreen({Key? key, Veiculo? veiculo})` (`veiculo == null` → modo criar; não nulo → modo editar) — usado pela Task 6 (`VeiculoListScreen`).

- [ ] **Step 1: Criar a tela**

```dart
// lib/screens/veiculo_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/veiculo.dart';
import '../providers/veiculo_provider.dart';

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
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _modeloController.dispose();
    _anoController.dispose();
    _placaController.dispose();
    _kmAtualController.dispose();
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

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    final veiculo = Veiculo(
      id: widget.veiculo?.id ?? '',
      nome: _nomeController.text.trim(),
      modelo: _modeloController.text.trim(),
      ano: int.parse(_anoController.text.trim()),
      placa: _placaController.text.trim(),
      kmAtual: int.parse(_kmAtualController.text.trim()),
      tipoVeiculo: _tipoVeiculo,
      fotoUrl: widget.veiculo?.fotoUrl,
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

Run: `flutter analyze lib/screens/veiculo_form_screen.dart`
Expected: `No issues found!`

---

### Task 5: `ConfiguracoesScreen` (mínima — só sign-out)

**Files:**
- Create: `lib/screens/configuracoes_screen.dart`

**Interfaces:**
- Consumes: `AppAuthProvider.signOut()`.
- Produces: `class ConfiguracoesScreen extends StatelessWidget` — usado pela Task 6 (`VeiculoListScreen`, ícone de Configurações no `AppBar`).

**Nota de arquitetura:** como `AuthGate` (Task 7) é o `home` do `MaterialApp`, e `ConfiguracoesScreen` é empurrada por cima dele via `Navigator.push`, o simples `signOut()` não troca a tela sozinho — a rota empilhada de Configurações continuaria visível. Por isso, depois do `signOut()`, o handler chama `Navigator.of(context).popUntil((route) => route.isFirst)` para voltar até a rota raiz (`AuthGate`), que então detecta `user == null` e mostra `LoginScreen`.

- [ ] **Step 1: Criar a tela**

```dart
// lib/screens/configuracoes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  Future<void> _sair(BuildContext context) async {
    await context.read<AppAuthProvider>().signOut();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sair da conta'),
          onTap: () => _sair(context),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verificar que o projeto compila sem erros**

Run: `flutter analyze lib/screens/configuracoes_screen.dart`
Expected: `No issues found!`

---

### Task 6: `VeiculoCard` + `VeiculoListScreen`

**Files:**
- Create: `lib/widgets/veiculo_card.dart`
- Create: `lib/screens/veiculo_list_screen.dart`

**Interfaces:**
- Consumes: `Veiculo`/`TipoVeiculo`, `VeiculoProvider` (`veiculos`, `remover(String id)` — Task 2), `VeiculoFormScreen` (Task 4), `ConfiguracoesScreen` (Task 5).
- Produces: `class VeiculoCard extends StatelessWidget`; `class VeiculoListScreen extends StatelessWidget` — usado pela Task 7 (`AuthGate`) quando `user != null`.

- [ ] **Step 1: Criar o widget de card**

```dart
// lib/widgets/veiculo_card.dart
import 'package:flutter/material.dart';

import '../models/veiculo.dart';

class VeiculoCard extends StatelessWidget {
  final Veiculo veiculo;
  final VoidCallback onTap;
  final VoidCallback onExcluir;

  const VeiculoCard({
    super.key,
    required this.veiculo,
    required this.onTap,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          veiculo.tipoVeiculo == TipoVeiculo.moto ? Icons.two_wheeler : Icons.directions_car,
          size: 40,
        ),
        title: Text(veiculo.nome),
        subtitle: Text('${veiculo.modelo} • ${veiculo.kmAtual} km'),
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

**Nota (decisão pós-revisão):** o design original desta task tinha um menu "⋮" com "Editar" e "Excluir", mas "Editar" duplicava a mesma ação do toque no card. O usuário decidiu remover "Editar" do menu — editar só é acessível pelo toque no card; o menu virou um único `IconButton` de exclusão. O código acima já reflete essa decisão.

- [ ] **Step 2: Criar a tela de lista**

```dart
// lib/screens/veiculo_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/veiculo_provider.dart';
import '../widgets/veiculo_card.dart';
import 'configuracoes_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final veiculos = context.watch<VeiculoProvider>().veiculos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus veículos'),
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
                return VeiculoCard(
                  veiculo: veiculo,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => VeiculoFormScreen(veiculo: veiculo)),
                  ),
                  onExcluir: () => _confirmarExclusao(context, veiculo.id, veiculo.nome),
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

- [ ] **Step 3: Verificar que o projeto compila sem erros**

Run: `flutter analyze lib/widgets/veiculo_card.dart lib/screens/veiculo_list_screen.dart`
Expected: `No issues found!`

---

### Task 7: `AuthGate`

**Files:**
- Create: `lib/screens/auth_gate.dart`

**Interfaces:**
- Consumes: `AppAuthProvider.user` (`lib/providers/auth_provider.dart`), `VeiculoRepository` (Provider, disponibilizado pela Task 8), `SharedPreferences` (Provider, disponibilizado pela Task 8), `VeiculoProvider` (Task 2), `LoginScreen` (Task 3), `VeiculoListScreen` (Task 6).
- Produces: `class AuthGate extends StatelessWidget` — usado como `home` do `MaterialApp` na Task 8.

- [ ] **Step 1: Criar o widget**

```dart
// lib/screens/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../providers/veiculo_provider.dart';
import '../repositories/veiculo_repository.dart';
import 'login_screen.dart';
import 'veiculo_list_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().user;

    if (user == null) {
      return const LoginScreen();
    }

    return ChangeNotifierProvider<VeiculoProvider>(
      key: ValueKey(user.uid),
      create: (context) => VeiculoProvider(
        repository: context.read<VeiculoRepository>(),
        prefs: context.read<SharedPreferences>(),
        uid: user.uid,
      ),
      child: const VeiculoListScreen(),
    );
  }
}
```

`key: ValueKey(user.uid)` garante que, se o usuário sair e entrar com uma conta Google diferente, o `VeiculoProvider` seja recriado do zero para o novo `uid` em vez de manter o estado (lista de veículos, veículo ativo) da conta anterior.

- [ ] **Step 2: Verificar que o projeto compila sem erros**

Run: `flutter analyze lib/screens/auth_gate.dart`
Expected: `No issues found!`

---

### Task 8: Ligar tudo em `main.dart`

**Files:**
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `AppAuthProvider` (Plano 1), `VeiculoRepository` (Plano 1 + Task 1), `AuthGate` (Task 7).
- Produces: app completo, executável (`flutter run`).

- [ ] **Step 1: Reescrever `main.dart` com o provider tree e o `AuthGate`**

```dart
// lib/main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'repositories/veiculo_repository.dart';
import 'screens/auth_gate.dart';

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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        Provider<SharedPreferences>.value(value: prefs),
        Provider<VeiculoRepository>(create: (_) => VeiculoRepository()),
      ],
      child: MaterialApp(
        title: 'RevisaCar',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
        home: const AuthGate(),
      ),
    );
  }
}
```

- [ ] **Step 2: Rodar a análise estática do projeto inteiro**

Run: `flutter analyze`
Expected: sem novos erros introduzidos por este plano (os infos/warnings pré-existentes do Plano 1, não relacionados a este trabalho, podem continuar aparecendo).

- [ ] **Step 3: Rodar a suíte de testes completa**

Run: `flutter test`
Expected: PASS em todos os testes (Plano 1 + os novos das Tasks 1 e 2 deste plano).

- [ ] **Step 4: Smoke test manual (sem automação — fora do escopo desta fase)**

Run: `flutter run` (em emulador/dispositivo Android ou simulador/dispositivo iOS conectado)
Checklist manual:
- Tela de Login aparece; "Entrar com Google" completa o login e leva à lista de veículos (vazia na primeira vez).
- FAB abre o formulário; cadastrar um veículo faz ele aparecer na lista.
- Tocar um card abre o formulário preenchido em modo edição; alterar um campo e salvar reflete na lista.
- Menu "⋮" no card → "Excluir" pede confirmação; confirmar remove o veículo da lista.
- Ícone de Configurações no `AppBar` abre a tela; "Sair da conta" volta para a tela de Login.
- Login novamente (mesma conta ou outra) volta a mostrar a lista corretamente (vazia se for outra conta, populada se for a mesma).

---

## Plano concluído quando

Tasks 1–8 concluídas, `flutter analyze` e `flutter test` passando, e o smoke test manual da Task 8 realizado com sucesso pelo usuário.
