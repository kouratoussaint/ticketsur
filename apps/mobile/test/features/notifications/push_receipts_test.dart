import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketsur/features/notifications/data/push_receipts.dart';

void main() {
  test(
    'réceptions notées, 50 au plus, puis retirées une fois confirmées',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(lastPushReceived(prefs), isNull);
      for (var i = 1; i <= 55; i++) {
        await notePushReceived(prefs, '$i', DateTime.utc(2030, 6, 1, 10));
      }
      await notePushReceived(prefs, '55', DateTime.utc(2030, 6, 1, 11));
      await notePushReceived(prefs, null, DateTime.utc(2030, 6, 1, 12));
      final pending = pendingPushReceipts(prefs);
      expect(pending.length, 50);
      expect(pending.first, 6);
      expect(pending.last, 55);
      expect(lastPushReceived(prefs), DateTime.utc(2030, 6, 1, 12).toLocal());

      await clearPushReceipts(prefs, [6, 7, 55]);
      expect(pendingPushReceipts(prefs), [for (var i = 8; i <= 54; i++) i]);
    },
  );
}
