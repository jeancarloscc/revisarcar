import 'package:flutter/material.dart';

import '../models/veiculo.dart';

class VeiculoCard extends StatelessWidget {
  final Veiculo veiculo;
  final VoidCallback onTap;
  final VoidCallback onExcluir;
  final ({int vencidos, int alertas})? resumoAlerta;

  const VeiculoCard({
    super.key,
    required this.veiculo,
    required this.onTap,
    required this.onExcluir,
    this.resumoAlerta,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMoto = veiculo.tipoVeiculo == TipoVeiculo.moto;
    final vencidos = resumoAlerta?.vencidos ?? 0;
    final alertas = resumoAlerta?.alertas ?? 0;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isMoto
                ? colorScheme.error.withValues(alpha: 0.12)
                : colorScheme.secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isMoto ? Icons.two_wheeler : Icons.directions_car,
            size: 30,
            color: isMoto ? colorScheme.error : colorScheme.primary,
          ),
        ),
        title: Text(veiculo.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${veiculo.modelo} · ${veiculo.ano}'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.speed, size: 12, color: colorScheme.primary),
                    const SizedBox(width: 2),
                    Text(
                      '${veiculo.kmAtual} km',
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                    ),
                  ],
                ),
                if (vencidos > 0 || alertas > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: vencidos > 0 ? colorScheme.error : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vencidos > 0
                          ? '$vencidos vencido${vencidos > 1 ? 's' : ''}'
                          : '$alertas alerta${alertas > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: onTap,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Excluir',
          onPressed: onExcluir,
        ),
      ),
    );
  }
}
