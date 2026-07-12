import 'intervalo_manutencao.dart';
import 'manutencao.dart';

enum TipoVeiculo { carro, moto }

class Veiculo {
  final String id;
  final String nome;
  final String modelo;
  final int ano;
  final String placa;
  final int kmAtual;
  final TipoVeiculo tipoVeiculo;
  final String? fotoUrl;
  final Map<TipoManutencao, IntervaloManutencao> intervalosPersonalizados;

  const Veiculo({
    required this.id,
    required this.nome,
    required this.modelo,
    required this.ano,
    required this.placa,
    required this.kmAtual,
    required this.tipoVeiculo,
    this.fotoUrl,
    this.intervalosPersonalizados = const {},
  });

  factory Veiculo.fromMap(String id, Map<String, dynamic> data) {
    final intervalosMap = data['intervalosPersonalizados'] as Map<Object?, Object?>?;
    return Veiculo(
      id: id,
      nome: data['nome'] as String,
      modelo: data['modelo'] as String,
      ano: data['ano'] as int,
      placa: data['placa'] as String,
      kmAtual: data['kmAtual'] as int,
      tipoVeiculo: TipoVeiculo.values.firstWhere(
        (t) => t.name == data['tipoVeiculo'],
        orElse: () => TipoVeiculo.carro,
      ),
      fotoUrl: data['fotoUrl'] as String?,
      intervalosPersonalizados: intervalosMap == null
          ? const {}
          : Map<String, dynamic>.from(intervalosMap).map(
              (key, value) => MapEntry(
                TipoManutencao.values.firstWhere(
                  (t) => t.name == key,
                  orElse: () => TipoManutencao.outro,
                ),
                IntervaloManutencao.fromMap(Map<String, dynamic>.from(value as Map)),
              ),
            ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'modelo': modelo,
      'ano': ano,
      'placa': placa,
      'kmAtual': kmAtual,
      'tipoVeiculo': tipoVeiculo.name,
      'fotoUrl': fotoUrl,
      'intervalosPersonalizados':
          intervalosPersonalizados.map((tipo, intervalo) => MapEntry(tipo.name, intervalo.toMap())),
    };
  }

  Veiculo copyWith({
    String? nome,
    String? modelo,
    int? ano,
    String? placa,
    int? kmAtual,
    TipoVeiculo? tipoVeiculo,
    String? fotoUrl,
    Map<TipoManutencao, IntervaloManutencao>? intervalosPersonalizados,
  }) {
    return Veiculo(
      id: id,
      nome: nome ?? this.nome,
      modelo: modelo ?? this.modelo,
      ano: ano ?? this.ano,
      placa: placa ?? this.placa,
      kmAtual: kmAtual ?? this.kmAtual,
      tipoVeiculo: tipoVeiculo ?? this.tipoVeiculo,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      intervalosPersonalizados: intervalosPersonalizados ?? this.intervalosPersonalizados,
    );
  }

  static bool _intervalosIguais(
    Map<TipoManutencao, IntervaloManutencao> a,
    Map<TipoManutencao, IntervaloManutencao> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static int _intervalosHash(Map<TipoManutencao, IntervaloManutencao> mapa) {
    var hash = 0;
    for (final entry in mapa.entries) {
      hash ^= Object.hash(entry.key, entry.value);
    }
    return hash;
  }

  @override
  bool operator ==(Object other) =>
      other is Veiculo &&
      other.id == id &&
      other.nome == nome &&
      other.modelo == modelo &&
      other.ano == ano &&
      other.placa == placa &&
      other.kmAtual == kmAtual &&
      other.tipoVeiculo == tipoVeiculo &&
      other.fotoUrl == fotoUrl &&
      _intervalosIguais(other.intervalosPersonalizados, intervalosPersonalizados);

  @override
  int get hashCode => Object.hash(
      id, nome, modelo, ano, placa, kmAtual, tipoVeiculo, fotoUrl, _intervalosHash(intervalosPersonalizados));
}
