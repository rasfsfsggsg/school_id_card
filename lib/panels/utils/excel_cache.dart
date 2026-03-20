import 'dart:typed_data';
import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_browser.dart';

class ExcelCache {
  static const String _dbName = 'excel_cache_db';
  static const String _storeName = 'excel_files';
  static const String _key = 'last_excel';

  static Future<Database> _openDb() async {
    final factory = getIdbFactory();
    if (factory == null) {
      throw Exception('IndexedDB not supported');
    }

    return factory.open(
      _dbName,
      version: 1,
      onUpgradeNeeded: (e) {
        final db = e.database;
        if (!db.objectStoreNames.contains(_storeName)) {
          db.createObjectStore(_storeName);
        }
      },
    );
  }

  /// Save excel bytes
  static Future<void> saveExcel(Uint8List bytes) async {
    final db = await _openDb();
    final txn = db.transaction(_storeName, idbModeReadWrite);
    final store = txn.objectStore(_storeName);

    await store.put(bytes, _key);
    await txn.completed;
    db.close();
  }

  /// Load excel bytes
  static Future<Uint8List?> loadExcel() async {
    final db = await _openDb();
    final txn = db.transaction(_storeName, idbModeReadOnly);
    final store = txn.objectStore(_storeName);

    final data = await store.getObject(_key);
    await txn.completed;
    db.close();

    return data is Uint8List ? data : null;
  }

  /// Clear cached excel (optional)
  static Future<void> clear() async {
    final db = await _openDb();
    final txn = db.transaction(_storeName, idbModeReadWrite);
    await txn.objectStore(_storeName).clear();
    await txn.completed;
    db.close();
  }
}
