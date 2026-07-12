import '../models/lembrete_manutencao.dart';
import '../models/manutencao.dart';

class MetaLembrete {
  final int? metaKm;
  final DateTime? metaData;
  const MetaLembrete({this.metaKm, this.metaData});
}

enum StatusLembrete { emDia, alertaAntecipado, vencido }

class LembreteService {
  static MetaLembrete calcularProximaMeta({
    required LembreteManutencao lembrete,
    required int kmReferencia,
    required DateTime dataReferencia,
  }) {
    final metaKm = lembrete.intervaloKm != null ? kmReferencia + lembrete.intervaloKm! : null;
    final metaData = lembrete.intervaloDias != null
        ? dataReferencia.add(Duration(days: lembrete.intervaloDias!))
        : null;
    return MetaLembrete(metaKm: metaKm, metaData: metaData);
  }

  static Manutencao? manutencaoMaisRecente(List<Manutencao> manutencoes, TipoManutencao tipo) {
    final doTipo = manutencoes.where((m) => m.tipo == tipo).toList()
      ..sort((a, b) => a.dataRealizada.compareTo(b.dataRealizada));
    return doTipo.isEmpty ? null : doTipo.last;
  }

  static StatusLembrete calcularStatus({
    required LembreteManutencao lembrete,
    required MetaLembrete meta,
    required int kmAtual,
    required DateTime hoje,
  }) {
    final vencidoPorKm = meta.metaKm != null && kmAtual >= meta.metaKm!;
    final vencidoPorData = meta.metaData != null && !hoje.isBefore(meta.metaData!);
    if (vencidoPorKm || vencidoPorData) return StatusLembrete.vencido;

    final alertaPorKm =
        meta.metaKm != null && kmAtual >= meta.metaKm! - lembrete.antecedenciaKm;
    final alertaPorData = meta.metaData != null &&
        !hoje.isBefore(meta.metaData!.subtract(Duration(days: lembrete.antecedenciaDias)));
    if (alertaPorKm || alertaPorData) return StatusLembrete.alertaAntecipado;

    return StatusLembrete.emDia;
  }
}
