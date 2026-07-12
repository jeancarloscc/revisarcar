import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/lembrete_manutencao.dart';
import 'package:revisacar/models/manutencao.dart';

void main() {
  group('LembreteManutencao', () {
    test('fromMap/toMap round-trip preserva todos os campos', () {
      final lembrete = LembreteManutencao(
        id: 'l1',
        veiculoId: 'v1',
        tipoManutencao: TipoManutencao.trocaOleo,
        intervaloKm: 10000,
        intervaloDias: 180,
        antecedenciaKm: 500,
        antecedenciaDias: 15,
        intervaloRepeticaoDias: 3,
        ativo: true,
        resolvidoEm: DateTime(2026, 1, 1),
      );

      final map = lembrete.toMap();
      final restaurado = LembreteManutencao.fromMap('l1', 'v1', map);

      expect(restaurado, lembrete);
    });

    test('exige intervaloKm ou intervaloDias', () {
      expect(
        () => LembreteManutencao(
          id: 'l2',
          veiculoId: 'v1',
          tipoManutencao: TipoManutencao.revisao,
          antecedenciaKm: 0,
          antecedenciaDias: 0,
          intervaloRepeticaoDias: 3,
          ativo: true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('resolvidoEm nulo é preservado', () {
      final map = {
        'tipoManutencao': 'revisao',
        'intervaloKm': 5000,
        'intervaloDias': null,
        'antecedenciaKm': 200,
        'antecedenciaDias': 10,
        'intervaloRepeticaoDias': 5,
        'ativo': true,
        'resolvidoEm': null,
      };

      final lembrete = LembreteManutencao.fromMap('l3', 'v1', map);

      expect(lembrete.resolvidoEm, isNull);
    });

    test('copyWith troca só os campos informados', () {
      final lembrete = LembreteManutencao(
        id: 'l1',
        veiculoId: 'v1',
        tipoManutencao: TipoManutencao.trocaOleo,
        intervaloKm: 10000,
        antecedenciaKm: 500,
        antecedenciaDias: 15,
        intervaloRepeticaoDias: 3,
        ativo: true,
      );

      final resolvido = DateTime(2026, 7, 10);
      final atualizado = lembrete.copyWith(resolvidoEm: resolvido);

      expect(atualizado.resolvidoEm, resolvido);
      expect(atualizado.ativo, lembrete.ativo);
      expect(atualizado.intervaloKm, lembrete.intervaloKm);
      expect(atualizado.tipoManutencao, lembrete.tipoManutencao);
    });
  });
}
