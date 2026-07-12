import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/veiculo.dart';
import 'package:revisacar/repositories/veiculo_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late VeiculoRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = VeiculoRepository(firestore);
  });

  group('VeiculoRepository', () {
    test('add grava o veículo e watchAll emite a lista atualizada', () async {
      const veiculo = Veiculo(
        id: '',
        nome: 'Meu HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
      );

      final id = await repository.add('uid1', veiculo);
      final lista = await repository.watchAll('uid1').first;

      expect(lista, hasLength(1));
      expect(lista.first.id, id);
      expect(lista.first.nome, 'Meu HB20');
    });

    test('update altera os campos do veículo', () async {
      const veiculo = Veiculo(
        id: '',
        nome: 'Meu HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
      );
      final id = await repository.add('uid1', veiculo);

      await repository.update('uid1', id, veiculo.copyWith(kmAtual: 46000));
      final lista = await repository.watchAll('uid1').first;

      expect(lista.first.kmAtual, 46000);
    });

    test('delete remove o veículo', () async {
      const veiculo = Veiculo(
        id: '',
        nome: 'X',
        modelo: 'Y',
        ano: 2020,
        placa: 'ZZZ',
        kmAtual: 0,
        tipoVeiculo: TipoVeiculo.moto,
      );
      final id = await repository.add('uid1', veiculo);

      await repository.delete('uid1', id);
      final lista = await repository.watchAll('uid1').first;

      expect(lista, isEmpty);
    });

    test('isola veículos por uid', () async {
      const veiculo = Veiculo(
        id: '',
        nome: 'X',
        modelo: 'Y',
        ano: 2020,
        placa: 'ZZZ',
        kmAtual: 0,
        tipoVeiculo: TipoVeiculo.carro,
      );
      await repository.add('uid1', veiculo);

      final listaOutroUsuario = await repository.watchAll('uid2').first;

      expect(listaOutroUsuario, isEmpty);
    });

    test('get retorna o veículo pelo id, ou null se não existir', () async {
      const veiculo = Veiculo(
        id: '',
        nome: 'Fiat Mobi',
        modelo: 'Fiat Mobi',
        ano: 2019,
        placa: 'XYZ9Z99',
        kmAtual: 30000,
        tipoVeiculo: TipoVeiculo.carro,
      );
      final id = await repository.add('uid1', veiculo);

      final encontrado = await repository.get('uid1', id);
      final inexistente = await repository.get('uid1', 'id-que-nao-existe');

      expect(encontrado?.nome, 'Fiat Mobi');
      expect(inexistente, isNull);
    });

    test('remover apaga o veículo e todos os documentos das subcoleções', () async {
      const veiculo = Veiculo(
        id: '',
        nome: 'Meu HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
      );
      final veiculoId = await repository.add('uid1', veiculo);

      final veiculoDoc = firestore
          .collection('users')
          .doc('uid1')
          .collection('veiculos')
          .doc(veiculoId);
      await veiculoDoc.collection('manutencoes').add({'tipo': 'trocaOleo'});
      await veiculoDoc.collection('abastecimentos').add({'litros': 40});
      await veiculoDoc.collection('lembretes').add({'ativo': true});
      await veiculoDoc.collection('checklistItems').add({'descricao': 'Óleo'});

      await repository.remover('uid1', veiculoId);

      final veiculoRestante = await repository.get('uid1', veiculoId);
      expect(veiculoRestante, isNull);
      expect((await veiculoDoc.collection('manutencoes').get()).docs, isEmpty);
      expect((await veiculoDoc.collection('abastecimentos').get()).docs, isEmpty);
      expect((await veiculoDoc.collection('lembretes').get()).docs, isEmpty);
      expect((await veiculoDoc.collection('checklistItems').get()).docs, isEmpty);
    });

    test('remover funciona mesmo quando o veículo não tem nenhum registro nas subcoleções', () async {
      const veiculo = Veiculo(
        id: '',
        nome: 'Sem registros',
        modelo: 'Y',
        ano: 2020,
        placa: 'ZZZ',
        kmAtual: 0,
        tipoVeiculo: TipoVeiculo.moto,
      );
      final veiculoId = await repository.add('uid1', veiculo);

      await repository.remover('uid1', veiculoId);

      final veiculoRestante = await repository.get('uid1', veiculoId);
      expect(veiculoRestante, isNull);
    });
  });
}
