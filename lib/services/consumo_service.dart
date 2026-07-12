import '../models/abastecimento.dart';

class ConsumoService {
  static double? consumoPorAbastecimento(Abastecimento atual, Abastecimento anterior) {
    if (!atual.tanqueCheio || !anterior.tanqueCheio) return null;
    final kmRodado = atual.kmAtual - anterior.kmAtual;
    if (kmRodado <= 0 || atual.litros <= 0) return null;
    return kmRodado / atual.litros;
  }

  static double custoPorLitro(Abastecimento abastecimento) {
    return abastecimento.valorTotal / abastecimento.litros;
  }

  static double? custoPorKm(Abastecimento atual, Abastecimento anterior) {
    final kmRodado = atual.kmAtual - anterior.kmAtual;
    if (kmRodado <= 0) return null;
    return atual.valorTotal / kmRodado;
  }

  static double? consumoPeriodo(List<Abastecimento> abastecimentosNoPeriodo) {
    final periodo = _periodoValido(abastecimentosNoPeriodo);
    if (periodo == null) return null;
    final litrosTotais =
        periodo.ordenados.skip(1).fold<double>(0, (soma, a) => soma + a.litros);
    if (litrosTotais <= 0) return null;
    return periodo.kmTotal / litrosTotais;
  }

  static double gastoPeriodo(List<Abastecimento> abastecimentosNoPeriodo) {
    return abastecimentosNoPeriodo.fold<double>(0, (soma, a) => soma + a.valorTotal);
  }

  static double? custoPorKmPeriodo(List<Abastecimento> abastecimentosNoPeriodo) {
    final periodo = _periodoValido(abastecimentosNoPeriodo);
    if (periodo == null) return null;
    return gastoPeriodo(abastecimentosNoPeriodo) / periodo.kmTotal;
  }

  static ({List<Abastecimento> ordenados, int kmTotal})? _periodoValido(
      List<Abastecimento> abastecimentosNoPeriodo) {
    final ordenados = _ordenarPorData(abastecimentosNoPeriodo);
    if (ordenados.length < 2) return null;
    final kmTotal = ordenados.last.kmAtual - ordenados.first.kmAtual;
    if (kmTotal <= 0) return null;
    return (ordenados: ordenados, kmTotal: kmTotal);
  }

  static List<Abastecimento> _ordenarPorData(List<Abastecimento> abastecimentos) {
    final copia = List<Abastecimento>.of(abastecimentos);
    copia.sort((a, b) {
      final porData = a.data.compareTo(b.data);
      if (porData != 0) return porData;
      return a.kmAtual.compareTo(b.kmAtual);
    });
    return copia;
  }
}
