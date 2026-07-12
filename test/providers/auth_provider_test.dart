import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisacar/auth/google_auth_client.dart';
import 'package:revisacar/providers/auth_provider.dart';

class _GoogleAuthClientFalso implements GoogleAuthClient {
  final AuthCredential? credencial;
  final Exception? erro;
  _GoogleAuthClientFalso({this.credencial, this.erro});

  @override
  Future<AuthCredential?> signIn() async {
    if (erro != null) throw erro!;
    return credencial;
  }
}

void main() {
  group('AppAuthProvider', () {
    test('user é nulo antes do login', () {
      final auth = MockFirebaseAuth();
      final provider = AppAuthProvider(
        firebaseAuth: auth,
        googleAuthClient: _GoogleAuthClientFalso(),
      );

      expect(provider.user, isNull);
    });

    test('signInWithGoogle autentica e popula user', () async {
      final mockUser = MockUser(uid: 'u1', email: 'jean@example.com');
      final auth = MockFirebaseAuth(mockUser: mockUser);
      final provider = AppAuthProvider(
        firebaseAuth: auth,
        googleAuthClient: _GoogleAuthClientFalso(
          credencial: GoogleAuthProvider.credential(idToken: 'token'),
        ),
      );

      await provider.signInWithGoogle();

      expect(provider.user?.uid, 'u1');
      expect(provider.errorMessage, isNull);
    });

    test('signInWithGoogle não altera user quando usuário cancela (credencial nula)', () async {
      final auth = MockFirebaseAuth();
      final provider = AppAuthProvider(
        firebaseAuth: auth,
        googleAuthClient: _GoogleAuthClientFalso(credencial: null),
      );

      await provider.signInWithGoogle();

      expect(provider.user, isNull);
      expect(provider.errorMessage, isNull);
    });

    test('signInWithGoogle grava mensagem de erro em falha', () async {
      final auth = MockFirebaseAuth();
      final provider = AppAuthProvider(
        firebaseAuth: auth,
        googleAuthClient: _GoogleAuthClientFalso(erro: Exception('sem conexão')),
      );

      await provider.signInWithGoogle();

      expect(provider.errorMessage, isNotNull);
    });

    test('signOut desloga o usuário', () async {
      final mockUser = MockUser(uid: 'u1');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final provider = AppAuthProvider(
        firebaseAuth: auth,
        googleAuthClient: _GoogleAuthClientFalso(),
      );

      await provider.signOut();

      expect(auth.currentUser, isNull);
    });
  });
}
