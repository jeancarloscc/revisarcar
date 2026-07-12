import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/providers/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('começa em ThemeMode.light quando não há preferência salva', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = ThemeModeProvider(prefs);

    expect(provider.themeMode, ThemeMode.light);
  });

  test('carrega ThemeMode.dark quando a preferência salva é true', () async {
    SharedPreferences.setMockInitialValues({'tema_escuro': true});
    final prefs = await SharedPreferences.getInstance();
    final provider = ThemeModeProvider(prefs);

    expect(provider.themeMode, ThemeMode.dark);
  });

  test('alternar() troca o tema e persiste a escolha', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = ThemeModeProvider(prefs);

    await provider.alternar();
    expect(provider.themeMode, ThemeMode.dark);
    expect(prefs.getBool('tema_escuro'), true);

    await provider.alternar();
    expect(provider.themeMode, ThemeMode.light);
    expect(prefs.getBool('tema_escuro'), false);
  });
}
