import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/lembrete_manutencao.dart';
import 'package:revisacar/models/manutencao.dart';
import 'package:revisacar/services/lembrete_service.dart';

LembreteManutencao _lembrete({
  int? intervaloKm,
  int? intervaloDias,
  int antecedenciaKm = 0,
  int antecedenciaDias = 0,
}) {
  return LembreteManutencao(
    id: 'l1',
    veiculoId: 'v1',
    tipoManutencao: TipoManutencao.trocaOleo,
    intervaloKm: intervaloKm,
    intervaloDias: intervaloDias,
    antecedenciaKm: antecedenciaKm,
    antecedenciaDias: antecedenciaDias,
    intervaloRepeticaoDias: 3,
    ativo: true,
  );
}

void main() {
  group('LembreteService.calcularProximaMeta', () {
    test('meta por km soma intervaloKm ao km de referência', () {
      final lembrete = _lembrete(intervaloKm: 10000);

      final meta = LembreteService.calcularProximaMeta(
        lembrete: lembrete,
        kmReferencia: 40000,
        dataReferencia: DateTime(2026, 1, 1),
      );

      expect(meta.metaKm, 50000);
      expect(meta.metaData, isNull);
    });

    test('meta por tempo soma intervaloDias à data de referência', () {
      final lembrete = _lembrete(intervaloDias: 180);

      final meta = LembreteService.calcularProximaMeta(
        lembrete: lembrete,
        kmReferencia: 40000,
        dataReferencia: DateTime(2026, 1, 1),
      );

      expect(meta.metaData, DateTime(2026, 1, 1).add(const Duration(days: 180)));
      expect(meta.metaKm, isNull);
    });

    test('calcula as duas metas quando ambos os intervalos estão configurados', () {
      final lembrete = _lembrete(intervaloKm: 10000, intervaloDias: 180);

      final meta = LembreteService.calcularProximaMeta(
        lembrete: lembrete,
        kmReferencia: 40000,
        dataReferencia: DateTime(2026, 1, 1),
      );

      expect(meta.metaKm, 50000);
      expect(meta.metaData, DateTime(2026, 1, 1).add(const Duration(days: 180)));
    });
  });

  group('LembreteService.manutencaoMaisRecente', () {
    test('retorna a manutenção mais recente (por data) daquele tipo', () {
      final manutencoes = [
        Manutencao(
          id: 'm1',
          veiculoId: 'v1',
          tipo: TipoManutencao.trocaOleo,
          dataRealizada: DateTime(2025, 6, 1),
          kmNaData: 30000,
          custo: 200,
          oficina: 'A',
          observacoes: '',
        ),
        Manutencao(
          id: 'm2',
          veiculoId: 'v1',
          tipo: TipoManutencao.trocaOleo,
          dataRealizada: DateTime(2026, 1, 1),
          kmNaData: 40000,
          custo: 220,
          oficina: 'B',
          observacoes: '',
        ),
        Manutencao(
          id: 'm3',
          veiculoId: 'v1',
          tipo: TipoManutencao.revisao,
          dataRealizada: DateTime(2026, 2, 1),
          kmNaData: 41000,
          custo: 500,
          oficina: 'C',
          observacoes: '',
        ),
      ];

      final referencia =
          LembreteService.manutencaoMaisRecente(manutencoes, TipoManutencao.trocaOleo);

      expect(referencia?.id, 'm2');
    });

    test('retorna null quando não há manutenção daquele tipo', () {
      final referencia = LembreteService.manutencaoMaisRecente([], TipoManutencao.bateria);

      expect(referencia, isNull);
    });
  });

  group('LembreteService.calcularStatus', () {
    test('emDia quando longe da meta por km e por data', () {
      final lembrete = _lembrete(intervaloKm: 10000, antecedenciaKm: 500);
      final meta = MetaLembrete(metaKm: 50000);

      final status = LembreteService.calcularStatus(
        lembrete: lembrete,
        meta: meta,
        kmAtual: 45000,
        hoje: DateTime(2026, 1, 1),
      );

      expect(status, StatusLembrete.emDia);
    });

    test('alertaAntecipado quando km entra na faixa de antecedência', () {
      final lembrete = _lembrete(intervaloKm: 10000, antecedenciaKm: 500);
      final meta = MetaLembrete(metaKm: 50000);

      final status = LembreteService.calcularStatus(
        lembrete: lembrete,
        meta: meta,
        kmAtual: 49600,
        hoje: DateTime(2026, 1, 1),
      );

      expect(status, StatusLembrete.alertaAntecipado);
    });

    test('vencido quando km atinge ou ultrapassa a meta', () {
      final lembrete = _lembrete(intervaloKm: 10000, antecedenciaKm: 500);
      final meta = MetaLembrete(metaKm: 50000);

      final status = LembreteService.calcularStatus(
        lembrete: lembrete,
        meta: meta,
        kmAtual: 50000,
        hoje: DateTime(2026, 1, 1),
      );

      expect(status, StatusLembrete.vencido);
    });

    test('vencido por data mesmo com km longe da meta ("o que vencer primeiro")', () {
      final lembrete = _lembrete(intervaloKm: 10000, intervaloDias: 180, antecedenciaDias: 15);
      final meta = MetaLembrete(metaKm: 60000, metaData: DateTime(2026, 6, 1));

      final status = LembreteService.calcularStatus(
        lembrete: lembrete,
        meta: meta,
        kmAtual: 41000,
        hoje: DateTime(2026, 6, 1),
      );

      expect(status, StatusLembrete.vencido);
    });
  });

  group('LembreteService.proximosAvisos', () {
    test('início no futuro: primeiro aviso às 9h do dia de início', () {
      final avisos = LembreteService.proximosAvisos(
        inicio: DateTime(2026, 3, 10),
        repeticaoDias: 3,
        agora: DateTime(2026, 3, 1, 15),
      );

      expect(avisos, [DateTime(2026, 3, 10, 9), DateTime(2026, 3, 13, 9), DateTime(2026, 3, 16, 9)]);
    });

    test('início no passado: mantém a cadência e só devolve avisos futuros', () {
      final avisos = LembreteService.proximosAvisos(
        inicio: DateTime(2026, 3, 10),
        repeticaoDias: 3,
        agora: DateTime(2026, 3, 16, 10),
      );

      expect(avisos, [DateTime(2026, 3, 19, 9), DateTime(2026, 3, 22, 9), DateTime(2026, 3, 25, 9)]);
    });

    test('no dia de um aviso, antes das 9h, o aviso do dia ainda entra', () {
      final avisos = LembreteService.proximosAvisos(
        inicio: DateTime(2026, 3, 10),
        repeticaoDias: 3,
        agora: DateTime(2026, 3, 13, 8),
        quantidade: 1,
      );

      expect(avisos, [DateTime(2026, 3, 13, 9)]);
    });

    test('repetição 0 é tratada como diária', () {
      final avisos = LembreteService.proximosAvisos(
        inicio: DateTime(2026, 3, 10),
        repeticaoDias: 0,
        agora: DateTime(2026, 3, 10, 12),
        quantidade: 2,
      );

      expect(avisos, [DateTime(2026, 3, 11, 9), DateTime(2026, 3, 12, 9)]);
    });
  });
}
