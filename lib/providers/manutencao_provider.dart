import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/manutencao.dart';
import '../models/veiculo.dart';
import '../models/lembrete_manutencao.dart';
import '../repositories/manutencao_repository.dart';
import '../repositories/lembrete_repository.dart';
import '../repositories/veiculo_repository.dart';
import '../utils/intervalo_padrao_manutencao.dart';

class ManutencaoProvider extends ChangeNotifier {
  final ManutencaoRepository _repository;
  final VeiculoRepository _veiculoRepository;
  final LembreteRepository _lembreteRepository;
  final String uid;

  String? _veiculoId;
  List<Manutencao> _manutencoes = [];
  StreamSubscription<List<Manutencao>>? _subscription;

  ManutencaoProvider({
    required ManutencaoRepository repository,
    required VeiculoRepository veiculoRepository,
    required LembreteRepository lembreteRepository,
    required this.uid,
  })  : _repository = repository,
        _veiculoRepository = veiculoRepository,
        _lembreteRepository = lembreteRepository;

  List<Manutencao> get manutencoes => _manutencoes;

  void escutarVeiculo(String veiculoId) {
    if (_veiculoId == veiculoId) return;
    _veiculoId = veiculoId;
    _subscription?.cancel();
    _subscription = _repository.watchAll(uid, veiculoId: veiculoId).listen((lista) {
      _manutencoes = lista;
      notifyListeners();
    });
  }

  Future<void> adicionar(Manutencao manutencao) async {
    await _repository.add(uid, manutencao, veiculoId: _veiculoId);
    final veiculoId = _veiculoId;
    if (veiculoId == null) return;
    final veiculo = await _veiculoRepository.get(uid, veiculoId);
    if (veiculo == null) return;
    if (manutencao.kmNaData > veiculo.kmAtual) {
      await _veiculoRepository.update(uid, veiculoId, veiculo.copyWith(kmAtual: manutencao.kmNaData));
    }
    await _criarLembreteSeNecessario(veiculo, manutencao.tipo);
  }

  Future<void> _criarLembreteSeNecessario(Veiculo veiculo, TipoManutencao tipo) async {
    final intervalo = intervaloEfetivo(veiculo, tipo);
    if (intervalo == null || intervalo.vazio) return;
    final existentes = await _lembreteRepository.getAll(uid, veiculoId: veiculo.id);
    final jaExiste = existentes.any((l) => l.tipoManutencao == tipo);
    if (jaExiste) return;
    await _lembreteRepository.add(
      uid,
      LembreteManutencao(
        id: '',
        veiculoId: veiculo.id,
        tipoManutencao: tipo,
        intervaloKm: intervalo.km,
        intervaloDias: intervalo.dias,
        antecedenciaKm: 500,
        antecedenciaDias: 15,
        intervaloRepeticaoDias: 3,
        ativo: true,
      ),
      veiculoId: veiculo.id,
    );
  }

  Future<void> atualizar(Manutencao manutencao) {
    return _repository.update(uid, manutencao.id, manutencao, veiculoId: _veiculoId);
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
