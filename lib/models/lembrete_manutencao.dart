import 'firestore_date.dart';
import 'manutencao.dart';

class LembreteManutencao {
  final String id;
  final String veiculoId;
  final TipoManutencao tipoManutencao;
  final int? intervaloKm;
  final int? intervaloDias;
  final int antecedenciaKm;
  final int antecedenciaDias;
  final int intervaloRepeticaoDias;
  final bool ativo;
  final DateTime? resolvidoEm;

  LembreteManutencao({
    required this.id,
    required this.veiculoId,
    required this.tipoManutencao,
    this.intervaloKm,
    this.intervaloDias,
    required this.antecedenciaKm,
    required this.antecedenciaDias,
    required this.intervaloRepeticaoDias,
    required this.ativo,
    this.resolvidoEm,
  }) : assert(intervaloKm != null || intervaloDias != null,
            'LembreteManutencao exige intervaloKm ou intervaloDias');

  factory LembreteManutencao.fromMap(String id, String veiculoId, Map<String, dynamic> data) {
    return LembreteManutencao(
      id: id,
      veiculoId: veiculoId,
      tipoManutencao: TipoManutencao.values.firstWhere(
        (t) => t.name == data['tipoManutencao'],
        orElse: () => TipoManutencao.outro,
      ),
      intervaloKm: data['intervaloKm'] as int?,
      intervaloDias: data['intervaloDias'] as int?,
      antecedenciaKm: data['antecedenciaKm'] as int? ?? 0,
      antecedenciaDias: data['antecedenciaDias'] as int? ?? 0,
      intervaloRepeticaoDias: data['intervaloRepeticaoDias'] as int? ?? 3,
      ativo: data['ativo'] as bool? ?? true,
      resolvidoEm:
          data['resolvidoEm'] == null ? null : parseFirestoreDate(data['resolvidoEm']),
    );
  }

  LembreteManutencao copyWith({
    int? intervaloKm,
    int? intervaloDias,
    int? antecedenciaKm,
    int? antecedenciaDias,
    int? intervaloRepeticaoDias,
    bool? ativo,
    DateTime? resolvidoEm,
  }) {
    return LembreteManutencao(
      id: id,
      veiculoId: veiculoId,
      tipoManutencao: tipoManutencao,
      intervaloKm: intervaloKm ?? this.intervaloKm,
      intervaloDias: intervaloDias ?? this.intervaloDias,
      antecedenciaKm: antecedenciaKm ?? this.antecedenciaKm,
      antecedenciaDias: antecedenciaDias ?? this.antecedenciaDias,
      intervaloRepeticaoDias: intervaloRepeticaoDias ?? this.intervaloRepeticaoDias,
      ativo: ativo ?? this.ativo,
      resolvidoEm: resolvidoEm ?? this.resolvidoEm,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipoManutencao': tipoManutencao.name,
      'intervaloKm': intervaloKm,
      'intervaloDias': intervaloDias,
      'antecedenciaKm': antecedenciaKm,
      'antecedenciaDias': antecedenciaDias,
      'intervaloRepeticaoDias': intervaloRepeticaoDias,
      'ativo': ativo,
      'resolvidoEm': resolvidoEm,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is LembreteManutencao &&
      other.id == id &&
      other.veiculoId == veiculoId &&
      other.tipoManutencao == tipoManutencao &&
      other.intervaloKm == intervaloKm &&
      other.intervaloDias == intervaloDias &&
      other.antecedenciaKm == antecedenciaKm &&
      other.antecedenciaDias == antecedenciaDias &&
      other.intervaloRepeticaoDias == intervaloRepeticaoDias &&
      other.ativo == ativo &&
      other.resolvidoEm == resolvidoEm;

  @override
  int get hashCode => Object.hash(id, veiculoId, tipoManutencao, intervaloKm, intervaloDias,
      antecedenciaKm, antecedenciaDias, intervaloRepeticaoDias, ativo, resolvidoEm);
}
