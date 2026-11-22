import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

const googleClientId = 'synthetic-web-client';
const googleId = 'synthetic-google-id';
const googleAccess = 'synthetic-google-access';
const googleScopes = ['email'];

class MockGoogle extends Mock implements GoogleSignIn {}

class _Account extends Mock implements GoogleSignInAccount {}

class _Authorization extends Mock implements GoogleSignInAuthorizationClient {}

MockGoogle syntheticGoogle({
  String? id = googleId,
  String? access = googleAccess,
  bool supported = true,
  Object? error,
  Future<void>? beforeResult,
}) {
  final google = MockGoogle();
  final account = _Account();
  final authorization = _Authorization();
  when(() => google.initialize(serverClientId: googleClientId))
      .thenAnswer((_) async {});
  when(google.supportsAuthenticate).thenReturn(supported);
  when(() => google.authenticate(scopeHint: googleScopes))
      .thenAnswer((_) async {
    await beforeResult;
    if (error != null) throw error;
    return account;
  });
  when(() => account.authentication)
      .thenReturn(GoogleSignInAuthentication(idToken: id));
  when(() => account.authorizationClient).thenReturn(authorization);
  when(() => authorization.authorizationForScopes(googleScopes)).thenAnswer(
      (_) async => access == null
          ? null
          : GoogleSignInClientAuthorization(accessToken: access));
  return google;
}
