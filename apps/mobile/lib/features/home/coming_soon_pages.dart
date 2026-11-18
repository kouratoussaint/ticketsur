import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/widgets/coming_soon_view.dart';
import 'package:ticketsur/l10n/l10n.dart';

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
