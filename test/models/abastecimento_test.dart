import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/abastecimento.dart';

void main() {
  group('Abastecimento', () {
    test('fromMap/toMap round-trip preserva todos os campos', () {
      final abastecimento = Abastecimento(
        id: 'a1',
        veiculoId: 'v1',
        data: DateTime(2026, 3, 1),
        kmAtual: 45500,
        litros: 35.5,
        valorTotal: 210.90,
        tanqueCheio: true,
      );

      final map = abastecimento.toMap();
      final restaurado = Abastecimento.fromMap('a1', 'v1', map);

      expect(restaurado, abastecimento);
    });

    test('tanqueCheio false é preservado', () {
      final map = {
        'data': DateTime(2026, 3, 5),
        'kmAtual': 45700,
        'litros': 10.0,
        'valorTotal': 60.0,
        'tanqueCheio': false,
      };

      final abastecimento = Abastecimento.fromMap('a2', 'v1', map);

      expect(abastecimento.tanqueCheio, isFalse);
    });

    test('fromMap aplica defaults para posto/tipoCombustivel quando ausentes (documento antigo)', () {
      final map = {
        'data': DateTime(2026, 3, 5),
        'kmAtual': 45700,
        'litros': 10.0,
        'valorTotal': 60.0,
        'tanqueCheio': false,
      };

      final abastecimento = Abastecimento.fromMap('a2', 'v1', map);

      expect(abastecimento.posto, isNull);
      expect(abastecimento.tipoCombustivel, TipoCombustivel.gasolina);
    });

    test('fromMap/toMap round-trip preserva posto e tipoCombustivel', () {
      final abastecimento = Abastecimento(
        id: 'a3',
        veiculoId: 'v1',
        data: DateTime(2026, 3, 10),
        kmAtual: 46000,
        litros: 40.0,
        valorTotal: 240.0,
        tanqueCheio: true,
        posto: 'Ipiranga Av. Brasil',
        tipoCombustivel: TipoCombustivel.etanol,
      );

      final map = abastecimento.toMap();
      final restaurado = Abastecimento.fromMap('a3', 'v1', map);

      expect(restaurado, abastecimento);
    });
  });
}
