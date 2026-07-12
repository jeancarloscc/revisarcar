// test/services/export_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/abastecimento.dart';
import 'package:revisacar/models/lembrete_manutencao.dart';
import 'package:revisacar/models/manutencao.dart';
import 'package:revisacar/models/veiculo.dart';
import 'package:revisacar/services/export_service.dart';

void main() {
  group('ExportService', () {
    test('veiculosCsv gera cabeçalho e uma linha por veículo', () {
      const veiculo = Veiculo(
        id: 'v1',
        nome: 'Meu HB20',
        modelo: 'Hyundai HB20',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 45000,
        tipoVeiculo: TipoVeiculo.carro,
      );

      final csv = ExportService.veiculosCsv([veiculo]);

      expect(csv, 'id,nome,modelo,ano,placa,km_atual\n'
          'v1,Meu HB20,Hyundai HB20,2020,ABC1D23,45000');
    });

    test('veiculosCsv com lista vazia gera só o cabeçalho', () {
      expect(ExportService.veiculosCsv([]), 'id,nome,modelo,ano,placa,km_atual');
    });

    test('escapa campos com vírgula usando aspas', () {
      const veiculo = Veiculo(
        id: 'v1',
        nome: 'Carro, apelido com vírgula',
        modelo: 'X',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 0,
        tipoVeiculo: TipoVeiculo.carro,
      );

      final csv = ExportService.veiculosCsv([veiculo]);

      expect(csv, contains('"Carro, apelido com vírgula"'));
    });

    test('manutencoesCsv formata data em ISO 8601 (aaaa-mm-dd)', () {
      final manutencao = Manutencao(
        id: 'm1',
        veiculoId: 'v1',
        tipo: TipoManutencao.trocaOleo,
        dataRealizada: DateTime(2026, 3, 5),
        kmNaData: 40000,
        custo: 200.0,
        oficina: 'Oficina',
        observacoes: '',
      );

      final csv = ExportService.manutencoesCsv([manutencao]);

      expect(csv, contains('2026-03-05'));
    });

    test('abastecimentosCsv inclui todos os campos na ordem esperada', () {
      final abastecimento = Abastecimento(
        id: 'a1',
        veiculoId: 'v1',
        data: DateTime(2026, 1, 1),
        kmAtual: 40000,
        litros: 30.0,
        valorTotal: 180.0,
        tanqueCheio: true,
      );

      final csv = ExportService.abastecimentosCsv([abastecimento]);

      expect(csv, 'id,veiculo_id,data,km_atual,litros,valor_total,tanque_cheio\n'
          'a1,v1,2026-01-01,40000,30.0,180.0,true');
    });

    test('escapa aspas duplas duplicando-as em veiculosCsv', () {
      const veiculo = Veiculo(
        id: 'v1',
        nome: 'Carro "Especial" com aspas',
        modelo: 'X',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 0,
        tipoVeiculo: TipoVeiculo.carro,
      );

      final csv = ExportService.veiculosCsv([veiculo]);

      expect(csv, contains('"Carro ""Especial"" com aspas"'));
    });

    test('escapa quebra de linha em veiculosCsv', () {
      const veiculo = Veiculo(
        id: 'v1',
        nome: 'Carro com\nquebra de linha',
        modelo: 'X',
        ano: 2020,
        placa: 'ABC1D23',
        kmAtual: 0,
        tipoVeiculo: TipoVeiculo.carro,
      );

      final csv = ExportService.veiculosCsv([veiculo]);

      expect(csv, contains('"Carro com\nquebra de linha"'));
    });

    test('lembretesCsv gera linha completa com todos os campos preenchidos', () {
      final lembrete = LembreteManutencao(
        id: 'l1',
        veiculoId: 'v1',
        tipoManutencao: TipoManutencao.trocaOleo,
        intervaloKm: 5000,
        intervaloDias: null,
        antecedenciaKm: 100,
        antecedenciaDias: 7,
        intervaloRepeticaoDias: 30,
        ativo: true,
        resolvidoEm: DateTime(2026, 5, 15),
      );

      final csv = ExportService.lembretesCsv([lembrete]);

      expect(csv, 'id,veiculo_id,tipo_manutencao,intervalo_km,intervalo_dias,antecedencia_km,'
          'antecedencia_dias,intervalo_repeticao_dias,ativo,resolvido_em\n'
          'l1,v1,trocaOleo,5000,,100,7,30,true,2026-05-15');
    });

    test('lembretesCsv com campos nulos aparece como string vazia no CSV', () {
      final lembrete = LembreteManutencao(
        id: 'l2',
        veiculoId: 'v1',
        tipoManutencao: TipoManutencao.revisao,
        intervaloKm: null,
        intervaloDias: 90,
        antecedenciaKm: 50,
        antecedenciaDias: 10,
        intervaloRepeticaoDias: 15,
        ativo: false,
        resolvidoEm: null,
      );

      final csv = ExportService.lembretesCsv([lembrete]);

      expect(csv, 'id,veiculo_id,tipo_manutencao,intervalo_km,intervalo_dias,antecedencia_km,'
          'antecedencia_dias,intervalo_repeticao_dias,ativo,resolvido_em\n'
          'l2,v1,revisao,,90,50,10,15,false,');
    });
  });
}
