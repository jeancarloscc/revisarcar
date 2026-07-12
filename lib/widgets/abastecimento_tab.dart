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
