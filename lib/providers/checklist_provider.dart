import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/checklist_item.dart';
import '../repositories/checklist_repository.dart';

class ChecklistProvider extends ChangeNotifier {
  final ChecklistRepository _repository;
  final String uid;

  String? _veiculoId;
  List<ChecklistItem> _checklistItems = [];
  StreamSubscription<List<ChecklistItem>>? _subscription;

  ChecklistProvider({required ChecklistRepository repository, required this.uid})
      : _repository = repository;

  List<ChecklistItem> get checklistItems => _checklistItems;

  void escutarVeiculo(String veiculoId) {
    if (_veiculoId == veiculoId) return;
    _veiculoId = veiculoId;
    _subscription?.cancel();
    _subscription = _repository.watchAll(uid, veiculoId: veiculoId).listen((lista) {
      _checklistItems = lista;
      notifyListeners();
    });
  }

  Future<void> adicionar(ChecklistItem item) {
    return _repository.add(uid, item, veiculoId: _veiculoId);
  }

  Future<void> remover(String id) {
    return _repository.delete(uid, id, veiculoId: _veiculoId);
  }

  Future<void> alternarVerificado(ChecklistItem item) {
    return _repository.update(
      uid,
      item.id,
      item.copyWith(verificado: !item.verificado),
      veiculoId: _veiculoId,
    );
  }

  Future<void> resetarTodos() async {
    for (final item in _checklistItems) {
      if (item.verificado) {
        await _repository.update(uid, item.id, item.copyWith(verificado: false),
            veiculoId: _veiculoId);
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
