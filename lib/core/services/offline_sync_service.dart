import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:subsaver/core/services/hive_service.dart';
import 'package:subsaver/core/services/network_info.dart';

class OfflineSyncService {
  OfflineSyncService(this._hive, this._firestore, this._networkInfo);

  final HiveService _hive;
  final FirebaseFirestore _firestore;
  final NetworkInfo _networkInfo;
  StreamSubscription<bool>? _connectivitySub;

  void startListening() {
    _connectivitySub = _networkInfo.onConnectivityChanged.listen((isOnline) {
      if (isOnline) syncPendingWrites();
    });
  }

  Future<void> syncPendingWrites() async {
    final pending = _hive.getPendingWrites();
    for (final write in pending) {
      try {
        final collection = write['collection'] as String;
        final docId = write['docId'] as String;
        final data = Map<String, dynamic>.from(write['data'] as Map);
        await _firestore.collection(collection).doc(docId).set(data, SetOptions(merge: true));
        await _hive.removePendingWrite(write['id'] as String);
      } catch (_) {
        // Keep in queue for next sync
      }
    }
  }

  Future<void> queueWrite({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final isOnline = await _networkInfo.isConnected;
    if (isOnline) {
      await _firestore.collection(collection).doc(docId).set(data, SetOptions(merge: true));
    } else {
      await _hive.queuePendingWrite({
        'id': docId,
        'collection': collection,
        'docId': docId,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}
