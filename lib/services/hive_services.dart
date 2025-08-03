
import 'package:hive/hive.dart';
import '../models/txn.dart';

class HiveService {
  static const String boxName = 'transactions';
  static late Box<Txn> _box;

  /// Call this once at app startup
  static Future<void> init() async {
    _box = await Hive.openBox<Txn>(boxName);
  }

  /// Save or update a transaction
  static Future<void> addTxn(Txn txn) async {
    await _box.put(txn.id, txn);
  }

  /// Get all transactions
  static List<Txn> getAllTxns() => _box.values.toList();

  /// Unsynced only
  static List<Txn> getUnsyncedTxns() =>
      _box.values.where((t) => !t.isSynced).toList();

  /// Mark one as synced
  static Future<void> markAsSynced(String id) async {
    final txn = _box.get(id);
    if (txn != null) {
      txn.isSynced = true;
      await txn.save();
    }
  }
  static Future<void> deleteTxn(String id) async {
    final box = Hive.box<Txn>(boxName);
    await box.delete(id);
  }

  /// Clear all transactions from the Hive box
  static Future<void> clearAllTxns() async {
    final box = Hive.isBoxOpen(boxName)
        ? Hive.box<Txn>(boxName)
        : await Hive.openBox<Txn>(boxName);
    await box.clear();
  }
}
