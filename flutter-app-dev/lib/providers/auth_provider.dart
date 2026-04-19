import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  /// Convenience role getter — defaults to 'viewer' when not logged in.
  String get role => _currentUser?.role ?? 'viewer';

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _setLoading(true);
    try {
      // Load locally cached user first (fast)
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();

      // Then refresh from server so the role is always up-to-date
      if (_currentUser != null) {
        try {
          final fresh = await _authService.getProfile();
          _currentUser = fresh;
          await _authService.saveCurrentUser(fresh);
          notifyListeners();
        } catch (_) {
          // Server unreachable — keep cached user, app still works offline
        }
      }
    } catch (_) {
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final authResponse = await _authService.login(
        email: email,
        password: password,
      );

      _currentUser = authResponse.user;
      notifyListeners();

      // Immediately refresh profile from server so role is authoritative
      try {
        final fresh = await _authService.getProfile();
        _currentUser = fresh;
        await _authService.saveCurrentUser(fresh);
        notifyListeners();
      } catch (_) {
        // Use the role already in authResponse.user if profile call fails
      }

      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final authResponse = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      _currentUser = authResponse.user;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _currentUser = null;
      _setError(null);
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final user = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
      );

      _currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _setError(null);
  }
}
