import 'package:flutter/material.dart';

import '../models/manutencao.dart';

extension TipoManutencaoVisual on TipoManutencao {
  IconData get icon {
    switch (this) {
      case TipoManutencao.revisao:
        return Icons.assignment_turned_in;
      case TipoManutencao.trocaOleo:
        return Icons.water_drop;
      case TipoManutencao.trocaFiltro:
        return Icons.air;
      case TipoManutencao.pneusRodizio:
        return Icons.circle;
      case TipoManutencao.bateria:
        return Icons.battery_charging_full;
      case TipoManutencao.palhetas:
        return Icons.cleaning_services;
      case TipoManutencao.arCondicionado:
        return Icons.ac_unit;
      case TipoManutencao.alinhamentoBalanceamento:
        return Icons.tune;
      case TipoManutencao.outro:
        return Icons.more_horiz;
    }
  }

  Color get cor {
    switch (this) {
      case TipoManutencao.revisao:
        return const Color(0xFF059669);
      case TipoManutencao.trocaOleo:
        return const Color(0xFFF07810);
      case TipoManutencao.trocaFiltro:
        return const Color(0xFF4A90D9);
      case TipoManutencao.pneusRodizio:
        return const Color(0xFF6B7280);
      case TipoManutencao.bateria:
        return const Color(0xFFD97706);
      case TipoManutencao.palhetas:
        return const Color(0xFF0891B2);
      case TipoManutencao.arCondicionado:
        return const Color(0xFF0EA5E9);
      case TipoManutencao.alinhamentoBalanceamento:
        return const Color(0xFF7C3AED);
      case TipoManutencao.outro:
        return const Color(0xFF64748B);
    }
  }
}
