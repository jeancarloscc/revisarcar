import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/veiculo.dart';
import 'package:revisacar/providers/veiculo_provider.dart';
import 'package:revisacar/repositories/veiculo_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('carrega veículos existentes e seleciona o primeiro como ativo', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = VeiculoRepository(firestore);
    await repository.add(
      'uid1',
      const Veiculo(
        id: '',
        nome: 'Meu HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final provider = VeiculoProvider(repository: repository, prefs: prefs, uid: 'uid1');

    await Future<void>.delayed(Duration.zero);

    expect(provider.veiculos, hasLength(1));
    expect(provider.veiculoAtivo?.nome, 'Meu HB20');
  });

  test('selecionarVeiculo troca o veículo ativo e persiste a escolha', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = VeiculoRepository(firestore);
    final id1 = await repository.add(
      'uid1',
      const Veiculo(
        id: '',
        nome: 'HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
      ),
    );
    final id2 = await repository.add(
      'uid1',
      const Veiculo(
        id: '',
        nome: 'Fiat Mobi',
        modelo: 'Fiat Mobi',
        ano: 2019,
        placa: 'XYZ9Z99',
        kmAtual: 30000,
        tipoVeiculo: TipoVeiculo.carro,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final provider = VeiculoProvider(repository: repository, prefs: prefs, uid: 'uid1');
    await Future<void>.delayed(Duration.zero);

    await provider.selecionarVeiculo(id2);

    expect(provider.veiculoAtivo?.id, id2);
    expect(provider.veiculoAtivo?.id, isNot(id1));
    expect(prefs.getString('active_veiculo_id'), id2);
  });

  test('adicionar grava um novo veículo e ele aparece na lista', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = VeiculoRepository(firestore);
    final prefs = await SharedPreferences.getInstance();
    final provider = VeiculoProvider(repository: repository, prefs: prefs, uid: 'uid1');
    await Future<void>.delayed(Duration.zero);

    await provider.adicionar(
      const Veiculo(
        id: '',
        nome: 'Nova Moto',
        modelo: 'Honda CG',
        ano: 2022,
        placa: 'MOT0123',
        kmAtual: 1000,
        tipoVeiculo: TipoVeiculo.moto,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(provider.veiculos, hasLength(1));
    expect(provider.veiculos.first.nome, 'Nova Moto');
  });

  test('atualizar altera os dados de um veículo existente', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = VeiculoRepository(firestore);
    final id = await repository.add(
      'uid1',
      const Veiculo(
        id: '',
        nome: 'HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    final provider = VeiculoProvider(repository: repository, prefs: prefs, uid: 'uid1');
    await Future<void>.delayed(Duration.zero);

    await provider.atualizar(id, provider.veiculos.first.copyWith(kmAtual: 46000));
    await Future<void>.delayed(Duration.zero);

    expect(provider.veiculos.first.kmAtual, 46000);
  });

  test('remover exclui o veículo e ele some da lista', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = VeiculoRepository(firestore);
    final id = await repository.add(
      'uid1',
      const Veiculo(
        id: '',
        nome: 'HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    final provider = VeiculoProvider(repository: repository, prefs: prefs, uid: 'uid1');
    await Future<void>.delayed(Duration.zero);

    await provider.remover(id);
    await Future<void>.delayed(Duration.zero);

    expect(provider.veiculos, isEmpty);
  });
}
