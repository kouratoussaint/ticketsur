import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';

/// Pastille ronde : photo distante, sinon initiales sur fond de marque.
class UserAvatar extends StatelessWidget {
  const new({
    required this.initials,
    this.url,
    this.radius = 28,
    this.icon,
    super.key,
  });

  /// Initiales affichées sans photo.
  final String initials;

  /// Adresse de la photo.
  final String? url;

  final double radius;

  /// Icône à la place des initiales (logo d'organisation absent…).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: TicketSurColors.white,
      fontSize: radius * 0.7,
      fontWeight: FontWeight.w700,
    );
    final fallback = Center(
      child: icon != null
          ? Icon(icon, color: TicketSurColors.white, size: radius)
          : Text(initials, style: textStyle),
    );
    return SizedBox.square(
      dimension: radius * 2,
      child: ClipOval(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [TicketSurColors.mintDeep, TicketSurColors.navy],
            ),
          ),
          child: url == null
              ? fallback
              : Image.network(
                  url!,
                  key: const Key('avatar-image'),
                  fit: BoxFit.cover,
                  width: radius * 2,
                  height: radius * 2,
                  errorBuilder: (context, error, stack) => fallback,
                ),
        ),
      ),
    );
  }
}

/// Initiales d'un nom (« Awa Ouédraogo » → « AO »).
String initialsOf(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  String head(String word) => String.fromCharCode(word.runes.first);
  final last = words.length > 1 ? head(words.last) : '';
  return (head(words.first) + last).toUpperCase();
}
