import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/veiculo.dart';
import '../providers/veiculo_provider.dart';
import '../repositories/lembrete_repository.dart';
import '../repositories/manutencao_repository.dart';
import '../services/lembrete_service.dart';
import '../widgets/veiculo_card.dart';
import 'calculadora_combustivel_screen.dart';
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
            icon: const Icon(Icons.local_gas_station),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalculadoraCombustivelScreen()),
            ),
          ),
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
