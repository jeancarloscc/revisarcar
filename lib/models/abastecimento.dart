import 'firestore_date.dart';

class Abastecimento {
  final String id;
  final String veiculoId;
  final DateTime data;
  final int kmAtual;
  final double litros;
  final double valorTotal;
  final bool tanqueCheio;

  const Abastecimento({
    required this.id,
    required this.veiculoId,
    required this.data,
    required this.kmAtual,
    required this.litros,
    required this.valorTotal,
    required this.tanqueCheio,
  });

  factory Abastecimento.fromMap(String id, String veiculoId, Map<String, dynamic> map) {
    return Abastecimento(
      id: id,
      veiculoId: veiculoId,
      data: parseFirestoreDate(map['data']),
      kmAtual: map['kmAtual'] as int,
      litros: (map['litros'] as num).toDouble(),
      valorTotal: (map['valorTotal'] as num).toDouble(),
      tanqueCheio: map['tanqueCheio'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'data': data,
      'kmAtual': kmAtual,
      'litros': litros,
      'valorTotal': valorTotal,
      'tanqueCheio': tanqueCheio,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is Abastecimento &&
      other.id == id &&
      other.veiculoId == veiculoId &&
      other.data == data &&
      other.kmAtual == kmAtual &&
      other.litros == litros &&
      other.valorTotal == valorTotal &&
      other.tanqueCheio == tanqueCheio;

  @override
  int get hashCode =>
      Object.hash(id, veiculoId, data, kmAtual, litros, valorTotal, tanqueCheio);
}
