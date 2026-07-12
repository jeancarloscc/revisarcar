import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/abastecimento.dart';
import 'package:revisacar/models/veiculo.dart';
import 'package:revisacar/providers/abastecimento_provider.dart';
import 'package:revisacar/repositories/abastecimento_repository.dart';
import 'package:revisacar/repositories/veiculo_repository.dart';

void main() {
  test('escutarVeiculo carrega os abastecimentos daquele veículo', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = AbastecimentoRepository(firestore);
    final provider = AbastecimentoProvider(
      repository: repository,
      veiculoRepository: VeiculoRepository(firestore),
      uid: 'uid1',
    );

    provider.escutarVeiculo('v1');
    await provider.adicionar(Abastecimento(
      id: '',
      veiculoId: 'v1',
      data: DateTime(2026, 1, 1),
      kmAtual: 40000,
      litros: 30,
      valorTotal: 180,
      tanqueCheio: true,
    ));
    await Future<void>.delayed(Duration.zero);

    expect(provider.abastecimentos, hasLength(1));
  });

  test('adicionar atualiza Veiculo.kmAtual quando o km do abastecimento é maior', () async {
    final firestore = FakeFirebaseFirestore();
    final veiculoRepository = VeiculoRepository(firestore);
    final veiculoId = await veiculoRepository.add(
      'uid1',
      const Veiculo(
        id: '',
        nome: 'HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 40000,
        tipoVeiculo: TipoVeiculo.carro,
      ),
    );
    final repository = AbastecimentoRepository(firestore);
    final provider = AbastecimentoProvider(
      repository: repository,
      veiculoRepository: veiculoRepository,
      uid: 'uid1',
    );
    provider.escutarVeiculo(veiculoId);

    await provider.adicionar(Abastecimento(
      id: '',
      veiculoId: veiculoId,
      data: DateTime(2026, 1, 1),
      kmAtual: 40500,
      litros: 30,
      valorTotal: 180,
      tanqueCheio: true,
    ));

    final veiculoAtualizado = await veiculoRepository.get('uid1', veiculoId);
    expect(veiculoAtualizado?.kmAtual, 40500);
  });
}
