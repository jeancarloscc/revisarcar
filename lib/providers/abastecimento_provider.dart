import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/abastecimento.dart';
import '../repositories/abastecimento_repository.dart';
import '../repositories/veiculo_repository.dart';

class AbastecimentoProvider extends ChangeNotifier {
  final AbastecimentoRepository _repository;
  final VeiculoRepository _veiculoRepository;
  final String uid;

  String? _veiculoId;
  List<Abastecimento> _abastecimentos = [];
  StreamSubscription<List<Abastecimento>>? _subscription;

  AbastecimentoProvider({
    required AbastecimentoRepository repository,
    required VeiculoRepository veiculoRepository,
    required this.uid,
  })  : _repository = repository,
        _veiculoRepository = veiculoRepository;

  List<Abastecimento> get abastecimentos => _abastecimentos;

  void escutarVeiculo(String veiculoId) {
    if (_veiculoId == veiculoId) return;
    _veiculoId = veiculoId;
    _subscription?.cancel();
    _subscription = _repository.watchAll(uid, veiculoId: veiculoId).listen((lista) {
      _abastecimentos = lista;
      notifyListeners();
    });
  }

  Future<void> adicionar(Abastecimento abastecimento) async {
    await _repository.add(uid, abastecimento, veiculoId: _veiculoId);
    await _sincronizarKmDoVeiculo(abastecimento.kmAtual);
  }

  Future<void> atualizar(Abastecimento abastecimento) async {
    await _repository.update(uid, abastecimento.id, abastecimento, veiculoId: _veiculoId);
    await _sincronizarKmDoVeiculo(abastecimento.kmAtual);
  }

  Future<void> remover(String id) {
    return _repository.delete(uid, id, veiculoId: _veiculoId);
  }

  /// Propaga o km do abastecimento para o veículo. É um efeito colateral: o
  /// abastecimento já foi gravado quando isso roda, então uma falha aqui não
  /// pode ser reportada como falha de salvamento (o usuário tentaria de novo e
  /// duplicaria o registro).
  Future<void> _sincronizarKmDoVeiculo(int km) async {
    try {
      await _atualizarKmSeNecessario(km);
    } catch (erro, stack) {
      debugPrint('Falha ao sincronizar km do veículo: $erro\n$stack');
    }
  }

  Future<void> _atualizarKmSeNecessario(int km) async {
    if (_veiculoId == null) return;
    final veiculo = await _veiculoRepository.get(uid, _veiculoId!);
    if (veiculo != null && km > veiculo.kmAtual) {
      await _veiculoRepository.update(uid, _veiculoId!, veiculo.copyWith(kmAtual: km));
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
