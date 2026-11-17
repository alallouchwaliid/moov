import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Client HTTP de l'API MOOV : JSON, JWT et rafraîchissement automatique du token.
class ApiClient {
  ApiClient({String? baseUrl}) : _baseUrl = baseUrl ?? apiBaseUrl;

  String _baseUrl;
  String get baseUrl => _baseUrl;

  /// Adresse par défaut (choisie à la compilation).
  static final defaultBaseUrl = apiBaseUrl;
  final _storage = const FlutterSecureStorage();
  final _http = http.Client();

  String? _access;
  String? _refresh;

  /// Appelé quand la session a expiré (refresh token invalide).
  void Function()? onSessionExpired;

  bool get isAuthenticated => _access != null;
  String? get refreshToken => _refresh;

  /// Change l'adresse du serveur (ex. autre Wi-Fi) sans recompiler l'app.
  Future<void> setBaseUrl(String url) async {
    var clean = url.trim();
    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    _baseUrl = clean.isEmpty ? defaultBaseUrl : clean;
    if (_baseUrl == defaultBaseUrl) {
      await _storage.delete(key: 'api_url');
    } else {
      await _storage.write(key: 'api_url', value: _baseUrl);
    }
  }

  Future<void> loadTokens() async {
    _baseUrl = await _storage.read(key: 'api_url') ?? _baseUrl;
    _access = await _storage.read(key: 'access');
    _refresh = await _storage.read(key: 'refresh');
  }

  Future<void> saveTokens({required String access, String? refresh}) async {
    _access = access;
    await _storage.write(key: 'access', value: access);
    if (refresh != null) {
      _refresh = refresh;
      await _storage.write(key: 'refresh', value: refresh);
    }
  }

  Future<void> clearTokens() async {
    _access = null;
    _refresh = null;
    await _storage.delete(key: 'access');
    await _storage.delete(key: 'refresh');
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final params = <String, String>{};
    query?.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) params[key] = value.toString();
    });
    return Uri.parse('$baseUrl$path').replace(queryParameters: params.isEmpty ? null : params);
  }

  Map<String, String> _headers({bool json = true}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
        if (_access != null) 'Authorization': 'Bearer $_access',
      };

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _http.get(_uri(path, query), headers: _headers()));

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) => _send(
      () => _http.post(_uri(path), headers: _headers(), body: body == null ? null : jsonEncode(body)));

  Future<dynamic> patch(String path, Map<String, dynamic> body) =>
      _send(() => _http.patch(_uri(path), headers: _headers(), body: jsonEncode(body)));

  Future<dynamic> delete(String path) => _send(() => _http.delete(_uri(path), headers: _headers()));

  /// Envoi d'un fichier (ex. avatar) en multipart. Fonctionne sur mobile et sur le web.
  Future<dynamic> uploadFile(String path, String field, List<int> bytes, String filename,
      {String method = 'PATCH'}) {
    return _send(() async {
      final request = http.MultipartRequest(method, _uri(path))
        ..headers.addAll(_headers(json: false))
        ..files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));
      return http.Response.fromStream(await _http.send(request));
    });
  }

  Future<dynamic> _send(Future<http.Response> Function() request, {bool retried = false}) async {
    http.Response response;
    try {
      // 60 s : le serveur gratuit Render met ~50 s à se réveiller après une période d'inactivité.
      response = await request().timeout(const Duration(seconds: 60));
    } on SocketException {
      throw ApiException("Impossible de joindre le serveur. Vérifiez votre connexion et l'adresse de l'API.");
    } on TimeoutException {
      throw ApiException('Le serveur met trop de temps à répondre.');
    } on http.ClientException {
      throw ApiException('Erreur réseau. Réessayez.');
    }

    if (response.statusCode == 401 && !retried && _refresh != null) {
      if (await _tryRefresh()) return _send(request, retried: true);
      await clearTokens();
      onSessionExpired?.call();
    }

    final body = response.body.isEmpty ? null : jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    throw ApiException(_extractMessage(body, response.statusCode), statusCode: response.statusCode);
  }

  Future<bool> _tryRefresh() async {
    try {
      final res = await _http.post(
        _uri('/auth/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refresh}),
      );
      if (res.statusCode != 200) return false;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      await saveTokens(access: data['access'] as String, refresh: data['refresh'] as String?);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Transforme les erreurs DRF ({"detail": ...}, {"champ": ["msg"]}, ["msg"]) en texte lisible.
  static String _extractMessage(dynamic body, int status) {
    String? first(dynamic value) {
      if (value is String) return value;
      if (value is List && value.isNotEmpty) return first(value.first);
      if (value is Map) {
        for (final key in ['detail', 'non_field_errors']) {
          if (value.containsKey(key)) return first(value[key]);
        }
        for (final entry in value.entries) {
          final msg = first(entry.value);
          if (msg != null) return msg;
        }
      }
      return null;
    }

    final msg = first(body);
    if (msg != null) return msg;
    if (status == 401) return 'Veuillez vous reconnecter.';
    if (status == 403) return "Vous n'avez pas l'autorisation d'effectuer cette action.";
    if (status == 404) return 'Élément introuvable.';
    if (status >= 500) return 'Erreur du serveur. Réessayez plus tard.';
    return 'Une erreur est survenue ($status).';
  }
}

/// Instance partagée par toute l'application.
final api = ApiClient();
