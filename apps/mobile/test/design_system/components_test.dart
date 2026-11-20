import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/ticketsur_theme.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/widgets/empty_state.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';

import '../helpers/pump_app.dart';

void main() {
  void reduceMotion(WidgetTester tester) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  testWidgets('en-tête héros : titre, sous-titre, retour, illustration', (
    tester,
  ) async {
    var back = 0;
    await tester.pumpApp(
      TikeoHeroHeader(
        title: 'Mon équipe',
        subtitle: '12 membres',
        illustration: TikeoIllustration.team,
        onBack: () => back++,
        actions: [
          TikeoHeaderBell(onPressed: () {}, tooltip: 'Alertes', dot: true),
        ],
      ),
    );
    expect(find.text('Mon équipe'), findsOneWidget);
    expect(find.text('12 membres'), findsOneWidget);
    expect(find.byType(TikeoIllustrationView), findsOneWidget);
    await tester.tap(find.byKey(const Key('hero-back')));
    expect(back, 1);
    expect(find.byTooltip('Alertes'), findsOneWidget);
  });

  testWidgets('carte chevauchante : remonte de 48 et reste touchable', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpApp(
      Column(
        children: [
          const SizedBox(height: 200, child: TikeoHeroBackground()),
          TikeoOverlapCard(
            child: SizedBox(
              height: 100,
              child: TextButton(
                key: const Key('in-card'),
                onPressed: () => taps++,
                child: const Text('Changer'),
              ),
            ),
          ),
          const SizedBox(key: Key('after'), height: 10),
        ],
      ),
    );
    final card = tester.getRect(find.byKey(const Key('in-card')));
    // Le haut de la carte (padding 16) est 48 au-dessus de la fin du fond.
    expect(card.top, 200 - 48 + 16);
    // La place occupée diminue d'autant : rien ne s'empile en dessous.
    expect(
      tester.getTopLeft(find.byKey(const Key('after'))).dy,
      200 + 16 + 100 + 16 - 48,
    );
    await tester.tap(find.byKey(const Key('in-card')));
    expect(taps, 1);
  });

  testWidgets('en-tête repliable : titre condensé au défilement', (
    tester,
  ) async {
    await tester.pumpApp(
      CustomScrollView(
        slivers: [
          const TikeoHeroSliver(title: 'Tickets', subtitle: 'Tous vos tickets'),
          SliverList.list(
            children: [
              for (var i = 0; i < 30; i++)
                SizedBox(height: 60, child: Text('Ligne $i')),
            ],
          ),
        ],
      ),
    );
    final header = find.byType(TikeoHeroBackground).first;
    final tall = tester.getSize(header).height;
    await tester.drag(find.text('Ligne 3'), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.getSize(header).height, lessThan(tall));
    expect(find.text('Tickets'), findsWidgets);
  });

  testWidgets('tuiles : chiffres annoncés, action rapide touchable', (
    tester,
  ) async {
    var tapped = 0;
    final semantics = tester.ensureSemantics();
    await tester.pumpApp(
      Column(
        children: [
          StatTile(
            tint: TikeoTints.light.blue,
            icon: Icons.confirmation_number_rounded,
            value: '8 450',
            label: 'tickets émis',
          ),
          const StatStrip(
            items: [
              (value: '42', label: 'entrés', color: null),
              (value: '120', label: 'émis', color: null),
            ],
          ),
          const StatRing(value: 0.35, label: '35 %'),
          SizedBox(
            width: 90,
            child: QuickActionTile(
              icon: Icons.add_rounded,
              label: 'Nouvel événement',
              primary: true,
              onTap: () => tapped++,
            ),
          ),
        ],
      ),
    );
    expect(find.bySemanticsLabel('8 450 tickets émis'), findsOneWidget);
    expect(find.bySemanticsLabel('42 entrés'), findsOneWidget);
    expect(find.bySemanticsLabel('35 %'), findsOneWidget);
    await tester.tap(find.text('Nouvel événement'));
    expect(tapped, 1);
    semantics.dispose();
  });

  testWidgets('bouton principal : actif, inactif, en attente', (tester) async {
    var taps = 0;
    await tester.pumpApp(
      Column(
        children: [
          TikeoPrimaryButton(label: 'Créer', onPressed: () => taps++),
          const TikeoPrimaryButton(label: 'Inactif', onPressed: null),
          TikeoPrimaryButton(
            key: const Key('busy'),
            label: 'Envoi',
            busy: true,
            onPressed: () => taps++,
          ),
        ],
      ),
    );
    expect(tester.getSize(find.byType(TikeoPrimaryButton).first).height, 56);
    await tester.tap(find.text('Créer'));
    await tester.tap(find.text('Inactif'));
    await tester.tap(find.byKey(const Key('busy')));
    expect(taps, 1);
    expect(find.text('Envoi'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('option, onglets, recherche, bandeau', (tester) async {
    var option = false;
    var tab = 0;
    var filters = 0;
    var closed = 0;
    await tester.pumpApp(
      Column(
        children: [
          SelectableOption(
            label: 'Payant',
            selected: false,
            onTap: () => option = true,
          ),
          StatusTabs<int>(
            values: const [0, 1],
            selected: 0,
            labelOf: (i) => ['Tous', 'Valables'][i],
            onSelected: (i) => tab = i,
          ),
          TikeoSearchBar(
            hint: 'Rechercher',
            onFilter: () => filters++,
            filterTooltip: 'Filtres',
            filterCount: 2,
          ),
          TintedBanner(
            tint: TikeoTints.light.salmon,
            icon: Icons.campaign_rounded,
            title: 'Annonce',
            onClose: () => closed++,
            closeTooltip: 'Fermer',
          ),
        ],
      ),
    );
    await tester.tap(find.text('Payant'));
    await tester.tap(find.text('Valables'));
    await tester.tap(find.byTooltip('Filtres'));
    await tester.tap(find.byTooltip('Fermer'));
    expect((option, tab, filters, closed), (true, 1, 1, 1));
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('ligne de liste : trait de statut, menu et appui long', (
    tester,
  ) async {
    var opened = 0;
    var held = 0;
    await tester.pumpApp(
      TikeoListRow(
        title: 'Awa Ouédraogo',
        subtitle: 'TS-7K3P-9QXM',
        stripe: TikeoTints.light.blue.icon,
        menu: IconButton(
          onPressed: () {},
          tooltip: 'Plus',
          icon: const Icon(Icons.more_vert_rounded),
        ),
        onTap: () => opened++,
        onLongPress: () => held++,
      ),
    );
    await tester.tap(find.text('Awa Ouédraogo'));
    await tester.longPress(find.text('Awa Ouédraogo'));
    expect((opened, held), (1, 1));
    expect(find.byTooltip('Plus'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'illustrations dessinées (thème ${dark ? 'sombre' : 'clair'})',
      (tester) async {
        await tester.pumpApp(
          Wrap(
            children: [
              for (final kind in TikeoIllustration.values)
                TikeoIllustrationView(kind, width: 80, height: 60),
            ],
          ),
          theme: dark ? TicketSurTheme.dark() : TicketSurTheme.light(),
        );
        expect(
          find.byType(TikeoIllustrationView),
          findsNWidgets(TikeoIllustration.values.length),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('état vide : illustration à la place de l’icône', (tester) async {
    await tester.pumpApp(
      const EmptyState(
        icon: Icons.event_rounded,
        illustration: TikeoIllustration.noEvents,
        title: 'Aucun événement',
      ),
    );
    expect(find.byType(TikeoIllustrationView), findsOneWidget);
    expect(find.byType(BrandSpot), findsNothing);
  });

  testWidgets(
    'point « en direct » : immobile si les animations sont réduites',
    (tester) async {
      reduceMotion(tester);
      await tester.pumpApp(const LiveDot());
      await tester.pumpAndSettle();
      expect(find.byType(LiveDot), findsOneWidget);
    },
  );

  test('types et rôles : teintes des maquettes', () {
    const t = TikeoTints.light;
    expect(eventKindTint(EventKind.concert, t), t.violet);
    expect(eventKindTint(EventKind.sport, t), t.green);
    expect(eventKindColor(EventKind.worship), TikeoKindColors.worship);
    expect(roleTint(MemberRole.owner, t), t.mint);
    expect(roleTint(MemberRole.manager, t), t.blue);
    expect(roleTint(MemberRole.controller, t), t.violet);
    expect(roleIcon(MemberRole.controller), Icons.qr_code_scanner_rounded);
  });
}
