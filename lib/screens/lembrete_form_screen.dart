// lib/screens/lembrete_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lembrete_manutencao.dart';
import '../models/manutencao.dart';
import '../providers/lembrete_provider.dart';
import '../utils/tipo_manutencao_labels.dart';
import '../utils/tipo_manutencao_visual.dart';

class LembreteFormScreen extends StatefulWidget {
  final LembreteManutencao? lembrete;

  const LembreteFormScreen({super.key, this.lembrete});

  @override
  State<LembreteFormScreen> createState() => _LembreteFormScreenState();
}

class _LembreteFormScreenState extends State<LembreteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _intervaloKmController;
  late final TextEditingController _intervaloDiasController;
  late final TextEditingController _antecedenciaKmController;
  late final TextEditingController _antecedenciaDiasController;
  late final TextEditingController _intervaloRepeticaoDiasController;
  late TipoManutencao _tipoManutencao;
  late bool _ativo;
  bool _salvando = false;

  bool get _editando => widget.lembrete != null;

  @override
  void initState() {
    super.initState();
    final l = widget.lembrete;
    _tipoManutencao = l?.tipoManutencao ?? TipoManutencao.revisao;
    _intervaloKmController = TextEditingController(text: l?.intervaloKm?.toString() ?? '');
    _intervaloDiasController = TextEditingController(text: l?.intervaloDias?.toString() ?? '');
    _antecedenciaKmController = TextEditingController(text: l?.antecedenciaKm.toString() ?? '');
    _antecedenciaDiasController =
        TextEditingController(text: l?.antecedenciaDias.toString() ?? '');
    _intervaloRepeticaoDiasController =
        TextEditingController(text: l?.intervaloRepeticaoDias.toString() ?? '');
    _ativo = l?.ativo ?? true;
  }

  @override
  void dispose() {
    _intervaloKmController.dispose();
    _intervaloDiasController.dispose();
    _antecedenciaKmController.dispose();
    _antecedenciaDiasController.dispose();
    _intervaloRepeticaoDiasController.dispose();
    super.dispose();
  }

  String? _inteiroOpcional(String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;
    if (int.tryParse(valor.trim()) == null) return 'Informe um número válido';
    return null;
  }

  String? _validarIntervaloKm(String? valor) {
    final erroNumero = _inteiroOpcional(valor);
    if (erroNumero != null) return erroNumero;
    final semKm = valor == null || valor.trim().isEmpty;
    final semDias = _intervaloDiasController.text.trim().isEmpty;
    if (semKm && semDias) return 'Preencha km ou dias';
    return null;
  }

  String? _validarIntervaloDias(String? valor) {
    final erroNumero = _inteiroOpcional(valor);
    if (erroNumero != null) return erroNumero;
    final semDias = valor == null || valor.trim().isEmpty;
    final semKm = _intervaloKmController.text.trim().isEmpty;
    if (semKm && semDias) return 'Preencha km ou dias';
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
    final lembrete = LembreteManutencao(
      id: widget.lembrete?.id ?? '',
      veiculoId: widget.lembrete?.veiculoId ?? '',
      tipoManutencao: _tipoManutencao,
      intervaloKm: _intervaloKmController.text.trim().isEmpty
          ? null
          : int.parse(_intervaloKmController.text.trim()),
      intervaloDias: _intervaloDiasController.text.trim().isEmpty
          ? null
          : int.parse(_intervaloDiasController.text.trim()),
      antecedenciaKm: _antecedenciaKmController.text.trim().isEmpty
          ? 0
          : int.parse(_antecedenciaKmController.text.trim()),
      antecedenciaDias: _antecedenciaDiasController.text.trim().isEmpty
          ? 0
          : int.parse(_antecedenciaDiasController.text.trim()),
      intervaloRepeticaoDias: _intervaloRepeticaoDiasController.text.trim().isEmpty
          ? 3
          : int.parse(_intervaloRepeticaoDiasController.text.trim()),
      ativo: _ativo,
      resolvidoEm: widget.lembrete?.resolvidoEm,
    );

    try {
      final provider = context.read<LembreteProvider>();
      if (_editando) {
        await provider.atualizar(lembrete);
      } else {
        await provider.adicionar(lembrete);
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
      appBar: AppBar(title: Text(_editando ? 'Editar lembrete' : 'Novo lembrete')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _rotulo('Tipo de manutenção'),
            DropdownButtonFormField<TipoManutencao>(
              initialValue: _tipoManutencao,
              items: TipoManutencao.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.icon, size: 16, color: t.cor),
                            const SizedBox(width: 8),
                            Text(t.label),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (valor) =>
                  setState(() => _tipoManutencao = valor ?? TipoManutencao.revisao),
            ),
            const SizedBox(height: 12),
            _rotulo('Intervalo (km)'),
            TextFormField(
              controller: _intervaloKmController,
              keyboardType: TextInputType.number,
              validator: _validarIntervaloKm,
            ),
            const SizedBox(height: 12),
            _rotulo('Intervalo (dias)'),
            TextFormField(
              controller: _intervaloDiasController,
              keyboardType: TextInputType.number,
              validator: _validarIntervaloDias,
            ),
            const SizedBox(height: 12),
            _rotulo('Antecedência (km)'),
            TextFormField(
              controller: _antecedenciaKmController,
              keyboardType: TextInputType.number,
              validator: _inteiroOpcional,
            ),
            const SizedBox(height: 12),
            _rotulo('Antecedência (dias)'),
            TextFormField(
              controller: _antecedenciaDiasController,
              keyboardType: TextInputType.number,
              validator: _inteiroOpcional,
            ),
            const SizedBox(height: 12),
            _rotulo('Repetir notificação a cada (dias)'),
            TextFormField(
              controller: _intervaloRepeticaoDiasController,
              keyboardType: TextInputType.number,
              validator: _inteiroOpcional,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ativo'),
              value: _ativo,
              onChanged: (valor) => setState(() => _ativo = valor),
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
