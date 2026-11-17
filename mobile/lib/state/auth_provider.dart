import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_client.dart';
import '../api/moov_api.dart';
import '../models/models.dart';

/// État de connexion partagé (Provider).
class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _ready = false;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isReady => _ready;

  Future<void> init() async {
    api.onSessionExpired = () {
      _user = null;
      notifyListeners();
    };
    await api.loadTokens();
    if (api.isAuthenticated) {
      try {
        _user = await MoovApi.me();
      } on ApiException catch (e) {
        // Hors ligne : on garde les tokens ; session invalide : on les supprime.
        if (e.statusCode == 401) await api.clearTokens();
      }
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _applyAuthResponse(Map<String, dynamic> data) async {
    await api.saveTokens(access: data['access'] as String, refresh: data['refresh'] as String?);
    _user = User.fromJson(data['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> login(String email, String password) async =>
      _applyAuthResponse(await MoovApi.login(email.trim().toLowerCase(), password));

  Future<void> register(Map<String, dynamic> data) async => _applyAuthResponse(await MoovApi.register(data));

  Future<void> logout() async {
    final refresh = api.refreshToken;
    if (refresh != null) {
      try {
        await MoovApi.logout(refresh);
      } catch (_) {
        // On déconnecte localement même si le serveur est injoignable.
      }
    }
    await api.clearTokens();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshMe() async {
    if (!api.isAuthenticated) return;
    _user = await MoovApi.me();
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await MoovApi.updateMe(data);
    await refreshMe();
  }

  Future<void> uploadAvatar(XFile file) async {
    await MoovApi.uploadAvatar(file);
    await refreshMe();
  }
}
