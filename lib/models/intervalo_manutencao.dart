class IntervaloManutencao {
  final int? km;
  final int? dias;

  const IntervaloManutencao({this.km, this.dias});

  bool get vazio => km == null && dias == null;

  factory IntervaloManutencao.fromMap(Map<String, dynamic> data) {
    return IntervaloManutencao(
      km: data['km'] as int?,
      dias: data['dias'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'km': km, 'dias': dias};
  }

  @override
  bool operator ==(Object other) =>
      other is IntervaloManutencao && other.km == km && other.dias == dias;

  @override
  int get hashCode => Object.hash(km, dias);
}
