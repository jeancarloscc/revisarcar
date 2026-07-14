import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/services/calculadora_combustivel_service.dart';

void main() {
  group('CalculadoraCombustivelService.calculoDireto', () {
    test('calcula litros e valor total corretamente', () {
      final resultado = CalculadoraCombustivelService.calculoDireto(
        distanciaKm: 400,
        consumoKmPorLitro: 10,
        precoPorLitro: 6,
      );

      expect(resultado, isNotNull);
      expect(resultado!.litros, 40);
      expect(resultado.valorTotal, 240);
    });

    test('dobra a distância quando idaEVolta é true', () {
      final resultado = CalculadoraCombustivelService.calculoDireto(
        distanciaKm: 200,
        consumoKmPorLitro: 10,
        precoPorLitro: 6,
        idaEVolta: true,
      );

      expect(resultado!.litros, 40);
    });

    test('não dobra a distância quando idaEVolta é false (padrão)', () {
      final resultado = CalculadoraCombustivelService.calculoDireto(
        distanciaKm: 200,
        consumoKmPorLitro: 10,
        precoPorLitro: 6,
      );

      expect(resultado!.litros, 20);
    });

    test('retorna null quando distanciaKm não é positiva', () {
      final resultado = CalculadoraCombustivelService.calculoDireto(
        distanciaKm: 0,
        consumoKmPorLitro: 10,
        precoPorLitro: 6,
      );

      expect(resultado, isNull);
    });

    test('retorna null quando consumoKmPorLitro não é positivo', () {
      final resultado = CalculadoraCombustivelService.calculoDireto(
        distanciaKm: 200,
        consumoKmPorLitro: 0,
        precoPorLitro: 6,
      );

      expect(resultado, isNull);
    });

    test('retorna null quando precoPorLitro não é positivo', () {
      final resultado = CalculadoraCombustivelService.calculoDireto(
        distanciaKm: 200,
        consumoKmPorLitro: 10,
        precoPorLitro: 0,
      );

      expect(resultado, isNull);
    });
  });

  group('CalculadoraCombustivelService.calculoPorOrcamento', () {
    test('calcula litros comprados e km alcançáveis', () {
      final resultado = CalculadoraCombustivelService.calculoPorOrcamento(
        valorDisponivel: 120,
        consumoKmPorLitro: 10,
        precoPorLitro: 6,
      );

      expect(resultado, isNotNull);
      expect(resultado!.litros, 20);
      expect(resultado.kmAlcancaveis, 200);
    });

    test('retorna null quando valorDisponivel não é positivo', () {
      final resultado = CalculadoraCombustivelService.calculoPorOrcamento(
        valorDisponivel: 0,
        consumoKmPorLitro: 10,
        precoPorLitro: 6,
      );

      expect(resultado, isNull);
    });

    test('retorna null quando consumoKmPorLitro não é positivo', () {
      final resultado = CalculadoraCombustivelService.calculoPorOrcamento(
        valorDisponivel: 120,
        consumoKmPorLitro: 0,
        precoPorLitro: 6,
      );

      expect(resultado, isNull);
    });

    test('retorna null quando precoPorLitro não é positivo', () {
      final resultado = CalculadoraCombustivelService.calculoPorOrcamento(
        valorDisponivel: 120,
        consumoKmPorLitro: 10,
        precoPorLitro: 0,
      );

      expect(resultado, isNull);
    });
  });
}
