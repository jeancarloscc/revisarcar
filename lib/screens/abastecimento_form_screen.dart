import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/abastecimento.dart';
import '../providers/abastecimento_provider.dart';

class AbastecimentoFormScreen extends StatefulWidget {
  final Abastecimento? abastecimento;
  final double? litrosInicial;
  final double? valorTotalInicial;

  const AbastecimentoFormScreen({
    super.key,
    this.abastecimento,
    this.litrosInicial,
    this.valorTotalInicial,
  });

  @override
  State<AbastecimentoFormScreen> createState() => _AbastecimentoFormScreenState();
}

class _AbastecimentoFormScreenState extends State<AbastecimentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kmAtualController;
  late final TextEditingController _litrosController;
  late final TextEditingController _valorTotalController;
  late DateTime _data;
  late bool _tanqueCheio;
  bool _salvando = false;

  bool get _editando => widget.abastecimento != null;

  @override
  void initState() {
    super.initState();
    final a = widget.abastecimento;
    _data = a?.data ?? DateTime.now();
    _kmAtualController = TextEditingController(text: a?.kmAtual.toString() ?? '');
    _litrosController = TextEditingController(
      text: a?.litros.toString() ?? widget.litrosInicial?.toStringAsFixed(2) ?? '',
    );
    _valorTotalController = TextEditingController(
      text: a?.valorTotal.toString() ?? widget.valorTotalInicial?.toStringAsFixed(2) ?? '',
    );
    _tanqueCheio = a?.tanqueCheio ?? true;
  }

  @override
  void dispose() {
    _kmAtualController.dispose();
    _litrosController.dispose();
    _valorTotalController.dispose();
    super.dispose();
  }

  String? _obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  String? _inteiroObrigatorio(String? valor) {
    final erro = _obrigatorio(valor);
    if (erro != null) return erro;
    if (int.tryParse(valor!.trim()) == null) return 'Informe um número válido';
    return null;
  }

  String? _decimalObrigatorio(String? valor) {
    final erro = _obrigatorio(valor);
    if (erro != null) return erro;
    if (double.tryParse(valor!.trim().replaceAll(',', '.')) == null) {
      return 'Informe um valor válido';
    }
    return null;
  }

  Future<void> _selecionarData() async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selecionada != null) {
      setState(() => _data = selecionada);
    }
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
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
    final abastecimento = Abastecimento(
      id: widget.abastecimento?.id ?? '',
      veiculoId: widget.abastecimento?.veiculoId ?? '',
      data: _data,
      kmAtual: int.parse(_kmAtualController.text.trim()),
      litros: double.parse(_litrosController.text.trim().replaceAll(',', '.')),
      valorTotal: double.parse(_valorTotalController.text.trim().replaceAll(',', '.')),
      tanqueCheio: _tanqueCheio,
    );

    try {
      final provider = context.read<AbastecimentoProvider>();
      if (_editando) {
        await provider.atualizar(abastecimento);
      } else {
        await provider.adicionar(abastecimento);
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
    final litros = double.tryParse(_litrosController.text.replaceAll(',', '.'));
    final valorTotal = double.tryParse(_valorTotalController.text.replaceAll(',', '.'));

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar abastecimento' : 'Novo abastecimento')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _rotulo('Data'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_formatarData(_data)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selecionarData,
            ),
            const SizedBox(height: 12),
            _rotulo('Km atual'),
            TextFormField(
              controller: _kmAtualController,
              keyboardType: TextInputType.number,
              validator: _inteiroObrigatorio,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _rotulo('Litros'),
            TextFormField(
              controller: _litrosController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _decimalObrigatorio,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _rotulo('Valor total (R\$)'),
            TextFormField(
              controller: _valorTotalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _decimalObrigatorio,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tanque cheio'),
              value: _tanqueCheio,
              onChanged: (valor) => setState(() => _tanqueCheio = valor),
            ),
            if (litros != null && litros > 0 && valorTotal != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_gas_station, size: 16, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Preço por litro', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Text(
                      'R\$ ${(valorTotal / litros).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
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
