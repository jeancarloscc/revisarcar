import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _carregando = false;

  Future<void> _entrar() async {
    setState(() => _carregando = true);
    await context.read<AppAuthProvider>().signInWithGoogle();
    if (mounted) setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    final erro = context.watch<AppAuthProvider>().errorMessage;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colorScheme.primary.withValues(alpha: 0.85), colorScheme.primary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(Icons.build, size: 46, color: colorScheme.onPrimary),
              ),
              const SizedBox(height: 24),
              Text('RevisaCar', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 6),
              Text(
                'Manutenção do seu veículo sem complicação',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              if (erro != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 18, color: colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(child: Text(erro, style: TextStyle(color: colorScheme.error))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                onPressed: _carregando ? null : _entrar,
                icon: const Icon(Icons.login),
                label: Text(_carregando ? 'Entrando...' : 'Entrar com Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
