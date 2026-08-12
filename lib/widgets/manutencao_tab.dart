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
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: lembretesAtivos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
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
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: corTexto),
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
                        child: InkWell(
                          borderRadius: BorderRadius.circular(kCardRadius),
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
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: manutencao.tipo.cor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child:
                                        Icon(manutencao.tipo.icon, size: 18, color: manutencao.tipo.cor),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(manutencao.tipo.label,
                                            style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(
                                          manutencao.oficina,
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_formatarData(manutencao.dataRealizada)} · ${manutencao.kmNaData} km',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'R\$ ${manutencao.custo.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
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
