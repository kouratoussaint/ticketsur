import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/widgets/cached_network_image.dart';

void main() {
  test('nom de fichier stable, extension gardée', () {
    const url = 'https://x.supabase.co/storage/v1/object/public/a/b/c.JPG';
    expect(cacheFileName(url), cacheFileName(url));
    expect(cacheFileName(url), endsWith('.jpg'));
    expect(cacheFileName(url), isNot(cacheFileName('${url}x')));
    expect(cacheFileName('https://x/y'), hasLength(16));
  });

  test('sans dossier de cache : image réseau simple', () {
    networkImageCacheDirectory = null;
    expect(networkImage('https://x/y.png'), isA<NetworkImage>());
  });

  testWidgets('image déjà en cache : lue sur le disque, sans réseau', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('tikeo-cache');
    addTearDown(() => directory.deleteSync(recursive: true));
    const url = 'https://hors-ligne.invalid/couverture.png';
    File('${directory.path}/${cacheFileName(url)}').writeAsBytesSync(
      File('assets/branding/Tikeo_Logo_Clair_480.png').readAsBytesSync(),
    );
    networkImageCacheDirectory = directory;
    addTearDown(() => networkImageCacheDirectory = null);
    final provider = networkImage(url);
    expect(provider, isA<DiskCachedNetworkImage>());
    await tester.runAsync(() async {
      final completer = Completer<ImageInfo>();
      provider
          .resolve(ImageConfiguration.empty)
          .addListener(
            ImageStreamListener(
              (info, _) => completer.complete(info),
              onError: completer.completeError,
            ),
          );
      final info = await completer.future.timeout(const Duration(seconds: 10));
      // Lue sur le disque malgré une adresse injoignable.
      expect(info.image.width, greaterThan(0));
    });
  });

  test('élagage : les plus anciens fichiers partent en premier', () async {
    final directory = Directory.systemTemp.createTempSync('tikeo-prune');
    addTearDown(() => directory.deleteSync(recursive: true));
    for (var i = 0; i < 5; i++) {
      File('${directory.path}/f$i')
        ..writeAsBytesSync(List.filled(1000, i))
        ..setLastModifiedSync(DateTime(2030, 1, 1, i));
    }
    await pruneNetworkImageCache(directory, maxBytes: 3000);
    final left = directory.listSync().map((e) => e.uri.pathSegments.last);
    expect(left.toSet(), {'f3', 'f4'});
  });
}
