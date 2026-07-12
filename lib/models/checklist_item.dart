class ChecklistItem {
  final String id;
  final String veiculoId;
  final String descricao;
  final int ordem;
  final bool verificado;

  const ChecklistItem({
    required this.id,
    required this.veiculoId,
    required this.descricao,
    required this.ordem,
    required this.verificado,
  });

  factory ChecklistItem.fromMap(String id, String veiculoId, Map<String, dynamic> map) {
    return ChecklistItem(
      id: id,
      veiculoId: veiculoId,
      descricao: map['descricao'] as String,
      ordem: map['ordem'] as int,
      verificado: map['verificado'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'descricao': descricao,
      'ordem': ordem,
      'verificado': verificado,
    };
  }

  ChecklistItem copyWith({bool? verificado}) => ChecklistItem(
        id: id,
        veiculoId: veiculoId,
        descricao: descricao,
        ordem: ordem,
        verificado: verificado ?? this.verificado,
      );

  @override
  bool operator ==(Object other) =>
      other is ChecklistItem &&
      other.id == id &&
      other.veiculoId == veiculoId &&
      other.descricao == descricao &&
      other.ordem == ordem &&
      other.verificado == verificado;

  @override
  int get hashCode => Object.hash(id, veiculoId, descricao, ordem, verificado);
}
