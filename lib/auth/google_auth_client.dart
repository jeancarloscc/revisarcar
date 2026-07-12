import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Abstração sobre o processo de autenticação do Google, permitindo que
/// [AppAuthProvider] seja testado sem depender do plugin real.
abstract class GoogleAuthClient {
  Future<AuthCredential?> signIn();
}

/// Implementação real de [GoogleAuthClient] usando o pacote `google_sign_in`.
///
/// Nota: a partir da versão 7.x do `google_sign_in`, a API mudou
/// significativamente em relação a versões anteriores:
/// - `GoogleSignIn` não tem mais construtor público; usa-se o singleton
///   `GoogleSignIn.instance`, que precisa ser inicializado via
///   `initialize()` antes de qualquer outra chamada.
/// - O método `signIn()` foi substituído por `authenticate()`, que lança
///   `GoogleSignInException` (código `canceled`) em vez de retornar `null`
///   quando o usuário cancela o fluxo.
/// - `GoogleSignInAuthentication` não expõe mais `accessToken` (apenas
///   `idToken`); tokens de autorização/acesso são obtidos separadamente via
///   `authorizationClient`, o que não é necessário para autenticar no
///   Firebase apenas com `idToken`.
class GoogleSignInAuthClient implements GoogleAuthClient {
  GoogleSignInAuthClient([GoogleSignIn? googleSignIn])
      : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize();
    _initialized = true;
  }

  @override
  Future<AuthCredential?> signIn() async {
    await _ensureInitialized();
    try {
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      return GoogleAuthProvider.credential(idToken: googleAuth.idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }
}
