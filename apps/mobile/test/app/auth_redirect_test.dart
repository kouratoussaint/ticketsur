import 'package:flutter_test/flutter_test.dart';
import 'package:ticketsur/app/routes.dart';

void main() {
  group('authRedirect', () {
    test('visiteur : l’accueil connecté renvoie vers la connexion', () {
      expect(
        authRedirect(signedIn: false, location: AppRoutes.home),
        AppRoutes.signIn,
      );
    });

    for (final location in [
      AppRoutes.welcome,
      AppRoutes.signIn,
      AppRoutes.forgotPassword,
      AppRoutes.verdictPreview,
    ]) {
      test('visiteur : $location reste accessible', () {
        expect(authRedirect(signedIn: false, location: location), isNull);
      });
    }

    for (final location in AppRoutes.guestOnly) {
      test('connecté : $location renvoie vers l’accueil connecté', () {
        expect(
          authRedirect(signedIn: true, location: location),
          AppRoutes.home,
        );
      });
    }

    test('connecté : l’accueil connecté reste affiché', () {
      expect(authRedirect(signedIn: true, location: AppRoutes.home), isNull);
    });
  });
}
