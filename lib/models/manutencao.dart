import 'firestore_date.dart';

enum TipoManutencao {
  revisao,
  trocaOleo,
  trocaFiltro,
  pneusRodizio,
  bateria,
  palhetas,
  arCondicionado,
  alinhamentoBalanceamento,
  outro,
}

class Manutencao {
  final String id;
  final String veiculoId;
  final TipoManutencao tipo;
  final String? descricaoOutro;
  final DateTime dataRealizada;
  final int kmNaData;
  final double custo;
  final String oficina;
  final String observacoes;

  const Manutencao({
    required this.id,
    required this.veiculoId,
    required this.tipo,
    this.descricaoOutro,
    required this.dataRealizada,
    required this.kmNaData,
    required this.custo,
    required this.oficina,
    required this.observacoes,
  });

  factory Manutencao.fromMap(String id, String veiculoId, Map<String, dynamic> data) {
    return Manutencao(
      id: id,
      veiculoId: veiculoId,
      tipo: TipoManutencao.values.firstWhere(
        (t) => t.name == data['tipo'],
        orElse: () => TipoManutencao.outro,
      ),
      descricaoOutro: data['descricaoOutro'] as String?,
      dataRealizada: parseFirestoreDate(data['dataRealizada']),
      kmNaData: data['kmNaData'] as int,
      custo: (data['custo'] as num).toDouble(),
      oficina: data['oficina'] as String,
      observacoes: data['observacoes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo.name,
      'descricaoOutro': descricaoOutro,
      'dataRealizada': dataRealizada,
      'kmNaData': kmNaData,
      'custo': custo,
      'oficina': oficina,
      'observacoes': observacoes,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is Manutencao &&
      other.id == id &&
      other.veiculoId == veiculoId &&
      other.tipo == tipo &&
      other.descricaoOutro == descricaoOutro &&
      other.dataRealizada == dataRealizada &&
      other.kmNaData == kmNaData &&
      other.custo == custo &&
      other.oficina == oficina &&
      other.observacoes == observacoes;

  @override
  int get hashCode => Object.hash(
      id, veiculoId, tipo, descricaoOutro, dataRealizada, kmNaData, custo, oficina, observacoes);
}
