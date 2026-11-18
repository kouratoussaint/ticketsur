import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/widgets/coming_soon_view.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Onglet Événements (S07, Phase 2).
class EventsTabPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navEvents)),
      body: ComingSoonView(
        icon: Icons.event_rounded,
        title: l10n.eventsSoonTitle,
        body: l10n.eventsSoonBody,
        badge: l10n.phaseBadge('2'),
      ),
    );
  }
}

/// Onglet Billets (S14, Phase 3).
class TicketsTabPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTickets)),
      body: ComingSoonView(
        icon: Icons.confirmation_number_rounded,
        title: l10n.ticketsSoonTitle,
        body: l10n.ticketsSoonBody,
        badge: l10n.phaseBadge('3'),
      ),
    );
  }
}

/// Onglet Équipe (S16, Phase 2).
class TeamTabPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTeam)),
      body: ComingSoonView(
        icon: Icons.groups_rounded,
        title: l10n.teamSoonTitle,
        body: l10n.teamSoonBody,
        badge: l10n.phaseBadge('2'),
      ),
    );
  }
}
