import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/veiculo.dart';
import '../repositories/veiculo_repository.dart';

class VeiculoProvider extends ChangeNotifier {
  static const _activeVeiculoIdKey = 'active_veiculo_id';

  final VeiculoRepository _repository;
  final SharedPreferences _prefs;
  final String uid;

  List<Veiculo> _veiculos = [];
  String? _veiculoAtivoId;
  StreamSubscription<List<Veiculo>>? _subscription;

  VeiculoProvider({
    required VeiculoRepository repository,
    required SharedPreferences prefs,
    required this.uid,
  })  : _repository = repository,
        _prefs = prefs {
    _veiculoAtivoId = _prefs.getString(_activeVeiculoIdKey);
    _subscription = _repository.watchAll(uid).listen(_onVeiculosChanged);
  }

  List<Veiculo> get veiculos => _veiculos;

  Veiculo? get veiculoAtivo {
    for (final v in _veiculos) {
      if (v.id == _veiculoAtivoId) return v;
    }
    return null;
  }

  void _onVeiculosChanged(List<Veiculo> veiculos) {
    _veiculos = veiculos;
    final aindaExiste = _veiculos.any((v) => v.id == _veiculoAtivoId);
    if (_veiculoAtivoId == null || !aindaExiste) {
      _veiculoAtivoId = _veiculos.isNotEmpty ? _veiculos.first.id : null;
    }
    notifyListeners();
  }

  Future<void> selecionarVeiculo(String veiculoId) async {
    _veiculoAtivoId = veiculoId;
    await _prefs.setString(_activeVeiculoIdKey, veiculoId);
    notifyListeners();
  }

  Future<void> adicionar(Veiculo veiculo) {
    return _repository.add(uid, veiculo);
  }

  Future<void> atualizar(String id, Veiculo veiculo) {
    return _repository.update(uid, id, veiculo);
  }

  Future<void> remover(String id) {
    return _repository.remover(uid, id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
