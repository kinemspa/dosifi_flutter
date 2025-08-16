import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dosifi_flutter/core/services/database_service.dart';
import 'package:path/path.dart' as p;

class _MemorySecureStorage implements ISecureStorage {
  final Map<String, String> _store = {};
  @override
  Future<String?> read({required String key}) async => _store[key];
  @override
  Future<void> write({required String key, String? value}) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseService.backupDatabase', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dosifi_db_test_');
      DatabaseService.databasePathProviderOverride = () async => tempDir.path;
      DatabaseService.setSecureStorage(_MemorySecureStorage());
      DatabaseService.setPasswordKey('test_db_password');
    });

    tearDown(() async {
      await DatabaseService.closeDatabase();
      DatabaseService.resetTestOverrides();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('copies encrypted DB file to a timestamped backup path', () async {
      // Create a fake encrypted db file to simulate an initialized DB
      final dbPath = p.join(tempDir.path, 'dosifi_encrypted.db');
      await File(dbPath).writeAsString('encrypted_db_contents');

      final backupPath = await DatabaseService.backupDatabase();

      expect(backupPath.startsWith(tempDir.path), isTrue);
      expect(backupPath.contains('dosifi_backup_'), isTrue);
      final backupFile = File(backupPath);
      expect(await backupFile.exists(), isTrue);

      // Ensure contents match
      final original = await File(dbPath).readAsString();
      final copied = await backupFile.readAsString();
      expect(copied, original);
    });

    test('throws when source DB file does not exist', () async {
      await expectLater(
        () => DatabaseService.backupDatabase(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
