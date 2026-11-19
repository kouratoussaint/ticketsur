import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketsur/features/reports/domain/report.dart';

/// Dépôt du rapport (Supabase au démarrage, faux en test).
final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => throw UnimplementedError(
    'reportRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);
