import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/lembrete_manutencao.dart';
import 'package:revisacar/models/manutencao.dart';
import 'package:revisacar/providers/lembrete_provider.dart';
import 'package:revisacar/repositories/lembrete_repository.dart';

void main() {
  test('escutarVeiculo carrega os lembretes daquele veículo', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = LembreteRepository(firestore);
    final provider = LembreteProvider(repository: repository, uid: 'uid1');

    provider.escutarVeiculo('v1');
    await provider.adicionar(LembreteManutencao(
      id: '',
      veiculoId: 'v1',
      tipoManutencao: TipoManutencao.trocaOleo,
      intervaloKm: 10000,
      antecedenciaKm: 500,
      antecedenciaDias: 0,
      intervaloRepeticaoDias: 3,
      ativo: true,
    ));
    await Future<void>.delayed(Duration.zero);

    expect(provider.lembretes, hasLength(1));
  });
}
