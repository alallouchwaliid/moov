import 'package:flutter/foundation.dart' show kIsWeb;

/// Adresse de l'API Django.
///
/// - Serveur en ligne (PythonAnywhere) : valeur par défaut
/// - Émulateur Android + serveur local : http://10.0.2.2:8000/api
/// - Simulateur iOS / Web / Windows : http://127.0.0.1:8000/api
/// - Téléphone réel : http://<IP du PC sur le Wi-Fi>:8000/api
///
/// Modifiable sans toucher au code :
///   flutter run --dart-define=API_URL=http://192.168.1.20:8000/api
const _onlineApi = 'https://waliiiiiid.pythonanywhere.com/api';

/// Version web (PWA iPhone) : sans API_URL explicite, on appelle l'API du serveur
/// qui héberge la page (même origine → pas de blocage CORS, marche aussi en local).
final String apiBaseUrl = const bool.hasEnvironment('API_URL')
    ? const String.fromEnvironment('API_URL')
    : (kIsWeb ? '${Uri.base.origin}/api' : _onlineApi);
