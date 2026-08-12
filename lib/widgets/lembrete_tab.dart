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
                  child: GestureDetector(
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
                          if (lembrete.intervaloKm != null || lembrete.intervaloDias != null) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (lembrete.intervaloKm != null)
                                  _ChipIntervalo('cada ${lembrete.intervaloKm} km'),
                                if (lembrete.intervaloDias != null)
                                  _ChipIntervalo('${lembrete.intervaloDias! ~/ 30} meses'),
                              ],
                            ),
                          ],
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
                                label: const Text('Marcar como feito'),
                              ),
                            ),
                        ],
                      ),
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

class _ChipIntervalo extends StatelessWidget {
  final String texto;

  const _ChipIntervalo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
      ),
    );
  }
}
