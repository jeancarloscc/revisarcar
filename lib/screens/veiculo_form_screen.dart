import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/intervalo_manutencao.dart';
import '../models/manutencao.dart';
import '../models/veiculo.dart';
import '../providers/veiculo_provider.dart';
import '../utils/intervalo_padrao_manutencao.dart';
import '../utils/tipo_manutencao_labels.dart';
import '../utils/tipo_manutencao_visual.dart';

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

  Widget _rotulo(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          texto.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey.shade600),
        ),
      );

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

  String _resumoIntervalo(TipoManutencao tipo) {
    final km = _intervaloKmControllers[tipo]!.text.trim();
    final meses = _intervaloMesesControllers[tipo]!.text.trim();
    final partes = <String>[
      if (km.isNotEmpty) '$km km',
      if (meses.isNotEmpty) '$meses meses',
    ];
    return partes.isEmpty ? 'Não configurado' : partes.join(' · ');
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
            _rotulo('Nome'),
            TextFormField(controller: _nomeController, validator: _obrigatorio),
            const SizedBox(height: 12),
            _rotulo('Modelo'),
            TextFormField(controller: _modeloController, validator: _obrigatorio),
            const SizedBox(height: 12),
            _rotulo('Ano'),
            TextFormField(
              controller: _anoController,
              keyboardType: TextInputType.number,
              validator: _numeroObrigatorio,
            ),
            const SizedBox(height: 12),
            _rotulo('Placa'),
            TextFormField(controller: _placaController, validator: _obrigatorio),
            const SizedBox(height: 12),
            _rotulo('Km atual'),
            TextFormField(
              controller: _kmAtualController,
              keyboardType: TextInputType.number,
              validator: _numeroObrigatorio,
            ),
            const SizedBox(height: 12),
            _rotulo('Tipo de veículo'),
            Row(
              children: [
                Expanded(
                  child: _BotaoTipoVeiculo(
                    selecionado: _tipoVeiculo == TipoVeiculo.carro,
                    icone: Icons.directions_car,
                    rotulo: 'Carro',
                    onTap: () => setState(() => _tipoVeiculo = TipoVeiculo.carro),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BotaoTipoVeiculo(
                    selecionado: _tipoVeiculo == TipoVeiculo.moto,
                    icone: Icons.two_wheeler,
                    rotulo: 'Moto',
                    onTap: () => setState(() => _tipoVeiculo = TipoVeiculo.moto),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _rotulo('Intervalos de manutenção'),
            Text(
              'Usado para criar lembretes automáticos.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            for (final tipo in _tiposComIntervalo)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tipo.cor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tipo.icon, size: 18, color: tipo.cor),
                  ),
                  title: Text(tipo.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    _resumoIntervalo(tipo),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _intervaloKmControllers[tipo],
                              decoration: const InputDecoration(
                                labelText: 'Km',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              keyboardType: TextInputType.number,
                              validator: _inteiroOpcional,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _intervaloMesesControllers[tipo],
                              decoration: const InputDecoration(
                                labelText: 'Meses',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              keyboardType: TextInputType.number,
                              validator: _inteiroOpcional,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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

class _BotaoTipoVeiculo extends StatelessWidget {
  final bool selecionado;
  final IconData icone;
  final String rotulo;
  final VoidCallback onTap;

  const _BotaoTipoVeiculo({
    required this.selecionado,
    required this.icone,
    required this.rotulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selecionado ? colorScheme.primary : Colors.grey.shade300, width: selecionado ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 20, color: selecionado ? colorScheme.primary : Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              rotulo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selecionado ? colorScheme.primary : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
