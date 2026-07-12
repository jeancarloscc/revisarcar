import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/theme/app_theme.dart';

void main() {
  group('appTheme', () {
    testWidgets('kCardRadius e kInputRadius têm os valores esperados',
      (WidgetTester tester) async {
      expect(kCardRadius, 16.0);
      expect(kInputRadius, 12.0);
    });

    testWidgets('tema claro usa a paleta esperada',
      (WidgetTester tester) async {
      expect(appThemeLight.colorScheme.primary, const Color(0xFF162936));
      expect(appThemeLight.colorScheme.surface, const Color(0xFFFFFCF8));
      expect(appThemeLight.colorScheme.error, const Color(0xFFC0392B));
      expect(appThemeLight.scaffoldBackgroundColor, const Color(0xFFF3E6D7));
    });

    testWidgets('tema escuro usa a paleta esperada',
      (WidgetTester tester) async {
      expect(appThemeDark.colorScheme.primary, kAccentColor);
      expect(appThemeDark.colorScheme.surface, const Color(0xFF25343E));
      expect(appThemeDark.colorScheme.error, const Color(0xFFE74C3C));
      expect(appThemeDark.scaffoldBackgroundColor, const Color(0xFF162936));
    });

    testWidgets('kAccentColor é igual nos dois temas',
      (WidgetTester tester) async {
      expect(kAccentColor, const Color(0xFFCE9D78));
    });
  });
}
