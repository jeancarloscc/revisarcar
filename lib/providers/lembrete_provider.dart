import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/lembrete_manutencao.dart';
import '../repositories/lembrete_repository.dart';

class LembreteProvider extends ChangeNotifier {
  final LembreteRepository _repository;
  final String uid;

  String? _veiculoId;
  List<LembreteManutencao> _lembretes = [];
  StreamSubscription<List<LembreteManutencao>>? _subscription;

  LembreteProvider({required LembreteRepository repository, required this.uid})
      : _repository = repository;

  List<LembreteManutencao> get lembretes => _lembretes;

  void escutarVeiculo(String veiculoId) {
    if (_veiculoId == veiculoId) return;
    _veiculoId = veiculoId;
    _subscription?.cancel();
    _subscription = _repository.watchAll(uid, veiculoId: veiculoId).listen((lista) {
      _lembretes = lista;
      notifyListeners();
    });
  }

  Future<void> adicionar(LembreteManutencao lembrete) {
    return _repository.add(uid, lembrete, veiculoId: _veiculoId);
  }

  Future<void> atualizar(LembreteManutencao lembrete) {
    return _repository.update(uid, lembrete.id, lembrete, veiculoId: _veiculoId);
  }

  Future<void> remover(String id) {
    return _repository.delete(uid, id, veiculoId: _veiculoId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
