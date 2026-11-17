import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen.dart';
import 'state/auth_provider.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..init(),
      child: const MoovApp(),
    ),
  );
}

class MoovApp extends StatelessWidget {
  const MoovApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOOV',
      debugShowCheckedModeBanner: false,
      theme: buildMoovTheme(),
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
