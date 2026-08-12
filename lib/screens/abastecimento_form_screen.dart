import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/abastecimento.dart';
import '../providers/abastecimento_provider.dart';
import '../theme/app_theme.dart';
import '../utils/tipo_combustivel_labels.dart';

enum _CampoAbastecimento { precoLitro, litros, valorTotal }

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
  late final TextEditingController _precoLitroController;
  late final TextEditingController _litrosController;
  late final TextEditingController _valorTotalController;
  late final TextEditingController _postoController;
  late DateTime _data;
  late bool _tanqueCheio;
  late TipoCombustivel _tipoCombustivel;
  _CampoAbastecimento? _campoCalculado;
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
    _precoLitroController = TextEditingController();
    final litrosIniciais = a?.litros ?? widget.litrosInicial;
    final valorTotalInicial = a?.valorTotal ?? widget.valorTotalInicial;
    if (litrosIniciais != null && litrosIniciais > 0 && valorTotalInicial != null) {
      _precoLitroController.text = (valorTotalInicial / litrosIniciais).toStringAsFixed(2);
      _campoCalculado = _CampoAbastecimento.precoLitro;
    }
    _postoController = TextEditingController(text: a?.posto ?? '');
    _tanqueCheio = a?.tanqueCheio ?? true;
    _tipoCombustivel = a?.tipoCombustivel ?? TipoCombustivel.gasolina;
  }

  @override
  void dispose() {
    _kmAtualController.dispose();
    _precoLitroController.dispose();
    _litrosController.dispose();
    _valorTotalController.dispose();
    _postoController.dispose();
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

  Widget _rotulo(String texto, {bool calculado = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Flexible(
              child: Text(
                texto.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey.shade600),
              ),
            ),
            if (calculado) ...[
              const SizedBox(width: 6),
              const Text(
                '(calculado)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kAccentColor),
              ),
            ],
          ],
        ),
      );

  InputDecoration? _decoracaoCampo(_CampoAbastecimento campo) {
    if (_campoCalculado != campo) return null;
    return InputDecoration(filled: true, fillColor: kAccentColor.withValues(alpha: 0.08));
  }

  double? _valorDoCampo(_CampoAbastecimento campo) {
    final texto = switch (campo) {
      _CampoAbastecimento.precoLitro => _precoLitroController.text,
      _CampoAbastecimento.litros => _litrosController.text,
      _CampoAbastecimento.valorTotal => _valorTotalController.text,
    };
    return double.tryParse(texto.trim().replaceAll(',', '.'));
  }

  void _definirValorDoCampo(_CampoAbastecimento campo, double valor) {
    final texto = valor.toStringAsFixed(2);
    switch (campo) {
      case _CampoAbastecimento.precoLitro:
        _precoLitroController.text = texto;
      case _CampoAbastecimento.litros:
        _litrosController.text = texto;
      case _CampoAbastecimento.valorTotal:
        _valorTotalController.text = texto;
    }
  }

  double? _calcularCampo(_CampoAbastecimento campo, {required double? preco, required double? litros, required double? total}) {
    switch (campo) {
      case _CampoAbastecimento.precoLitro:
        if (litros != null && litros > 0 && total != null && total >= 0) return total / litros;
        return null;
      case _CampoAbastecimento.litros:
        if (preco != null && preco > 0 && total != null && total >= 0) return total / preco;
        return null;
      case _CampoAbastecimento.valorTotal:
        if (preco != null && preco >= 0 && litros != null && litros >= 0) return preco * litros;
        return null;
    }
  }

  void _aoEditarCampoFuel(_CampoAbastecimento campoEditado) {
    setState(() {
      if (campoEditado == _campoCalculado) {
        // Usuário sobrescreveu manualmente o campo que era calculado: ele vira campo manual
        // e nenhum campo fica marcado como calculado até um deles ser esvaziado de novo.
        _campoCalculado = null;
        return;
      }

      final outros = _CampoAbastecimento.values.where((c) => c != campoEditado).toList();
      var alvo = _campoCalculado != null && outros.contains(_campoCalculado) ? _campoCalculado : null;
      if (alvo == null) {
        final vazios = outros.where((c) => _valorDoCampo(c) == null).toList();
        if (vazios.length == 1) alvo = vazios.first;
      }

      if (alvo == null) {
        _campoCalculado = null;
        return;
      }

      final resultado = _calcularCampo(
        alvo,
        preco: _valorDoCampo(_CampoAbastecimento.precoLitro),
        litros: _valorDoCampo(_CampoAbastecimento.litros),
        total: _valorDoCampo(_CampoAbastecimento.valorTotal),
      );
      if (resultado == null || !resultado.isFinite) {
        _campoCalculado = null;
        return;
      }

      _definirValorDoCampo(alvo, resultado);
      _campoCalculado = alvo;
    });
  }

  Abastecimento? _ultimoExistente(List<Abastecimento> abastecimentos) {
    final outros = abastecimentos.where((a) => a.id != widget.abastecimento?.id).toList();
    if (outros.isEmpty) return null;
    outros.sort((a, b) => a.kmAtual.compareTo(b.kmAtual));
    return outros.last;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    final posto = _postoController.text.trim();
    final abastecimento = Abastecimento(
      id: widget.abastecimento?.id ?? '',
      veiculoId: widget.abastecimento?.veiculoId ?? '',
      data: _data,
      kmAtual: int.parse(_kmAtualController.text.trim()),
      litros: double.parse(_litrosController.text.trim().replaceAll(',', '.')),
      valorTotal: double.parse(_valorTotalController.text.trim().replaceAll(',', '.')),
      tanqueCheio: _tanqueCheio,
      posto: posto.isEmpty ? null : posto,
      tipoCombustivel: _tipoCombustivel,
    );

    try {
      final provider = context.read<AbastecimentoProvider>();
      if (_editando) {
        await provider.atualizar(abastecimento);
      } else {
        await provider.adicionar(abastecimento);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (erro, stack) {
      debugPrint('Erro ao salvar abastecimento: $erro\n$stack');
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
    final abastecimentos = context.watch<AbastecimentoProvider>().abastecimentos;
    final ultimoExistente = _ultimoExistente(abastecimentos);

    final litros = _valorDoCampo(_CampoAbastecimento.litros);
    final valorTotal = _valorDoCampo(_CampoAbastecimento.valorTotal);
    final kmDigitado = int.tryParse(_kmAtualController.text.trim());

    final avisoKm =
        ultimoExistente != null && kmDigitado != null && kmDigitado <= ultimoExistente.kmAtual;

    int? distancia;
    double? consumoReal;
    if (ultimoExistente != null && kmDigitado != null && kmDigitado > ultimoExistente.kmAtual) {
      distancia = kmDigitado - ultimoExistente.kmAtual;
      if (_tanqueCheio && ultimoExistente.tanqueCheio && litros != null && litros > 0) {
        consumoReal = distancia / litros;
      }
    }

    final podeSalvar = litros != null && litros > 0 && valorTotal != null && kmDigitado != null;

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar abastecimento' : 'Novo abastecimento')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _rotulo('Combustível'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TipoCombustivel.values.map((tipo) {
                final selecionado = tipo == _tipoCombustivel;
                return ChoiceChip(
                  label: Text(tipo.label),
                  selected: selecionado,
                  onSelected: (_) => setState(() => _tipoCombustivel = tipo),
                  selectedColor: kAccentColor.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selecionado ? kAccentColor : null,
                  ),
                  side: BorderSide(
                    color: selecionado ? kAccentColor : Colors.grey.shade300,
                    width: selecionado ? 2 : 1,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
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
            if (avisoKm) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 14, color: kStatusAlertaTexto),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Km menor ou igual ao último registro (${ultimoExistente.kmAtual} km).',
                      style: const TextStyle(fontSize: 12, color: kStatusAlertaTexto),
                    ),
                  ),
                ],
              ),
            ] else if (distancia != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.route, size: 14, color: kAccentColor),
                  const SizedBox(width: 6),
                  Text(
                    'Distância percorrida: $distancia km',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kAccentColor),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _rotulo('Preço por litro (R\$)', calculado: _campoCalculado == _CampoAbastecimento.precoLitro),
            TextFormField(
              controller: _precoLitroController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _decoracaoCampo(_CampoAbastecimento.precoLitro),
              onChanged: (_) => _aoEditarCampoFuel(_CampoAbastecimento.precoLitro),
            ),
            const SizedBox(height: 12),
            _rotulo('Litros', calculado: _campoCalculado == _CampoAbastecimento.litros),
            TextFormField(
              controller: _litrosController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _decoracaoCampo(_CampoAbastecimento.litros),
              onChanged: (_) => _aoEditarCampoFuel(_CampoAbastecimento.litros),
            ),
            const SizedBox(height: 12),
            _rotulo('Valor total (R\$)', calculado: _campoCalculado == _CampoAbastecimento.valorTotal),
            TextFormField(
              controller: _valorTotalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _decoracaoCampo(_CampoAbastecimento.valorTotal),
              onChanged: (_) => _aoEditarCampoFuel(_CampoAbastecimento.valorTotal),
            ),
            const SizedBox(height: 12),
            _rotulo('Posto (opcional)'),
            TextFormField(controller: _postoController),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tanque cheio'),
              value: _tanqueCheio,
              onChanged: (valor) => setState(() => _tanqueCheio = valor),
            ),
            if (consumoReal != null) ...[
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
                        const Icon(Icons.speed, size: 16, color: kAccentColor),
                        const SizedBox(width: 8),
                        const Text('Consumo médio', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Text(
                      '${consumoReal.toStringAsFixed(1)} km/L',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: podeSalvar && !_salvando ? _salvar : null,
              child: Text(_salvando ? 'Salvando...' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
