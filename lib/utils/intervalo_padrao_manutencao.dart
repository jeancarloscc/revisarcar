import '../models/intervalo_manutencao.dart';
import '../models/manutencao.dart';
import '../models/veiculo.dart';

const Map<TipoManutencao, IntervaloManutencao> intervalosPadraoManutencao = {
  TipoManutencao.revisao: IntervaloManutencao(km: 10000, dias: 360),
  TipoManutencao.trocaOleo: IntervaloManutencao(km: 10000, dias: 360),
  TipoManutencao.trocaFiltro: IntervaloManutencao(km: 40000, dias: 1440),
  TipoManutencao.pneusRodizio: IntervaloManutencao(km: 10000),
  TipoManutencao.bateria: IntervaloManutencao(dias: 720),
  TipoManutencao.palhetas: IntervaloManutencao(dias: 360),
  TipoManutencao.arCondicionado: IntervaloManutencao(km: 20000, dias: 720),
  TipoManutencao.alinhamentoBalanceamento: IntervaloManutencao(km: 10000),
};

IntervaloManutencao? intervaloEfetivo(Veiculo veiculo, TipoManutencao tipo) {
  if (tipo == TipoManutencao.outro) return null;
  return veiculo.intervalosPersonalizados[tipo] ?? intervalosPadraoManutencao[tipo];
}
