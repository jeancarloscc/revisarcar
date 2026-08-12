import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/abastecimento.dart';
import 'package:revisacar/services/consumo_service.dart';

Abastecimento _abastecimento({
  required DateTime data,
  required int km,
  required double litros,
  required double valor,
  required bool tanqueCheio,
  String id = 'a',
}) {
  return Abastecimento(
    id: id,
    veiculoId: 'v1',
    data: data,
    kmAtual: km,
    litros: litros,
    valorTotal: valor,
    tanqueCheio: tanqueCheio,
  );
}

void main() {
  group('ConsumoService.consumoPorAbastecimento (4a)', () {
    test('calcula km/l quando ambos são tanque cheio', () {
      final anterior = _abastecimento(
          data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true);
      final atual = _abastecimento(
          data: DateTime(2026, 1, 15), km: 40400, litros: 40, valor: 240, tanqueCheio: true);

      final consumo = ConsumoService.consumoPorAbastecimento(atual, anterior);

      expect(consumo, 400 / 40);
    });

    test('retorna null quando o abastecimento anterior não foi tanque cheio', () {
      final anterior = _abastecimento(
          data: DateTime(2026, 1, 1), km: 40000, litros: 20, valor: 120, tanqueCheio: false);
      final atual = _abastecimento(
          data: DateTime(2026, 1, 15), km: 40400, litros: 40, valor: 240, tanqueCheio: true);

      final consumo = ConsumoService.consumoPorAbastecimento(atual, anterior);

      expect(consumo, isNull);
    });

    test('retorna null quando o abastecimento atual não é tanque cheio', () {
      final anterior = _abastecimento(
          data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true);
      final atual = _abastecimento(
          data: DateTime(2026, 1, 15), km: 40200, litros: 15, valor: 90, tanqueCheio: false);

      final consumo = ConsumoService.consumoPorAbastecimento(atual, anterior);

      expect(consumo, isNull);
    });

    test('retorna null quando km rodado não é positivo (dado inconsistente)', () {
      final anterior = _abastecimento(
          data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true);
      final atual = _abastecimento(
          data: DateTime(2026, 1, 15), km: 40000, litros: 40, valor: 240, tanqueCheio: true);

      final consumo = ConsumoService.consumoPorAbastecimento(atual, anterior);

      expect(consumo, isNull);
    });
  });

  group('ConsumoService.custoPorLitro (4b)', () {
    test('calcula valor total dividido por litros', () {
      final abastecimento = _abastecimento(
          data: DateTime(2026, 1, 1), km: 40000, litros: 40, valor: 240, tanqueCheio: true);

      expect(ConsumoService.custoPorLitro(abastecimento), 6.0);
    });
  });

  group('ConsumoService.custoPorKm (4c)', () {
    test('calcula custo por km entre abastecimentos consecutivos, tanque cheio ou não', () {
      final anterior = _abastecimento(
          data: DateTime(2026, 1, 1), km: 40000, litros: 20, valor: 120, tanqueCheio: false);
      final atual = _abastecimento(
          data: DateTime(2026, 1, 10), km: 40200, litros: 15, valor: 90, tanqueCheio: false);

      final custoPorKm = ConsumoService.custoPorKm(atual, anterior);

      expect(custoPorKm, 90 / 200);
    });

    test('retorna null quando km rodado não é positivo', () {
      final anterior = _abastecimento(
          data: DateTime(2026, 1, 1), km: 40000, litros: 20, valor: 120, tanqueCheio: true);
      final atual = _abastecimento(
          data: DateTime(2026, 1, 10), km: 40000, litros: 15, valor: 90, tanqueCheio: true);

      expect(ConsumoService.custoPorKm(atual, anterior), isNull);
    });
  });

  group('ConsumoService.consumoPeriodo (4d)', () {
    test('usa km total do período dividido por litros exceto o primeiro abastecimento', () {
      final abastecimentos = [
        _abastecimento(id: 'a1', data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true),
        _abastecimento(id: 'a2', data: DateTime(2026, 1, 10), km: 40300, litros: 25, valor: 150, tanqueCheio: true),
        _abastecimento(id: 'a3', data: DateTime(2026, 1, 20), km: 40600, litros: 25, valor: 150, tanqueCheio: true),
      ];

      final consumo = ConsumoService.consumoPeriodo(abastecimentos);

      // km total = 40600 - 40000 = 600; litros exceto o primeiro = 25 + 25 = 50
      expect(consumo, 600 / 50);
    });

    test('funciona mesmo com abastecimentos fora de ordem de inserção', () {
      final abastecimentos = [
        _abastecimento(id: 'a3', data: DateTime(2026, 1, 20), km: 40600, litros: 25, valor: 150, tanqueCheio: true),
        _abastecimento(id: 'a1', data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true),
        _abastecimento(id: 'a2', data: DateTime(2026, 1, 10), km: 40300, litros: 25, valor: 150, tanqueCheio: true),
      ];

      final consumo = ConsumoService.consumoPeriodo(abastecimentos);

      expect(consumo, 600 / 50);
    });

    test('retorna null com 0 abastecimentos no período', () {
      expect(ConsumoService.consumoPeriodo([]), isNull);
    });

    test('retorna null com 1 abastecimento no período', () {
      final abastecimentos = [
        _abastecimento(data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true),
      ];

      expect(ConsumoService.consumoPeriodo(abastecimentos), isNull);
    });
  });

  group('ConsumoService.gastoPeriodo (4e)', () {
    test('soma valorTotal de todos os abastecimentos do período', () {
      final abastecimentos = [
        _abastecimento(data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true),
        _abastecimento(data: DateTime(2026, 1, 10), km: 40300, litros: 25, valor: 150, tanqueCheio: true),
      ];

      expect(ConsumoService.gastoPeriodo(abastecimentos), 330.0);
    });

    test('retorna 0 para período vazio', () {
      expect(ConsumoService.gastoPeriodo([]), 0.0);
    });
  });

  group('ConsumoService.custoPorKmPeriodo (4f)', () {
    test('divide gasto do período pelo km total rodado', () {
      final abastecimentos = [
        _abastecimento(data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true),
        _abastecimento(data: DateTime(2026, 1, 20), km: 40600, litros: 25, valor: 150, tanqueCheio: true),
      ];

      final custoPorKm = ConsumoService.custoPorKmPeriodo(abastecimentos);

      expect(custoPorKm, 330 / 600);
    });

    test('retorna null com menos de 2 abastecimentos no período', () {
      expect(ConsumoService.custoPorKmPeriodo([]), isNull);
    });
  });

  group('ConsumoService.referenciaAnterior', () {
    test('retorna distância e consumo nulos para o primeiro abastecimento por km', () {
      final unico = _abastecimento(
          id: 'a1', data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true);

      final referencia = ConsumoService.referenciaAnterior([unico], unico);

      expect(referencia.distancia, isNull);
      expect(referencia.consumo, isNull);
    });

    test('calcula distância e consumo entre dois tanques cheios consecutivos', () {
      final anterior = _abastecimento(
          id: 'a1', data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true);
      final atual = _abastecimento(
          id: 'a2', data: DateTime(2026, 1, 15), km: 40400, litros: 40, valor: 240, tanqueCheio: true);
      final historico = [anterior, atual];

      final referencia = ConsumoService.referenciaAnterior(historico, atual);

      expect(referencia.distancia, 400);
      expect(referencia.consumo, 400 / 40);
    });

    test('mantém a distância mas consumo nulo quando um dos dois não é tanque cheio', () {
      final anterior = _abastecimento(
          id: 'a1', data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: false);
      final atual = _abastecimento(
          id: 'a2', data: DateTime(2026, 1, 15), km: 40400, litros: 40, valor: 240, tanqueCheio: true);
      final historico = [anterior, atual];

      final referencia = ConsumoService.referenciaAnterior(historico, atual);

      expect(referencia.distancia, 400);
      expect(referencia.consumo, isNull);
    });

    test('funciona independente da ordem de inserção no histórico', () {
      final a1 = _abastecimento(
          id: 'a1', data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true);
      final a2 = _abastecimento(
          id: 'a2', data: DateTime(2026, 1, 15), km: 40400, litros: 40, valor: 240, tanqueCheio: true);
      final historicoInvertido = [a2, a1];

      final referencia = ConsumoService.referenciaAnterior(historicoInvertido, a2);

      expect(referencia.distancia, 400);
      expect(referencia.consumo, 400 / 40);
    });
  });

  group('ConsumoService.mediaConsumoReal', () {
    test('calcula a média de consumo real de múltiplos pares válidos', () {
      final a1 = _abastecimento(
          id: 'a1', data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true);
      final a2 = _abastecimento(
          id: 'a2', data: DateTime(2026, 1, 15), km: 40400, litros: 40, valor: 240, tanqueCheio: true);
      final a3 = _abastecimento(
          id: 'a3', data: DateTime(2026, 2, 1), km: 40900, litros: 50, valor: 300, tanqueCheio: true);
      final historico = [a1, a2, a3];

      // a2 vs a1: 400 km / 40 L = 10 km/L
      // a3 vs a2: 500 km / 50 L = 10 km/L
      final media = ConsumoService.mediaConsumoReal(historico, [a2, a3]);

      expect(media, 10.0);
    });

    test('retorna null quando nenhum par do subconjunto é válido', () {
      final unico = _abastecimento(
          id: 'a1', data: DateTime(2026, 1, 1), km: 40000, litros: 30, valor: 180, tanqueCheio: true);

      final media = ConsumoService.mediaConsumoReal([unico], [unico]);

      expect(media, isNull);
    });
  });
}
