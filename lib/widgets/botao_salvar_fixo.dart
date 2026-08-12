import 'package:flutter/material.dart';

class BotaoSalvarFixo extends StatelessWidget {
  final String label;
  final String labelCarregando;
  final bool carregando;
  final VoidCallback? onPressed;

  const BotaoSalvarFixo({
    super.key,
    required this.label,
    required this.labelCarregando,
    required this.carregando,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary.withValues(alpha: 0.9), colorScheme.primary],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: colorScheme.onPrimary,
          ),
          onPressed: carregando ? null : onPressed,
          child: Text(carregando ? labelCarregando : label),
        ),
      ),
    );
  }
}
