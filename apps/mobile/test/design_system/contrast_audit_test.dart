import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/legal/domain/legal_document.dart';

import '../helpers/contrast_audit.dart';
import '../helpers/showcase.dart';

/// Parcourt les écrans principaux en thème clair puis sombre et vérifie le
/// contraste de chaque texte affiché.
void main() {
  // La langue formatée hors widgets revient au français après chaque test.
  tearDown(() => appLocaleTag = 'fr');
  testWidgets("l'audit repère un texte illisible et ignore les icônes", (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ColoredBox(
          color: Color(0xFF061B38),
          child: Column(
            children: [
              Text('Lisible', style: TextStyle(color: Color(0xFFE6ECF4))),
              Text('Illisible', style: TextStyle(color: Color(0xFF52627A))),
              Icon(Icons.star, color: Color(0xFF0B1F3A)),
            ],
          ),
        ),
      ),
    );
    final issues = auditContrast(tester);
    expect(issues, hasLength(1));
    expect(issues.single, startsWith('« Illisible »'));
  });

  // Clair et sombre en français ; clair en anglais (textes plus longs ou
  // plus courts : débordements) ; « Très grande » taille du texte (130 %)
  // sur un téléphone déjà réglé à 130 %, soit 169 % : mise en page (#11).
  for (final (mode, language, textSize) in [
    ('light', 'fr', 'normal'),
    ('dark', 'fr', 'normal'),
    ('light', 'en', 'normal'),
    ('light', 'fr', 'extraLarge'),
  ]) {
    final large = textSize != 'normal';
    final screens = {
      'accueil': AppRoutes.home,
      'événements': AppRoutes.events,
      'fiche événement (brouillon)': AppRoutes.eventDetail('e0'),
      'fiche événement (en cours)': AppRoutes.eventDetail('e2'),
      'tableau de bord': AppRoutes.eventDashboard('e2'),
      'bilan': AppRoutes.eventSummary('e2'),
      'postes de contrôle': AppRoutes.posts,
      'composants': AppRoutes.componentGallery,
      'tickets': AppRoutes.tickets,
      'fiche ticket': AppRoutes.ticketDetail('e2', 'tk-0'),
      'équipe': AppRoutes.team,
      'profil': AppRoutes.profile,
      'modifier le profil': AppRoutes.editProfile,
      'nouvel événement': AppRoutes.newEvent,
      'explorer (connecté)': AppRoutes.explore,
      'sans compte : explorer': AppRoutes.discover,
      'sans compte : fiche publique': AppRoutes.publicEvent('p1'),
      'sans compte : organiser': AppRoutes.organize,
      'sans compte : inscription': AppRoutes.signUpWithCode,
      'sans compte : connexion': AppRoutes.signIn,
      'sans compte : bienvenue': AppRoutes.welcome,
      'sans compte : mot de passe oublié': AppRoutes.forgotPassword,
      'nouveau mot de passe': AppRoutes.newPassword,
      'rejoindre une structure': AppRoutes.joinOrganization,
      'sans compte : favoris': AppRoutes.favorites,
      'favoris (connecté)': AppRoutes.favorites,
      'console': AppRoutes.console,
      'console : organisations': AppRoutes.consoleOrganizations,
      'console : catalogue': AppRoutes.consoleCatalog,
      'console : à la une': AppRoutes.consoleFeatured,
      'console : journal': AppRoutes.consoleJournal,
      'console : comptes': AppRoutes.consoleAccounts,
      'console : support': AppRoutes.consoleSupport,
      'console : fil de support': AppRoutes.consoleSupportThread('r1'),
      'console : annonces': AppRoutes.consoleAnnouncements,
      'console : nouvelle annonce': AppRoutes.consoleAnnouncementNew,
      'console : packs': AppRoutes.consolePacks,
      'console : nouveau pack': AppRoutes.consolePackNew,
      'console : modifier un pack': AppRoutes.consolePack('pk1'),
      'console : à encaisser': AppRoutes.consoleCollect,
      'console : valider un paiement': AppRoutes.consoleCollectRequest('r1'),
      'console : encaisser une facture': AppRoutes.consoleCollectInvoice('i1'),
      'console : abonnements': AppRoutes.consoleSubscriptions,
      'console : réglages de paiement': AppRoutes.consolePaymentSettings,
      'mon pack': AppRoutes.billing,
      'choisir un pack': AppRoutes.billingPacks,
      'suppléments': AppRoutes.billingAddonsFor('pk1', BillingDuration.quarter),
      'paiement': AppRoutes.billingRequest('rq-new'),
      'demande en attente': AppRoutes.billingRequest('rq-wait'),
      'à propos': AppRoutes.about,
      'factures': AppRoutes.billingInvoices,
      'facture': AppRoutes.billingInvoice(
        'aaaaaaaa-0000-0000-0000-00000000f001',
      ),
      "facturation d'un événement": AppRoutes.eventBilling('e2'),
      'aide et support': AppRoutes.support,
      'nouvelle demande': AppRoutes.supportNew,
      'fil de support': AppRoutes.supportThread('r2'),
      'paramètres': AppRoutes.settings,
      'sans compte : conditions': AppRoutes.legal(LegalSlug.terms),
      'console : mentions légales': AppRoutes.consoleLegal,
      'console : modifier les conditions': AppRoutes.consoleLegalEdit(
        LegalSlug.terms,
      ),
      'mes tickets': AppRoutes.wallet,
      'ajouter un ticket': AppRoutes.walletAdd,
      'mon ticket': AppRoutes.walletTicket('w1'),
      'mon ticket utilisé': AppRoutes.walletTicket('w2'),
      'journal de la structure': AppRoutes.journal,
      'appareils connectés': AppRoutes.devices,
      'recherche': AppRoutes.search,
      'modèles des tickets': AppRoutes.ticketTemplates('e2'),
      "modèle d'une catégorie": AppRoutes.ticketTemplate('e2', 'c1'),
    };
    for (final MapEntry(key: name, value: path) in screens.entries) {
      testWidgets('thème $mode${language == 'en' ? ' en anglais' : ''}'
          '${large ? ', texte très grand' : ''} : $name', (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        if (large) {
          tester.platformDispatcher.textScaleFactorTestValue = 1.3;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        }
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: await showcaseOverrides(
              signedIn: !name.startsWith('sans compte'),
              mode: mode,
              language: language,
              textSize: textSize,
            ),
            child: const TicketSurApp(),
          ),
        );
        await tester.pumpAndSettle();
        GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);
        await tester.pumpAndSettle();
        await tester.pumpAndSettle();

        final issues = <String>{};
        // Écran entier : on fait défiler la liste principale par pas.
        final scrollables = find.byType(Scrollable);
        for (var step = 0; step < 12; step++) {
          issues.addAll(auditContrast(tester));
          if (scrollables.evaluate().isEmpty) break;
          final position = tester
              .state<ScrollableState>(scrollables.first)
              .position;
          if (position.pixels >= position.maxScrollExtent) break;
          position.jumpTo(
            (position.pixels + 600).clamp(0, position.maxScrollExtent),
          );
          await tester.pumpAndSettle();
        }
        expect(issues, isEmpty, reason: issues.join('\n'));
      });
    }
  }
}
