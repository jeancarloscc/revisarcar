import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/models/manutencao.dart';
import 'package:revisacar/utils/tipo_manutencao_visual.dart';

void main() {
  group('TipoManutencaoVisual', () {
    test('todo TipoManutencao tem ícone e cor definidos', () {
      for (final tipo in TipoManutencao.values) {
        expect(tipo.icon, isA<IconData>());
        expect(tipo.cor, isA<Color>());
      }
    });

    test('valores específicos batem com a tabela do design', () {
      expect(TipoManutencao.trocaOleo.icon, Icons.water_drop);
      expect(TipoManutencao.trocaOleo.cor, const Color(0xFFF07810));
      expect(TipoManutencao.revisao.icon, Icons.assignment_turned_in);
      expect(TipoManutencao.revisao.cor, const Color(0xFF059669));
      expect(TipoManutencao.outro.icon, Icons.more_horiz);
      expect(TipoManutencao.outro.cor, const Color(0xFF64748B));
    });

    test('cada tipo tem uma cor distinta dos demais', () {
      final cores = TipoManutencao.values.map((t) => t.cor).toSet();
      expect(cores.length, TipoManutencao.values.length);
    });
  });
}
