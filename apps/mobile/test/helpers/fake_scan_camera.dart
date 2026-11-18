import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/features/scanner/presentation/camera/scan_camera.dart';

/// Caméra de test : montre l'en-tête et le pied de page du poste et « lit »
/// [code] quand on touche « fake-camera-read ».
class FakeCameraFeed {
  String code = '';
  int reads = 0;

  ScanCameraBuilder get builder =>
      ({
        required onCode,
        required header,
        required footer,
        required onManualEntry,
      }) => ColoredBox(
        color: const Color(0xFF000000),
        child: SafeArea(
          child: Column(
            children: [
              header,
              const Spacer(),
              TextButton(
                key: const Key('fake-camera-read'),
                onPressed: () {
                  reads++;
                  onCode(code);
                },
                child: const Text('lire'),
              ),
              footer,
            ],
          ),
        ),
      );
}
