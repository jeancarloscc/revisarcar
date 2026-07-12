// test/models/manutencao_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/manutencao.dart';

void main() {
  group('Manutencao', () {
    test('fromMap/toMap round-trip preserva todos os campos', () {
      final manutencao = Manutencao(
        id: 'm1',
        veiculoId: 'v1',
        tipo: TipoManutencao.trocaOleo,
        dataRealizada: DateTime(2026, 1, 10),
        kmNaData: 40000,
        custo: 250.0,
        oficina: 'Oficina do Zé',
        observacoes: 'Óleo sintético 5W30',
      );

      final map = manutencao.toMap();
      final restaurada = Manutencao.fromMap('m1', 'v1', map);

      expect(restaurada, manutencao);
    });

    test('aceita Timestamp do Firestore em dataRealizada', () {
      final map = {
        'tipo': 'revisao',
        'descricaoOutro': null,
        'dataRealizada': Timestamp.fromDate(DateTime(2026, 2, 1)),
        'kmNaData': 41000,
        'custo': 300.0,
        'oficina': 'Concessionária',
        'observacoes': '',
      };

      final manutencao = Manutencao.fromMap('m2', 'v1', map);

      expect(manutencao.dataRealizada, DateTime(2026, 2, 1));
    });

    test('tipo desconhecido cai para outro', () {
      final map = {
        'tipo': 'valor_invalido',
        'dataRealizada': DateTime(2026, 1, 1),
        'kmNaData': 0,
        'custo': 0.0,
        'oficina': '',
        'observacoes': '',
      };

      final manutencao = Manutencao.fromMap('m3', 'v1', map);

      expect(manutencao.tipo, TipoManutencao.outro);
    });
  });
}
