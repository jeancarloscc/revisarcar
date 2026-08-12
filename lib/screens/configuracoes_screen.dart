// lib/screens/configuracoes_screen.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../models/veiculo.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../providers/veiculo_provider.dart';
import '../repositories/abastecimento_repository.dart';
import '../repositories/manutencao_repository.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  Future<({int manutencoes, int abastecimentos})>? _contagemFuture;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_contagemFuture == null) {
      final veiculoProvider = context.read<VeiculoProvider>();
      _contagemFuture = _contarRegistros(veiculoProvider.uid, veiculoProvider.veiculos);
    }
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
                  future: _contagemFuture,
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
          const SizedBox(height: 20),
          _secao(
            context,
            'Sobre o app',
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final versao = snapshot.data?.version ?? '—';
                return Column(
                  children: [
                    ListTile(
                      title: const Text('Versão'),
                      trailing: Text(versao, style: TextStyle(color: Colors.grey.shade600)),
                    ),
                    const Divider(height: 1),
                    const ListTile(
                      title: Text('Sincronização'),
                      trailing: Text('Automática', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                );
              },
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
