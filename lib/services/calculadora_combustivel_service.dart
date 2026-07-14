class CalculadoraCombustivelService {
  static ({double litros, double valorTotal})? calculoDireto({
    required double distanciaKm,
    required double consumoKmPorLitro,
    required double precoPorLitro,
    bool idaEVolta = false,
  }) {
    if (distanciaKm <= 0 || consumoKmPorLitro <= 0 || precoPorLitro <= 0) return null;
    final distanciaEfetiva = idaEVolta ? distanciaKm * 2 : distanciaKm;
    final litros = distanciaEfetiva / consumoKmPorLitro;
    return (litros: litros, valorTotal: litros * precoPorLitro);
  }

  static ({double litros, double kmAlcancaveis})? calculoPorOrcamento({
    required double valorDisponivel,
    required double consumoKmPorLitro,
    required double precoPorLitro,
  }) {
    if (valorDisponivel <= 0 || consumoKmPorLitro <= 0 || precoPorLitro <= 0) return null;
    final litros = valorDisponivel / precoPorLitro;
    return (litros: litros, kmAlcancaveis: litros * consumoKmPorLitro);
  }
}
