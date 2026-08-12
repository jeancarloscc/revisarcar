import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/checklist_item.dart';
import '../providers/checklist_provider.dart';
import '../utils/checklist_padrao.dart';
import 'confirmar_exclusao_dialog.dart';

class ChecklistTab extends StatelessWidget {
  final String veiculoId;

  const ChecklistTab({super.key, required this.veiculoId});

  Future<void> _usarChecklistSugerido(BuildContext context, ChecklistProvider provider) async {
    try {
      for (final descricao in checklistPadrao) {
        await provider.adicionar(ChecklistItem(
          id: '',
          veiculoId: veiculoId,
          descricao: descricao,
          ordem: provider.checklistItems.length,
          verificado: false,
        ));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível criar o checklist. Tente novamente.')),
        );
      }
    }
  }

  Future<void> _adicionarItem(BuildContext context, ChecklistProvider provider) async {
    final controller = TextEditingController();
    final descricao = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo item'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Descrição'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (descricao == null || descricao.isEmpty || !context.mounted) return;

    try {
      await provider.adicionar(ChecklistItem(
        id: '',
        veiculoId: veiculoId,
        descricao: descricao,
        ordem: provider.checklistItems.length,
        verificado: false,
      ));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível adicionar o item. Tente novamente.')),
        );
      }
    }
  }

  Future<void> _alternar(BuildContext context, ChecklistProvider provider, ChecklistItem item) async {
    try {
      await provider.alternarVerificado(item);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível atualizar o item. Tente novamente.')),
        );
      }
    }
  }

  Future<bool> _excluir(BuildContext context, ChecklistProvider provider, String id) async {
    final confirmar = await confirmarExclusaoDialog(
      context,
      titulo: 'Excluir item',
      mensagem: 'Excluir este item do checklist? Essa ação não pode ser desfeita.',
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

  Future<void> _reiniciar(BuildContext context, ChecklistProvider provider) async {
    final confirmar = await confirmarExclusaoDialog(
      context,
      titulo: 'Reiniciar checklist',
      mensagem: 'Todos os itens marcados voltam a ficar pendentes.',
      textoConfirmar: 'Reiniciar',
    );
    if (!confirmar) return;

    try {
      await provider.resetarTodos();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível reiniciar o checklist. Tente novamente.')),
        );
      }
    }
  }

  Widget _resumo(BuildContext context, ChecklistProvider provider, List<ChecklistItem> itens) {
    final concluidos = itens.where((i) => i.verificado).length;
    final progresso = itens.isEmpty ? 0.0 : concluidos / itens.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$concluidos de ${itens.length} concluídos',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: concluidos > 0 ? () => _reiniciar(context, provider) : null,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reiniciar'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: progresso, minHeight: 6),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final itens = provider.checklistItems.toList()..sort((a, b) => a.ordem.compareTo(b.ordem));

    return Scaffold(
      body: itens.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Nenhum item no checklist.', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _usarChecklistSugerido(context, provider),
                      icon: const Icon(Icons.playlist_add_check),
                      label: const Text('Usar checklist sugerido'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                _resumo(context, provider, itens),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: itens.length,
                    itemBuilder: (context, index) {
                      final item = itens[index];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Theme.of(context).colorScheme.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) => _excluir(context, provider, item.id),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: CheckboxListTile(
                            controlAffinity: ListTileControlAffinity.leading,
                            value: item.verificado,
                            onChanged: (_) => _alternar(context, provider, item),
                            title: Text(
                              item.descricao,
                              style: item.verificado
                                  ? const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_checklist',
        onPressed: () => _adicionarItem(context, provider),
        child: const Icon(Icons.add),
      ),
    );
  }
}
