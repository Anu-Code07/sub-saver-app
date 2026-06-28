import 'package:hive_flutter/hive_flutter.dart';
import 'package:subsaver/core/constants/app_constants.dart';

class HiveService {
  Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<Map>(AppConstants.subscriptionsBox),
      Hive.openBox<Map>(AppConstants.groupsBox),
      Hive.openBox<Map>(AppConstants.expensesBox),
      Hive.openBox<Map>(AppConstants.pendingWritesBox),
      Hive.openBox<Map>(AppConstants.userBox),
    ]);
  }

  Box<Map> get subscriptionsBox => Hive.box<Map>(AppConstants.subscriptionsBox);
  Box<Map> get groupsBox => Hive.box<Map>(AppConstants.groupsBox);
  Box<Map> get expensesBox => Hive.box<Map>(AppConstants.expensesBox);
  Box<Map> get pendingWritesBox => Hive.box<Map>(AppConstants.pendingWritesBox);
  Box<Map> get userBox => Hive.box<Map>(AppConstants.userBox);

  Future<void> cacheData(String boxName, String key, Map<String, dynamic> data) async {
    final box = Hive.box<Map>(boxName);
    await box.put(key, data);
  }

  Map<String, dynamic>? getCachedData(String boxName, String key) {
    final box = Hive.box<Map>(boxName);
    final data = box.get(key);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  List<Map<String, dynamic>> getAllCached(String boxName) {
    final box = Hive.box<Map>(boxName);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> queuePendingWrite(Map<String, dynamic> write) async {
    final id = write['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
    await pendingWritesBox.put(id, write);
  }

  List<Map<String, dynamic>> getPendingWrites() {
    return pendingWritesBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> removePendingWrite(String id) async {
    await pendingWritesBox.delete(id);
  }

  Future<void> clearBox(String boxName) async {
    await Hive.box<Map>(boxName).clear();
  }
}
