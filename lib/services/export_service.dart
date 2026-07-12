// lib/services/export_service.dart
import '../models/abastecimento.dart';
import '../models/lembrete_manutencao.dart';
import '../models/manutencao.dart';
import '../models/veiculo.dart';

class ExportService {
  static String veiculosCsv(List<Veiculo> veiculos) {
    final linhas = <String>['id,nome,modelo,ano,placa,km_atual'];
    for (final v in veiculos) {
      linhas.add([
        v.id,
        _csvEscape(v.nome),
        _csvEscape(v.modelo),
        v.ano.toString(),
        _csvEscape(v.placa),
        v.kmAtual.toString(),
      ].join(','));
    }
    return linhas.join('\n');
  }

  static String manutencoesCsv(List<Manutencao> manutencoes) {
    final linhas = <String>[
      'id,veiculo_id,tipo,descricao_outro,data_realizada,km_na_data,custo,oficina,observacoes'
    ];
    for (final m in manutencoes) {
      linhas.add([
        m.id,
        m.veiculoId,
        m.tipo.name,
        _csvEscape(m.descricaoOutro ?? ''),
        _formatarData(m.dataRealizada),
        m.kmNaData.toString(),
        m.custo.toString(),
        _csvEscape(m.oficina),
        _csvEscape(m.observacoes),
      ].join(','));
    }
    return linhas.join('\n');
  }

  static String abastecimentosCsv(List<Abastecimento> abastecimentos) {
    final linhas = <String>[
      'id,veiculo_id,data,km_atual,litros,valor_total,tanque_cheio'
    ];
    for (final a in abastecimentos) {
      linhas.add([
        a.id,
        a.veiculoId,
        _formatarData(a.data),
        a.kmAtual.toString(),
        a.litros.toString(),
        a.valorTotal.toString(),
        a.tanqueCheio.toString(),
      ].join(','));
    }
    return linhas.join('\n');
  }

  static String lembretesCsv(List<LembreteManutencao> lembretes) {
    final linhas = <String>[
      'id,veiculo_id,tipo_manutencao,intervalo_km,intervalo_dias,antecedencia_km,'
          'antecedencia_dias,intervalo_repeticao_dias,ativo,resolvido_em'
    ];
    for (final l in lembretes) {
      linhas.add([
        l.id,
        l.veiculoId,
        l.tipoManutencao.name,
        l.intervaloKm?.toString() ?? '',
        l.intervaloDias?.toString() ?? '',
        l.antecedenciaKm.toString(),
        l.antecedenciaDias.toString(),
        l.intervaloRepeticaoDias.toString(),
        l.ativo.toString(),
        l.resolvidoEm != null ? _formatarData(l.resolvidoEm!) : '',
      ].join(','));
    }
    return linhas.join('\n');
  }

  static String _formatarData(DateTime data) {
    final y = data.year.toString().padLeft(4, '0');
    final m = data.month.toString().padLeft(2, '0');
    final d = data.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _csvEscape(String valor) {
    if (valor.contains(',') || valor.contains('"') || valor.contains('\n')) {
      return '"${valor.replaceAll('"', '""')}"';
    }
    return valor;
  }
}
