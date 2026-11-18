import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/features/scanner/presentation/camera/scan_overlay.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Construit la vue caméra du poste de scan. [header] et [footer] sont
/// posés par-dessus l'image ; [onCode] reçoit chaque QR lu dans le cadre.
typedef ScanCameraBuilder = Widget Function({
  required ValueChanged<String> onCode,
  required Widget header,
  required Widget footer,
  required VoidCallback onManualEntry,
});

/// Vue caméra (caméra réelle ; remplacée en test).
final scanCameraBuilderProvider = Provider<ScanCameraBuilder>(
  (ref) =>
      ({
        required onCode,
        required header,
        required footer,
        required onManualEntry,
      }) => LiveScanCamera(
        onCode: onCode,
        header: header,
        footer: footer,
        onManualEntry: onManualEntry,
      ),
);

/// Caméra arrière en plein écran : QR codes seulement, lus dans le cadre,
/// lampe torche, état clair si la permission est refusée. Le cycle de vie
/// (arrière-plan, retour) est géré par `mobile_scanner`.
class LiveScanCamera extends StatefulWidget {
  const new({
    required this.onCode,
    required this.header,
    required this.footer,
    required this.onManualEntry,
    super.key,
  });

  final ValueChanged<String> onCode;
  final Widget header;
  final Widget footer;
  final VoidCallback onManualEntry;

  @override
  State<LiveScanCamera> createState() => _LiveScanCameraState();
}

class _LiveScanCameraState extends State<LiveScanCamera> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        widget.onCode(raw);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final window = scanWindowFor(constraints.biggest);
        return Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              scanWindow: window,
              errorBuilder: (context, error) => CameraErrorView(
                permissionDenied:
                    error.errorCode == MobileScannerErrorCode.permissionDenied,
                onRetry: () => unawaited(_controller.start()),
                onManualEntry: widget.onManualEntry,
              ),
            ),
            ScanOverlay(window: window),
            SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: widget.header),
                      _TorchButton(controller: _controller),
                    ],
                  ),
                  const Spacer(),
                  widget.footer,
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TorchButton extends StatelessWidget {
  const new({required this.controller});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (!state.isInitialized ||
            state.torchState == TorchState.unavailable) {
          return const SizedBox(width: 48);
        }
        final on = state.torchState == TorchState.on;
        return IconButton(
          key: const Key('scanner-torch'),
          tooltip: on ? l10n.scannerTorchOff : l10n.scannerTorchOn,
          onPressed: () => unawaited(controller.toggleTorch()),
          style: IconButton.styleFrom(
            backgroundColor: on
                ? TicketSurColors.white
                : const Color(0x55000000),
            foregroundColor: on ? TicketSurColors.navy : TicketSurColors.white,
          ),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                RotationTransition(turns: animation, child: child),
            child: Icon(
              on ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
              key: ValueKey(on),
            ),
          ),
        );
      },
    );
  }
}

/// Caméra inutilisable : permission refusée ou matériel occupé.
class CameraErrorView extends StatelessWidget {
  const new({
    required this.permissionDenied,
    required this.onRetry,
    required this.onManualEntry,
    super.key,
  });

  final bool permissionDenied;
  final VoidCallback onRetry;
  final VoidCallback onManualEntry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return ColoredBox(
      color: TicketSurColors.surfaceDark,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TicketSurSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  permissionDenied
                      ? Icons.no_photography_rounded
                      : Icons.videocam_off_rounded,
                  size: 64,
                  color: TicketSurColors.white,
                ),
                const SizedBox(height: TicketSurSpacing.md),
                Text(
                  permissionDenied
                      ? l10n.cameraDeniedTitle
                      : l10n.cameraErrorTitle,
                  key: const Key('camera-error-title'),
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    color: TicketSurColors.white,
                  ),
                ),
                const SizedBox(height: TicketSurSpacing.xs),
                Text(
                  permissionDenied
                      ? l10n.cameraDeniedBody
                      : l10n.cameraErrorBody,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: TicketSurColors.white,
                  ),
                ),
                const SizedBox(height: TicketSurSpacing.lg),
                FilledButton.icon(
                  key: const Key('camera-retry'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.cameraRetry),
                ),
                const SizedBox(height: TicketSurSpacing.xs),
                OutlinedButton.icon(
                  onPressed: onManualEntry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TicketSurColors.white,
                    side: const BorderSide(color: TicketSurColors.white),
                  ),
                  icon: const Icon(Icons.keyboard_rounded),
                  label: Text(l10n.scannerManual),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
