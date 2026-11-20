import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ticketsur/design_system/image_rules.dart';

/// Photo de test « bruitée » (difficile à compresser, comme une vraie photo).
Uint8List _photo(int width, int height, {int seed = 1}) {
  final random = math.Random(seed);
  final image = img.Image(width: width, height: height);
  for (final pixel in image) {
    pixel
      ..r = (pixel.x * 255 ~/ width + random.nextInt(60)) % 256
      ..g = (pixel.y * 255 ~/ height + random.nextInt(60)) % 256
      ..b = random.nextInt(256);
  }
  return img.encodeJpg(image, quality: 95);
}

void main() {
  group('règles des images', () {
    test('couverture : 1600 × 900 au plus, ≤ 400 Ko, vignette 480 × 270', () {
      final prepared = prepareImageSync(
        _photo(3200, 1800),
        'image/jpeg',
        ImageRules.cover,
      );
      final main = img.decodeImage(prepared.bytes)!;
      expect((main.width, main.height), (1600, 900));
      expect(prepared.bytes.length, lessThanOrEqualTo(400 * 1024));
      expect(prepared.mimeType, 'image/jpeg');
      expect(prepared.belowMinimum, isFalse);
      final thumb = img.decodeImage(prepared.thumbnail!)!;
      expect((thumb.width, thumb.height), (480, 270));
    });

    test('couverture en portrait : proportions gardées, poids respecté', () {
      final prepared = prepareImageSync(
        _photo(1200, 2400, seed: 2),
        'image/jpeg',
        ImageRules.cover,
      );
      final main = img.decodeImage(prepared.bytes)!;
      // Proportions gardées ; réduit encore si le poids l'exige.
      expect(main.height, lessThanOrEqualTo(1600));
      expect(main.width, lessThanOrEqualTo(900));
      expect(main.height, main.width * 2);
      expect(prepared.bytes.length, lessThanOrEqualTo(400 * 1024));
      // Vignette recadrée au centre en 16:9.
      final thumb = img.decodeImage(prepared.thumbnail!)!;
      expect((thumb.width, thumb.height), (480, 270));
    });

    test('petite image : acceptée, signalée, jamais agrandie', () {
      final prepared = prepareImageSync(
        _photo(640, 360, seed: 3),
        'image/jpeg',
        ImageRules.cover,
      );
      final main = img.decodeImage(prepared.bytes)!;
      expect((main.width, main.height), (640, 360));
      expect(prepared.belowMinimum, isTrue);
    });

    test('photo de profil : 400 au plus, ≤ 150 Ko, vignette carrée 128', () {
      final prepared = prepareImageSync(
        _photo(1000, 800, seed: 4),
        'image/jpeg',
        ImageRules.avatar,
      );
      final main = img.decodeImage(prepared.bytes)!;
      expect(math.max(main.width, main.height), 400);
      expect(prepared.bytes.length, lessThanOrEqualTo(150 * 1024));
      final thumb = img.decodeImage(prepared.thumbnail!)!;
      expect((thumb.width, thumb.height), (128, 128));
    });

    test('logo transparent : PNG gardé, vignette contenue dans 128', () {
      final logo = img.Image(width: 800, height: 400, numChannels: 4);
      for (final pixel in logo) {
        pixel
          ..r = 0
          ..g = 201
          ..b = 167
          ..a = pixel.x < 400 ? 255 : 0;
      }
      final prepared = prepareImageSync(
        img.encodePng(logo),
        'image/png',
        ImageRules.logo,
      );
      expect(prepared.mimeType, 'image/png');
      expect(prepared.extension, 'png');
      final main = img.decodePng(prepared.bytes)!;
      expect((main.width, main.height), (512, 256));
      expect(main.getPixel(500, 10).a, 0);
      final thumb = img.decodePng(prepared.thumbnail!)!;
      expect((thumb.width, thumb.height), (128, 64));
    });

    test('logo opaque : JPEG', () {
      final prepared = prepareImageSync(
        _photo(600, 600, seed: 5),
        'image/jpeg',
        ImageRules.logo,
      );
      expect(prepared.mimeType, 'image/jpeg');
      expect(prepared.bytes.length, lessThanOrEqualTo(200 * 1024));
    });

    test('fichier illisible : envoyé tel quel, sans vignette', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final prepared = prepareImageSync(bytes, 'image/webp', ImageRules.cover);
      expect(prepared.bytes, bytes);
      expect(prepared.mimeType, 'image/webp');
      expect(prepared.thumbnail, isNull);
    });

    test('chemin et adresse de la vignette', () {
      expect(
        thumbnailPath('org/evt/abc123def456.jpg'),
        'org/evt/abc123def456_v.jpg',
      );
      expect(thumbnailPath('u1/photo'), 'u1/photo_v');
      expect(
        thumbnailUrl(
          'https://x.supabase.co/storage/v1/object/public/event-covers/o/e/abcd1234.png',
        ),
        'https://x.supabase.co/storage/v1/object/public/event-covers/o/e/abcd1234_v.png',
      );
      expect(
        thumbnailUrl('https://cdn.test/a/b.jpg?v=2'),
        'https://cdn.test/a/b_v.jpg?v=2',
      );
    });
  });
}
