import '../models/manutencao.dart';

extension TipoManutencaoLabel on TipoManutencao {
  String get label {
    switch (this) {
      case TipoManutencao.revisao:
        return 'Revisão';
      case TipoManutencao.trocaOleo:
        return 'Troca de óleo';
      case TipoManutencao.trocaFiltro:
        return 'Troca de filtro';
      case TipoManutencao.pneusRodizio:
        return 'Pneus/Rodízio';
      case TipoManutencao.bateria:
        return 'Bateria';
      case TipoManutencao.palhetas:
        return 'Palhetas';
      case TipoManutencao.arCondicionado:
        return 'Ar-condicionado';
      case TipoManutencao.alinhamentoBalanceamento:
        return 'Alinhamento/Balanceamento';
      case TipoManutencao.outro:
        return 'Outro';
    }
  }
}
