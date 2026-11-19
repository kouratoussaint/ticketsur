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

    test('racine : Explorer sans compte, Accueil une fois connecté', () {
      expect(
        authRedirect(signedIn: false, location: AppRoutes.welcome),
        AppRoutes.discover,
      );
      expect(
        authRedirect(signedIn: false, location: AppRoutes.explore),
        AppRoutes.discover,
      );
      expect(
        authRedirect(signedIn: true, location: AppRoutes.welcome),
        AppRoutes.home,
      );
    });

    test('connecté : l’Explorer dans l’espace connecté', () {
      expect(authRedirect(signedIn: true, location: AppRoutes.explore), isNull);
      expect(
        authRedirect(signedIn: true, location: AppRoutes.discover),
        AppRoutes.explore,
      );
      expect(
        authRedirect(signedIn: true, location: AppRoutes.publicEvent('e1')),
        isNull,
      );
    });

    for (final location in [
      AppRoutes.discover,
      AppRoutes.publicEvent('e1'),
      AppRoutes.organize,
      AppRoutes.signIn,
      AppRoutes.forgotPassword,
      AppRoutes.verdictPreview,
    ]) {
      test('visiteur : $location reste accessible', () {
        expect(authRedirect(signedIn: false, location: location), isNull);
      });
    }

    for (final location in AppRoutes.guestOnly.difference({
      AppRoutes.discover,
    })) {
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
