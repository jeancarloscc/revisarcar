import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/intervalo_manutencao.dart';

void main() {
  group('IntervaloManutencao', () {
    test('fromMap/toMap round-trip preserva km e dias', () {
      const intervalo = IntervaloManutencao(km: 10000, dias: 360);

      final map = intervalo.toMap();
      final restaurado = IntervaloManutencao.fromMap(map);

      expect(restaurado, intervalo);
    });

    test('vazio é true quando km e dias são nulos', () {
      const intervalo = IntervaloManutencao();
      expect(intervalo.vazio, isTrue);
    });

    test('vazio é false quando pelo menos um campo está preenchido', () {
      const comKm = IntervaloManutencao(km: 10000);
      const comDias = IntervaloManutencao(dias: 360);
      expect(comKm.vazio, isFalse);
      expect(comDias.vazio, isFalse);
    });

    test('dois IntervaloManutencao com os mesmos valores são iguais', () {
      const a = IntervaloManutencao(km: 10000, dias: 360);
      const b = IntervaloManutencao(km: 10000, dias: 360);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
