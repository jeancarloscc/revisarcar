import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/intervalo_manutencao.dart';
import 'package:revisacar/models/manutencao.dart';
import 'package:revisacar/models/veiculo.dart';
import 'package:revisacar/utils/intervalo_padrao_manutencao.dart';

Veiculo _veiculo({Map<TipoManutencao, IntervaloManutencao> intervalos = const {}}) {
  return Veiculo(
    id: 'v1',
    nome: 'Meu HB20',
    modelo: 'Hyundai HB20',
    ano: 2020,
    placa: 'ABC1D23',
    kmAtual: 45000,
    tipoVeiculo: TipoVeiculo.carro,
    intervalosPersonalizados: intervalos,
  );
}

void main() {
  group('intervaloEfetivo', () {
    test('retorna null para TipoManutencao.outro', () {
      expect(intervaloEfetivo(_veiculo(), TipoManutencao.outro), isNull);
    });

    test('cai no padrão da tabela quando o veículo não tem override', () {
      final intervalo = intervaloEfetivo(_veiculo(), TipoManutencao.trocaOleo);
      expect(intervalo, intervalosPadraoManutencao[TipoManutencao.trocaOleo]);
      expect(intervalo?.km, 10000);
      expect(intervalo?.dias, 360);
    });

    test('usa o override do veículo quando presente', () {
      final veiculo = _veiculo(intervalos: const {
        TipoManutencao.trocaOleo: IntervaloManutencao(km: 8000, dias: 180),
      });

      final intervalo = intervaloEfetivo(veiculo, TipoManutencao.trocaOleo);

      expect(intervalo, const IntervaloManutencao(km: 8000, dias: 180));
    });

    test('override com km e dias nulos conta como vazio (desliga o tipo)', () {
      final veiculo = _veiculo(intervalos: const {
        TipoManutencao.trocaOleo: IntervaloManutencao(),
      });

      final intervalo = intervaloEfetivo(veiculo, TipoManutencao.trocaOleo);

      expect(intervalo?.vazio, isTrue);
    });

    test('tabela padrão não tem entrada para Outro', () {
      expect(intervalosPadraoManutencao.containsKey(TipoManutencao.outro), isFalse);
    });
  });
}
