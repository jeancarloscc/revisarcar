import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lembrete_manutencao.dart';
import '../models/manutencao.dart';
import '../providers/lembrete_provider.dart';
import '../providers/manutencao_provider.dart';
import '../utils/tipo_manutencao_labels.dart';
import '../utils/tipo_manutencao_visual.dart';

class ManutencaoFormScreen extends StatefulWidget {
  final Manutencao? manutencao;
  final TipoManutencao? tipoInicial;
  final LembreteManutencao? lembreteParaResolver;

  const ManutencaoFormScreen({
    super.key,
    this.manutencao,
    this.tipoInicial,
    this.lembreteParaResolver,
  });

  @override
  State<ManutencaoFormScreen> createState() => _ManutencaoFormScreenState();
}

class _ManutencaoFormScreenState extends State<ManutencaoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kmNaDataController;
  late final TextEditingController _custoController;
  late final TextEditingController _oficinaController;
  late final TextEditingController _observacoesController;
  late final TextEditingController _descricaoOutroController;
  late TipoManutencao _tipo;
  late DateTime _dataRealizada;
  bool _salvando = false;

  bool get _editando => widget.manutencao != null;

  @override
  void initState() {
    super.initState();
    final m = widget.manutencao;
    _tipo = m?.tipo ?? widget.tipoInicial ?? TipoManutencao.revisao;
    _dataRealizada = m?.dataRealizada ?? DateTime.now();
    _kmNaDataController = TextEditingController(text: m?.kmNaData.toString() ?? '');
    _custoController = TextEditingController(text: m?.custo.toString() ?? '');
    _oficinaController = TextEditingController(text: m?.oficina ?? '');
    _observacoesController = TextEditingController(text: m?.observacoes ?? '');
    _descricaoOutroController = TextEditingController(text: m?.descricaoOutro ?? '');
  }

  @override
  void dispose() {
    _kmNaDataController.dispose();
    _custoController.dispose();
    _oficinaController.dispose();
    _observacoesController.dispose();
    _descricaoOutroController.dispose();
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

  String? _descricaoOutroValidator(String? valor) {
    if (_tipo != TipoManutencao.outro) return null;
    return _obrigatorio(valor);
  }

  Future<void> _selecionarData() async {
    if (!mounted) return;
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _dataRealizada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selecionada != null && mounted) {
      setState(() => _dataRealizada = selecionada);
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
    final manutencao = Manutencao(
      id: widget.manutencao?.id ?? '',
      veiculoId: widget.manutencao?.veiculoId ?? '',
      tipo: _tipo,
      descricaoOutro: _tipo == TipoManutencao.outro ? _descricaoOutroController.text.trim() : null,
      dataRealizada: _dataRealizada,
      kmNaData: int.parse(_kmNaDataController.text.trim()),
      custo: double.parse(_custoController.text.trim().replaceAll(',', '.')),
      oficina: _oficinaController.text.trim(),
      observacoes: _observacoesController.text.trim(),
    );

    try {
      final provider = context.read<ManutencaoProvider>();
      if (_editando) {
        await provider.atualizar(manutencao);
      } else {
        await provider.adicionar(manutencao);
      }
      final lembrete = widget.lembreteParaResolver;
      if (lembrete != null && mounted) {
        final lembreteProvider = context.read<LembreteProvider>();
        await lembreteProvider.atualizar(lembrete.copyWith(resolvidoEm: DateTime.now()));
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
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar manutenção' : 'Nova manutenção')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _rotulo('Tipo'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.6,
              children: TipoManutencao.values.map((tipo) {
                final selecionado = tipo == _tipo;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _tipo = tipo),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selecionado ? tipo.cor : Colors.grey.shade300,
                        width: selecionado ? 2 : 1,
                      ),
                      color: selecionado ? tipo.cor.withValues(alpha: 0.08) : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: tipo.cor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(tipo.icon, size: 16, color: tipo.cor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tipo.label,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_tipo == TipoManutencao.outro) ...[
              const SizedBox(height: 16),
              _rotulo('Descrição'),
              TextFormField(
                controller: _descricaoOutroController,
                validator: _descricaoOutroValidator,
              ),
            ],
            const SizedBox(height: 16),
            _rotulo('Oficina'),
            TextFormField(
              controller: _oficinaController,
              validator: _obrigatorio,
            ),
            const SizedBox(height: 12),
            _rotulo('Km na data'),
            TextFormField(
              controller: _kmNaDataController,
              keyboardType: TextInputType.number,
              validator: _inteiroObrigatorio,
            ),
            const SizedBox(height: 12),
            _rotulo('Custo (R\$)'),
            TextFormField(
              controller: _custoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _decimalObrigatorio,
            ),
            const SizedBox(height: 12),
            _rotulo('Data realizada'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_formatarData(_dataRealizada)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selecionarData,
            ),
            const SizedBox(height: 12),
            _rotulo('Observações'),
            TextFormField(
              controller: _observacoesController,
              maxLines: 3,
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
