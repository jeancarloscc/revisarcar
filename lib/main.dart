// lib/main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_mode_provider.dart';
import 'providers/veiculo_provider.dart';
import 'repositories/veiculo_repository.dart';
import 'screens/login_screen.dart';
import 'screens/veiculo_list_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  final prefs = await SharedPreferences.getInstance();
  runApp(RevisaCarApp(prefs: prefs));
}

class RevisaCarApp extends StatelessWidget {
  final SharedPreferences prefs;

  const RevisaCarApp({super.key, required this.prefs});

  static const _localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const _supportedLocales = [Locale('pt', 'BR')];

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeModeProvider(prefs)),
        Provider<SharedPreferences>.value(value: prefs),
        Provider<VeiculoRepository>(create: (_) => VeiculoRepository()),
      ],
      child: Consumer2<AppAuthProvider, ThemeModeProvider>(
        builder: (context, auth, themeModeProvider, _) {
          final user = auth.user;

          if (user == null) {
            return MaterialApp(
              title: 'RevisaCar',
              theme: appThemeLight,
              darkTheme: appThemeDark,
              themeMode: themeModeProvider.themeMode,
              localizationsDelegates: _localizationsDelegates,
              supportedLocales: _supportedLocales,
              locale: const Locale('pt', 'BR'),
              home: const LoginScreen(),
            );
          }

          return ChangeNotifierProvider<VeiculoProvider>(
            key: ValueKey(user.uid),
            create: (context) => VeiculoProvider(
              repository: context.read<VeiculoRepository>(),
              prefs: context.read<SharedPreferences>(),
              uid: user.uid,
            ),
            child: MaterialApp(
              title: 'RevisaCar',
              theme: appThemeLight,
              darkTheme: appThemeDark,
              themeMode: themeModeProvider.themeMode,
              localizationsDelegates: _localizationsDelegates,
              supportedLocales: _supportedLocales,
              locale: const Locale('pt', 'BR'),
              home: const VeiculoListScreen(),
            ),
          );
        },
      ),
    );
  }
}
