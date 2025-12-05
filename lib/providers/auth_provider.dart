import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    // 로그인 상태 변화 감지
    _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  // Google 로그인
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    final userCredential = await _authService.signInWithGoogle();

    _isLoading = false;
    notifyListeners();

    return userCredential != null;
  }

  // 로그아웃
  Future<void> signOut() async {
    await _authService.signOut();
    notifyListeners();
  }
}
