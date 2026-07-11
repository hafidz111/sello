import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _onAuthStateChanged,
    );
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authSubscription;

  User? _user;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  bool get isLoggedIn => _user != null;

  String? get userName =>
      _user?.displayName?.trim().isNotEmpty == true
          ? _user!.displayName
          : _user?.email?.split('@').first;

  String get userId => _user?.uid ?? 'anonymous';

  String? get userEmail => _user?.email;

  void _onAuthStateChanged(User? user) {
    _user = user;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthException(_mapAuthError(error));
    }
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthException(_mapAuthError(error));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthException(_mapAuthError(error));
    }
  }

  String _mapAuthError(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Format email tidak valid.',
      'user-disabled' => 'Akun ini dinonaktifkan.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Email atau password salah.',
      'email-already-in-use' => 'Email sudah terdaftar. Silakan masuk.',
      'weak-password' => 'Password terlalu lemah. Minimal 6 karakter.',
      'too-many-requests' => 'Terlalu banyak percobaan. Coba lagi nanti.',
      'network-request-failed' =>
        'Gagal terhubung. Periksa koneksi internet kamu.',
      _ => 'Autentikasi gagal. Coba lagi.',
    };
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
