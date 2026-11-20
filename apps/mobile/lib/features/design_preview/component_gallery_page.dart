import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/status_chip.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/events/presentation/event_status_chip.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Galerie des composants de la direction artistique (ADR 0026), pour la
/// revue en image, en clair et en sombre. Données fictives, aucun appel
/// réseau ; les écrans de l'application les adoptent PR par PR.
class ComponentGalleryPage extends StatefulWidget {
  const new({super.key});

  @override
  State<ComponentGalleryPage> createState() => _ComponentGalleryPageState();
}

class _ComponentGalleryPageState extends State<ComponentGalleryPage> {
  var _option = 0;
  var _tab = 0;
  var _switch = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tints = context.tints;
    final theme = Theme.of(context);
    Widget gap([double h = TikeoSizes.cardGap]) => SizedBox(height: h);
    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.fromLTRB(16, TikeoSizes.sectionGap, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title),
          gap(),
          ...children,
        ],
      ),
    );
    return Scaffold(
      key: const Key('component-gallery'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 48),
        children: [
          TikeoHeroHeader(
            title: 'Bonjour Toussaint',
            subtitle: 'Voici ce qui se passe aujourd’hui.',
            illustration: TikeoIllustration.tickets,
            onBack: () => Navigator.of(context).maybePop(),
            actions: [
              TikeoHeaderBell(
                onPressed: () {},
                tooltip: l10n.componentGalleryTitle,
                dot: true,
              ),
              const SizedBox(width: 4),
              const CircleAvatar(
                radius: TikeoSizes.avatarHeader / 2,
                backgroundColor: TikeoColors.avatarMintPale,
                child: Text(
                  'T',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: TicketSurColors.navy,
                  ),
                ),
              ),
            ],
          ),
          TikeoOverlapCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tints.mint.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.storefront_rounded, color: tints.mint.icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ANKA EVENT', style: theme.textTheme.titleMedium),
                      Text(
                        'Propriétaire · toussaint@exemple.bf',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.unfold_more_rounded),
              ],
            ),
          ),
          section('Actions rapides', [
            Row(
              children: [
                for (final (i, (icon, label)) in const [
                  (Icons.add_rounded, 'Nouvel événement'),
                  (Icons.confirmation_number_rounded, 'Émettre des tickets'),
                  (Icons.qr_code_scanner_rounded, 'Scanner'),
                  (Icons.group_add_rounded, 'Inviter l’équipe'),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: QuickActionTile(
                      icon: icon,
                      label: label,
                      primary: i == 0,
                      onTap: () {},
                    ),
                  ),
                ],
              ],
            ),
          ]),
          section('Prochain événement', [
            HeroEventCard(
              title: 'Nuit du jazz de Ouaga',
              badges: [
                StatusChip(
                  label: 'En cours',
                  tone: StatusTone.positive,
                  tint: tints.live,
                  icon: Icons.sensors_rounded,
                ),
              ],
              overline: 'Concert',
              lines: const [
                (icon: Icons.event_rounded, text: 'Sam. 20 déc. · 20:00'),
                (icon: Icons.place_rounded, text: 'Jardin de la musique'),
              ],
              stats: const [
                (value: '342', label: 'entrées', color: TicketSurColors.mint),
                (value: '500', label: 'tickets', color: null),
                (value: '68 %', label: 'présence', color: null),
              ],
              actionLabel: 'Suivre les entrées en direct',
              actionIcon: Icons.insights_rounded,
              onAction: () {},
            ),
            gap(),
            const Center(child: CarouselDotsPreview()),
          ]),
          section('Chiffres', [
            // Deux tuiles par ligne, hauteur selon le contenu.
            for (final row in [
              [
                (tints.mint, Icons.event_rounded, '12', 'événements'),
                (
                  tints.blue,
                  Icons.confirmation_number_rounded,
                  '8 450',
                  'tickets émis',
                ),
              ],
              [
                (tints.amber, Icons.groups_rounded, '6 320', 'participants'),
                (tints.violet, Icons.insights_rounded, '4', 'en cours'),
              ],
            ]) ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, (tint, icon, value, label))
                        in row.indexed) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: StatTile(
                          tint: tint,
                          icon: icon,
                          value: value,
                          label: label,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              gap(8),
            ],
            const TikeoCard(
              child: Row(
                children: [
                  Expanded(
                    child: StatStrip(
                      items: [
                        (value: '120', label: 'émis', color: null),
                        (value: '42', label: 'entrés', color: null),
                        (value: '3', label: 'refusés', color: null),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  StatRing(value: 0.35, label: '35 %'),
                ],
              ),
            ),
          ]),
          section('Pastilles', [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in TicketStatus.values)
                  StatusChip(
                    label: ticketStatusLabel(l10n, status),
                    tone: StatusTone.neutral,
                    tint: ticketStatusTint(status, tints),
                    icon: ticketStatusStyle(status, tints).icon,
                  ),
                for (final status in EventStatus.values)
                  EventStatusChip(status: status),
                for (final kind in EventKind.values)
                  TikeoPill(
                    label: eventKindLabel(l10n, kind),
                    tint: eventKindTint(kind, tints),
                    uppercase: true,
                  ),
                for (final role in MemberRole.values)
                  TikeoPill(
                    label: roleLabel(l10n, role),
                    tint: roleTint(role, tints),
                    icon: roleIcon(role),
                  ),
                TikeoPill(
                  label: 'VIP',
                  tint: tints.vip,
                  icon: Icons.workspace_premium_rounded,
                ),
                TikeoPill(label: 'Entrée : 2 000 FCFA', tint: tints.mint),
                TikeoPill(
                  label: 'Valable',
                  tint: tints.blue,
                  icon: Icons.schedule_rounded,
                  large: true,
                ),
              ],
            ),
            gap(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: TikeoColors.heroGradient,
                borderRadius: BorderRadius.circular(TikeoRadii.card),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final kind in EventKind.values)
                    KindOnPhotoPill(
                      label: eventKindLabel(l10n, kind),
                      color: eventKindColor(kind),
                    ),
                  const LiveDot(),
                ],
              ),
            ),
          ]),
          section('Bandeaux', [
            TintedBanner(
              tint: tints.green,
              icon: Icons.check_rounded,
              title: 'Ticket valable',
              body: 'Ce ticket n’a pas encore été utilisé.',
            ),
            gap(),
            TintedBanner(
              tint: tints.salmon,
              icon: Icons.campaign_rounded,
              title: 'Maintenance samedi',
              body: 'Tikéo sera indisponible de 2 h à 3 h.',
              onClose: () {},
              closeTooltip: 'Fermer',
            ),
          ]),
          section('Listes et réglages', [
            TikeoListRow(
              title: 'Awa Ouédraogo',
              subtitle: 'TS-7K3P-9QXM · VIP',
              lines: const ['Émis le 18 nov. à 19:42'],
              stripe: ticketStatusTint(TicketStatus.issued, tints).icon,
              leading: CircleAvatar(
                radius: TikeoSizes.avatarList / 2,
                backgroundColor: tints.amber.background,
                child: Text('AO', style: TextStyle(color: tints.amber.text)),
              ),
              badge: const StatusChip(
                label: 'Valable',
                tone: StatusTone.info,
                icon: Icons.schedule_rounded,
              ),
              menu: IconButton(
                onPressed: () {},
                tooltip: 'Plus',
                icon: const Icon(Icons.more_vert_rounded),
              ),
              onTap: () {},
            ),
            gap(),
            TikeoCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  SettingsRow(
                    icon: Icons.notifications_rounded,
                    tint: tints.violet,
                    title: 'Notifications',
                    subtitle: 'Rappels et réponses du support',
                    trailing: Switch(
                      value: _switch,
                      onChanged: (v) => setState(() => _switch = v),
                    ),
                  ),
                  SettingsRow(
                    icon: Icons.logout_rounded,
                    tint: tints.red,
                    title: 'Se déconnecter',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ]),
          section('Boutons', [
            TikeoPrimaryButton(
              label: 'Créer l’événement',
              icon: Icons.add_rounded,
              onPressed: () {},
            ),
            gap(8),
            const TikeoPrimaryButton(label: 'Indisponible', onPressed: null),
            gap(8),
            TikeoDarkButton(
              label: 'Scanner à l’entrée',
              icon: Icons.qr_code_scanner_rounded,
              onPressed: () {},
            ),
            gap(8),
            OutlinedButton(onPressed: () {}, child: const Text('Secondaire')),
            gap(8),
            TikeoDangerButton(
              label: 'Annuler le ticket',
              icon: Icons.block_rounded,
              onPressed: () {},
            ),
          ]),
          section('Champs', [
            const TikeoFieldLabel(
              label: 'Titre de l’événement',
              icon: Icons.title_rounded,
              required: true,
            ),
            const TextField(
              maxLength: 200,
              decoration: InputDecoration(hintText: 'Nuit du jazz'),
            ),
            gap(8),
            for (final (i, label) in const ['Gratuit', 'Payant'].indexed) ...[
              SelectableOption(
                label: label,
                icon: i == 0 ? Icons.money_off_rounded : Icons.payments_rounded,
                selected: _option == i,
                onTap: () => setState(() => _option = i),
              ),
              gap(8),
            ],
            TikeoSearchBar(
              hint: 'Concert, lieu, promoteur…',
              onFilter: () {},
              filterCount: 2,
            ),
            gap(),
            StatusTabs<int>(
              values: const [0, 1, 2, 3],
              selected: _tab,
              labelOf: (i) =>
                  const ['Tous', 'Valables', 'Utilisés', 'Annulés'][i],
              onSelected: (i) => setState(() => _tab = i),
            ),
            gap(),
            const Center(
              child: QrViewfinder(
                child: FittedBox(
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    color: TicketSurColors.navy,
                  ),
                ),
              ),
            ),
          ]),
          section('Illustrations', [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final kind in TikeoIllustration.values)
                  TikeoIllustrationView(kind, width: 96, height: 72),
              ],
            ),
          ]),
        ],
      ),
    );
  }
}

/// Points d'un carrousel (aperçu sur fond Nuit).
class CarouselDotsPreview extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: TicketSurColors.navy,
      borderRadius: BorderRadius.circular(TikeoRadii.pill),
    ),
    child: const CarouselDots(count: 4, index: 1),
  );
}
