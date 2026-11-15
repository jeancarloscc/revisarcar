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

  /// Próximos avisos depois de `agora`, sempre às 9h: o primeiro cai no dia
  /// de `inicio` e os seguintes se repetem a cada `repeticaoDias`.
  static List<DateTime> proximosAvisos({
    required DateTime inicio,
    required int repeticaoDias,
    required DateTime agora,
    int quantidade = 3,
  }) {
    // O formulário aceita 0; sem isso a divisão abaixo falharia.
    final repeticao = repeticaoDias < 1 ? 1 : repeticaoDias;
    final primeiro = DateTime(inicio.year, inicio.month, inicio.day, 9);
    var k = primeiro.isAfter(agora) ? 0 : agora.difference(primeiro).inDays ~/ repeticao;
    final avisos = <DateTime>[];
    while (avisos.length < quantidade) {
      final aviso = DateTime(primeiro.year, primeiro.month, primeiro.day + k * repeticao, 9);
      if (aviso.isAfter(agora)) avisos.add(aviso);
      k++;
    }
    return avisos;
  }
}
