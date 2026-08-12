// lib/screens/detalhe_veiculo_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/veiculo.dart';
import '../providers/abastecimento_provider.dart';
import '../providers/checklist_provider.dart';
import '../providers/lembrete_provider.dart';
import '../providers/manutencao_provider.dart';
import '../providers/veiculo_provider.dart';
import '../repositories/abastecimento_repository.dart';
import '../repositories/checklist_repository.dart';
import '../repositories/lembrete_repository.dart';
import '../repositories/manutencao_repository.dart';
import '../repositories/veiculo_repository.dart';
import '../services/lembrete_service.dart';
import '../widgets/abastecimento_tab.dart';
import '../widgets/checklist_tab.dart';
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
        ChangeNotifierProvider<ChecklistProvider>(
          create: (context) => ChecklistProvider(
            repository: ChecklistRepository(),
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
                    ChecklistTab(veiculoId: widget.veiculo.id),
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
              NavigationDestination(icon: Icon(Icons.checklist), label: 'Checklist'),
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
