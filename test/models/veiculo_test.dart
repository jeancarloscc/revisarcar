import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/veiculo.dart';
import 'package:revisacar/models/intervalo_manutencao.dart';
import 'package:revisacar/models/manutencao.dart';

void main() {
  group('Veiculo', () {
    test('fromMap/toMap round-trip preserva todos os campos', () {
      const veiculo = Veiculo(
        id: 'v1',
        nome: 'Meu HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
        fotoUrl: 'https://example.com/foto.jpg',
      );

      final map = veiculo.toMap();
      final restaurado = Veiculo.fromMap('v1', map);

      expect(restaurado, veiculo);
    });

    test('fromMap usa TipoVeiculo.carro como fallback se o valor for desconhecido', () {
      final map = {
        'nome': 'X',
        'modelo': 'Y',
        'ano': 2020,
        'placa': 'ZZZ',
        'kmAtual': 0,
        'tipoVeiculo': 'valor_invalido',
      };

      final veiculo = Veiculo.fromMap('v1', map);

      expect(veiculo.tipoVeiculo, TipoVeiculo.carro);
    });

    test('fotoUrl é nula quando ausente do map', () {
      final map = {
        'nome': 'X',
        'modelo': 'Y',
        'ano': 2020,
        'placa': 'ZZZ',
        'kmAtual': 0,
        'tipoVeiculo': 'moto',
      };

      final veiculo = Veiculo.fromMap('v1', map);

      expect(veiculo.fotoUrl, isNull);
      expect(veiculo.tipoVeiculo, TipoVeiculo.moto);
    });

    test('copyWith troca só os campos informados', () {
      const veiculo = Veiculo(
        id: 'v1',
        nome: 'Meu HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
      );

      final atualizado = veiculo.copyWith(kmAtual: 46000);

      expect(atualizado.kmAtual, 46000);
      expect(atualizado.nome, veiculo.nome);
    });

    test('intervalosPersonalizados: fromMap/toMap round-trip preserva os valores', () {
      const veiculo = Veiculo(
        id: 'v1',
        nome: 'Meu HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
        intervalosPersonalizados: {
          TipoManutencao.trocaOleo: IntervaloManutencao(km: 8000, dias: 180),
          TipoManutencao.bateria: IntervaloManutencao(dias: 720),
        },
      );

      final map = veiculo.toMap();
      final restaurado = Veiculo.fromMap('v1', map);

      expect(restaurado, veiculo);
      expect(restaurado.intervalosPersonalizados[TipoManutencao.trocaOleo],
          const IntervaloManutencao(km: 8000, dias: 180));
    });

    test('intervalosPersonalizados: fromMap não quebra quando o mapa aninhado vem como Map<Object?, Object?>', () {
      final Map<Object?, Object?> intervalosDinamicos = {
        'trocaOleo': <Object?, Object?>{'km': 8000, 'dias': 180},
      };
      final map = <String, dynamic>{
        'nome': 'X',
        'modelo': 'Y',
        'ano': 2020,
        'placa': 'ZZZ',
        'kmAtual': 0,
        'tipoVeiculo': 'carro',
        'intervalosPersonalizados': intervalosDinamicos,
      };

      final veiculo = Veiculo.fromMap('v1', map);

      expect(veiculo.intervalosPersonalizados[TipoManutencao.trocaOleo],
          const IntervaloManutencao(km: 8000, dias: 180));
    });

    test('intervalosPersonalizados é vazio quando ausente do map', () {
      final map = {
        'nome': 'X',
        'modelo': 'Y',
        'ano': 2020,
        'placa': 'ZZZ',
        'kmAtual': 0,
        'tipoVeiculo': 'carro',
      };

      final veiculo = Veiculo.fromMap('v1', map);

      expect(veiculo.intervalosPersonalizados, isEmpty);
    });
  });
}
