import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/abastecimento.dart';
import '../providers/abastecimento_provider.dart';
import '../screens/abastecimento_form_screen.dart';
import '../screens/calculadora_combustivel_screen.dart';
import '../services/consumo_service.dart';
import '../theme/app_theme.dart';
import '../utils/mes_chave.dart';
import '../utils/tipo_combustivel_labels.dart';
import 'confirmar_exclusao_dialog.dart';

class AbastecimentoTab extends StatefulWidget {
  const AbastecimentoTab({super.key});

  @override
  State<AbastecimentoTab> createState() => _AbastecimentoTabState();
}

class _AbastecimentoTabState extends State<AbastecimentoTab> {
  String _mesSelecionado = chaveMesAtual();

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

  ({double total, double litros, double? consumo, int count}) _statsDoMes(
    List<Abastecimento> todos,
    List<Abastecimento> doMes,
  ) {
    final total = doMes.fold<double>(0, (s, a) => s + a.valorTotal);
    final litros = doMes.fold<double>(0, (s, a) => s + a.litros);
    final consumo = ConsumoService.mediaConsumoReal(todos, doMes);
    return (total: total, litros: litros, consumo: consumo, count: doMes.length);
  }

  Widget _navegadorMes(BuildContext context, String mesAtual) {
    final podeAvancar = _mesSelecionado.compareTo(mesAtual) < 0;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _mesSelecionado = passoMes(_mesSelecionado, -1)),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(formatarChaveMes(_mesSelecionado), style: Theme.of(context).textTheme.titleSmall),
                if (_mesSelecionado == mesAtual)
                  const Text(
                    'Mês atual',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kAccentColor),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed:
                  podeAvancar ? () => setState(() => _mesSelecionado = passoMes(_mesSelecionado, 1)) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _comparacaoGasto(
    ({double total, double litros, double? consumo, int count}) stats,
    ({double total, double litros, double? consumo, int count}) statsAnterior,
  ) {
    if (statsAnterior.total <= 0) return null;
    final delta = (stats.total - statsAnterior.total) / statsAnterior.total * 100;
    final cor = delta > 0 ? kStatusVencidoTexto : kStatusEmDiaTexto;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cor),
        ),
        const SizedBox(width: 4),
        Text('vs mês anterior', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget? _comparacaoSimples(String? texto) {
    if (texto == null) return null;
    return Text(texto, style: TextStyle(fontSize: 10, color: Colors.grey.shade600));
  }

  Widget _statsGrid(
    BuildContext context,
    ({double total, double litros, double? consumo, int count}) stats,
    ({double total, double litros, double? consumo, int count}) statsAnterior,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.7,
      children: [
        _CardEstatistica(
          rotulo: 'Total gasto',
          valor: 'R\$ ${stats.total.toStringAsFixed(2)}',
          comparacao: _comparacaoGasto(stats, statsAnterior),
        ),
        _CardEstatistica(
          rotulo: 'Abastecido',
          valor: '${stats.litros.toStringAsFixed(0)} L',
          comparacao: _comparacaoSimples(
              statsAnterior.litros > 0 ? 'vs ${statsAnterior.litros.toStringAsFixed(0)} L' : null),
        ),
        _CardEstatistica(
          rotulo: 'Consumo médio',
          valor: stats.consumo != null ? '${stats.consumo!.toStringAsFixed(1)} km/L' : '—',
          comparacao: _comparacaoSimples(statsAnterior.consumo != null
              ? 'vs ${statsAnterior.consumo!.toStringAsFixed(1)} km/L'
              : null),
        ),
        _CardEstatistica(
          rotulo: 'Abastecimentos',
          valor: '${stats.count}x',
          comparacao: _comparacaoSimples(statsAnterior.count > 0 ? 'vs ${statsAnterior.count}x' : null),
        ),
      ],
    );
  }

  Widget _historicoPorMes(BuildContext context, List<Abastecimento> todos, List<String> outrosMeses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HISTÓRICO POR MÊS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        for (final chave in outrosMeses)
          Builder(builder: (context) {
            final doMes = todos.where((a) => chaveMes(a.data) == chave).toList();
            final stats = _statsDoMes(todos, doMes);
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => setState(() => _mesSelecionado = chave),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formatarChaveMes(chave), style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${stats.count} abastecimento${stats.count != 1 ? 's' : ''} · ${stats.litros.toStringAsFixed(0)} L',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text('R\$ ${stats.total.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleSmall),
                          const Icon(Icons.chevron_right, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _cardRegistro(
    BuildContext context,
    Abastecimento a,
    List<Abastecimento> todos,
    AbastecimentoProvider provider,
  ) {
    final referencia = ConsumoService.referenciaAnterior(todos, a);
    final precoLitro = a.litros > 0 ? a.valorTotal / a.litros : null;

    return Dismissible(
      key: ValueKey(a.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _excluir(context, provider, a.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            final abastecimentoProvider = context.read<AbastecimentoProvider>();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: abastecimentoProvider,
                  child: AbastecimentoFormScreen(abastecimento: a),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.local_gas_station, size: 18, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'R\$ ${a.valorTotal.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          if (a.tanqueCheio) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: kStatusEmDiaFundo,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Cheio',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kStatusEmDiaTexto),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            precoLitro != null
                                ? '${a.litros.toStringAsFixed(1)} L · R\$ ${precoLitro.toStringAsFixed(2)}/L'
                                : '${a.litros.toStringAsFixed(1)} L',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          Text(
                            a.tipoCombustivel.label,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${_formatarData(a.data)} · ${a.kmAtual} km',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          if (referencia.distancia != null)
                            Text(
                              referencia.consumo != null
                                  ? '${referencia.distancia} km percorridos · ${referencia.consumo!.toStringAsFixed(1)} km/L'
                                  : '${referencia.distancia} km percorridos',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kAccentColor),
                            ),
                        ],
                      ),
                      if (a.posto != null && a.posto!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          a.posto!,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todos = context.watch<AbastecimentoProvider>().abastecimentos;
    final provider = context.read<AbastecimentoProvider>();
    final mesAtual = chaveMesAtual();

    final doMes = todos.where((a) => chaveMes(a.data) == _mesSelecionado).toList()
      ..sort((a, b) => b.kmAtual.compareTo(a.kmAtual));
    final doMesAnterior = todos.where((a) => chaveMes(a.data) == passoMes(_mesSelecionado, -1)).toList();

    final stats = _statsDoMes(todos, doMes);
    final statsAnterior = _statsDoMes(todos, doMesAnterior);

    final outrosMeses = {for (final a in todos) chaveMes(a.data)}.where((c) => c != _mesSelecionado).toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          _navegadorMes(context, mesAtual),
          const SizedBox(height: 12),
          if (doMes.isNotEmpty) ...[
            _statsGrid(context, stats, statsAnterior),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: () {
              final abastecimentoProvider = context.read<AbastecimentoProvider>();
              final navigator = Navigator.of(context);
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => CalculadoraCombustivelScreen(
                    consumoSugerido: ConsumoService.consumoPeriodo(todos),
                    aoRegistrarAbastecimento: (litros, valorTotal) {
                      navigator.pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: abastecimentoProvider,
                            child: AbastecimentoFormScreen(
                              litrosInicial: litros,
                              valorTotalInicial: valorTotal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calcular viagem'),
          ),
          const SizedBox(height: 12),
          if (doMes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.local_gas_station,
                        size: 24, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sem registros em ${formatarChaveMes(_mesSelecionado)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Navegue para outro mês ou registre um abastecimento',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              'REGISTROS — ${formatarChaveMes(_mesSelecionado).toUpperCase()}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            for (final a in doMes) _cardRegistro(context, a, todos, provider),
          ],
          if (outrosMeses.isNotEmpty) ...[
            const SizedBox(height: 8),
            _historicoPorMes(context, todos, outrosMeses),
          ],
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
  final Widget? comparacao;

  const _CardEstatistica({required this.rotulo, required this.valor, this.comparacao});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(rotulo.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(valor, style: Theme.of(context).textTheme.headlineSmall),
            if (comparacao != null) ...[
              const SizedBox(height: 2),
              comparacao!,
            ],
          ],
        ),
      ),
    );
  }
}
