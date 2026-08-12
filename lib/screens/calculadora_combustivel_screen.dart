import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../services/calculadora_combustivel_service.dart';
import '../theme/app_theme.dart';

enum _ModoCalculo { direto, orcamento }

class CalculadoraCombustivelScreen extends StatefulWidget {
  final double? consumoSugerido;
  final void Function(double litros, double valorTotal)?
  aoRegistrarAbastecimento;

  const CalculadoraCombustivelScreen({
    super.key,
    this.consumoSugerido,
    this.aoRegistrarAbastecimento,
  });

  @override
  State<CalculadoraCombustivelScreen> createState() =>
      _CalculadoraCombustivelScreenState();
}

class _CalculadoraCombustivelScreenState
    extends State<CalculadoraCombustivelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _precoController = TextEditingController();
  final _consumoController = TextEditingController();
  final _distanciaController = TextEditingController();
  final _valorDisponivelController = TextEditingController();
  _ModoCalculo _modo = _ModoCalculo.direto;
  bool _idaEVolta = false;

  @override
  void initState() {
    super.initState();
    if (widget.consumoSugerido != null) {
      _consumoController.text = widget.consumoSugerido!.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _precoController.dispose();
    _consumoController.dispose();
    _distanciaController.dispose();
    _valorDisponivelController.dispose();
    super.dispose();
  }

  String? _obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
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

  Widget _rotulo(String texto, {Widget? acao}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          texto.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.grey.shade600,
          ),
        ),
        ?acao,
      ],
    ),
  );

  Widget _buildButton({
    required String text,
    required IconData icon,
    required _ModoCalculo modo,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _modo == modo;
    final larguraTela = MediaQuery.of(context).size.width;
    final compacto = larguraTela < 360;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => setState(() => _modo = modo),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compacto ? 2 : 10,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: compacto ? 16 : 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: compacto ? 8 : 10,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preco = double.tryParse(_precoController.text.replaceAll(',', '.'));
    final consumo = double.tryParse(
      _consumoController.text.replaceAll(',', '.'),
    );

    final resultadoDireto =
        _modo == _ModoCalculo.direto && preco != null && consumo != null
        ? CalculadoraCombustivelService.calculoDireto(
            distanciaKm:
                double.tryParse(
                  _distanciaController.text.replaceAll(',', '.'),
                ) ??
                0,
            consumoKmPorLitro: consumo,
            precoPorLitro: preco,
            idaEVolta: _idaEVolta,
          )
        : null;

    final resultadoOrcamento =
        _modo == _ModoCalculo.orcamento && preco != null && consumo != null
        ? CalculadoraCombustivelService.calculoPorOrcamento(
            valorDisponivel:
                double.tryParse(
                  _valorDisponivelController.text.replaceAll(',', '.'),
                ) ??
                0,
            consumoKmPorLitro: consumo,
            precoPorLitro: preco,
          )
        : null;

    final resultadoParaRegistro = resultadoDireto != null
        ? (
            litros: resultadoDireto.litros,
            valorTotal: resultadoDireto.valorTotal,
          )
        : resultadoOrcamento != null
        ? (
            litros: resultadoOrcamento.litros,
            valorTotal:
                double.tryParse(
                  _valorDisponivelController.text.replaceAll(',', '.'),
                ) ??
                0,
          )
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora de combustível')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  _buildButton(
                    text: "Distância → Gasto",
                    icon: Symbols.route,
                    modo: _ModoCalculo.direto,
                  ),
                  const SizedBox(width: 4),
                  _buildButton(
                    text: "Orçamento → Alcance",
                    icon: Symbols.account_balance_wallet,
                    modo: _ModoCalculo.orcamento,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _rotulo(
              'Consumo médio (km/L)',
              acao: widget.consumoSugerido != null
                  ? TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                      ),
                      onPressed: () => setState(
                        () => _consumoController.text = widget.consumoSugerido!
                            .toStringAsFixed(1),
                      ),
                      child: Text(
                        'Usar ${widget.consumoSugerido!.toStringAsFixed(1)} km/L',
                      ),
                    )
                  : null,
            ),
            TextFormField(
              controller: _consumoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _decimalObrigatorio,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                suffixText: 'km/L',
                hintText: 'Ex: 12.5',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(32)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (widget.consumoSugerido != null) ...[
              const SizedBox(height: 4),
              Text(
                'Média registrada do veículo: ${widget.consumoSugerido!.toStringAsFixed(1)} km/L',
                style: const TextStyle(fontSize: 11, color: Colors.redAccent),
              ),
            ],
            const SizedBox(height: 12),
            _rotulo('Preço por Litro (R\$)'),
            TextFormField(
              controller: _precoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _decimalObrigatorio,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (_modo == _ModoCalculo.direto) ...[
              _rotulo('Distância (km)'),
              TextFormField(
                controller: _distanciaController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _decimalObrigatorio,
                onChanged: (_) => setState(() {}),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ida e volta'),
                value: _idaEVolta,
                onChanged: (valor) => setState(() => _idaEVolta = valor),
              ),
            ] else ...[
              _rotulo('Valor disponível (R\$)'),
              TextFormField(
                controller: _valorDisponivelController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _decimalObrigatorio,
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (resultadoDireto != null) ...[
              const SizedBox(height: 20),
              _CardResultado(
                linhas: [
                  (
                    'Litros necessários',
                    '${resultadoDireto.litros.toStringAsFixed(2)} L',
                  ),
                  (
                    'Valor total',
                    'R\$ ${resultadoDireto.valorTotal.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ],
            if (resultadoOrcamento != null) ...[
              const SizedBox(height: 20),
              _CardResultado(
                linhas: [
                  (
                    'Litros comprados',
                    '${resultadoOrcamento.litros.toStringAsFixed(2)} L',
                  ),
                  (
                    'Distância alcançável',
                    '${resultadoOrcamento.kmAlcancaveis.toStringAsFixed(0)} km',
                  ),
                ],
              ),
            ],
            if (resultadoParaRegistro != null &&
                widget.aoRegistrarAbastecimento != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => widget.aoRegistrarAbastecimento!(
                  resultadoParaRegistro.litros,
                  resultadoParaRegistro.valorTotal,
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Registrar este abastecimento'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardResultado extends StatelessWidget {
  final List<(String, String)> linhas;

  const _CardResultado({required this.linhas});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (rotulo, valor) in linhas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_gas_station,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        rotulo,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(valor, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
