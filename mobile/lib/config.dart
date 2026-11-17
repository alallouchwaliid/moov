/// Adresse de l'API Django.
///
/// - Émulateur Android : http://10.0.2.2:8000/api (valeur par défaut)
/// - Simulateur iOS / Web / Windows : http://127.0.0.1:8000/api
/// - Téléphone réel : http://<IP du PC sur le Wi-Fi>:8000/api
///
/// Modifiable sans toucher au code :
///   flutter run --dart-define=API_URL=http://192.168.1.20:8000/api
const String apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:8000/api',
);
