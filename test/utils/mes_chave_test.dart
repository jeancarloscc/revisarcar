import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/utils/mes_chave.dart';

void main() {
  test('chaveMes formata ano-mês com dois dígitos', () {
    expect(chaveMes(DateTime(2026, 3, 15)), '2026-03');
    expect(chaveMes(DateTime(2026, 11, 1)), '2026-11');
  });

  test('passoMes avança e volta mês dentro do mesmo ano', () {
    expect(passoMes('2026-03', 1), '2026-04');
    expect(passoMes('2026-03', -1), '2026-02');
  });

  test('passoMes atravessa virada de ano', () {
    expect(passoMes('2026-12', 1), '2027-01');
    expect(passoMes('2026-01', -1), '2025-12');
  });

  test('formatarChaveMes retorna nome do mês em português', () {
    expect(formatarChaveMes('2026-08'), 'Agosto de 2026');
    expect(formatarChaveMes('2026-01'), 'Janeiro de 2026');
  });
}
