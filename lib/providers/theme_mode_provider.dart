import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeProvider extends ChangeNotifier {
  static const _temaEscuroKey = 'tema_escuro';

  final SharedPreferences _prefs;
  bool _escuro;

  ThemeModeProvider(SharedPreferences prefs)
      : _prefs = prefs,
        _escuro = prefs.getBool(_temaEscuroKey) ?? false;

  ThemeMode get themeMode => _escuro ? ThemeMode.dark : ThemeMode.light;

  Future<void> alternar() async {
    _escuro = !_escuro;
    await _prefs.setBool(_temaEscuroKey, _escuro);
    notifyListeners();
  }
}
