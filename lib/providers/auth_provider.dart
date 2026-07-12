import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../auth/google_auth_client.dart';

class AppAuthProvider extends ChangeNotifier {
  AppAuthProvider({FirebaseAuth? firebaseAuth, GoogleAuthClient? googleAuthClient})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleAuthClient = googleAuthClient ?? GoogleSignInAuthClient() {
    _user = _firebaseAuth.currentUser;
    _firebaseAuth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final FirebaseAuth _firebaseAuth;
  final GoogleAuthClient _googleAuthClient;
  User? _user;
  String? _errorMessage;

  User? get user => _user;
  String? get errorMessage => _errorMessage;

  Future<void> signInWithGoogle() async {
    _errorMessage = null;
    try {
      final credential = await _googleAuthClient.signIn();
      if (credential == null) return;
      await _firebaseAuth.signInWithCredential(credential);
      _user = _firebaseAuth.currentUser;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Não foi possível entrar. Verifique sua conexão e tente novamente.';
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _user = null;
    notifyListeners();
  }
}
