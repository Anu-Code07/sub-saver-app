import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:subsaver/core/constants/app_constants.dart';
import 'package:subsaver/core/constants/firestore_paths.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';
import 'package:subsaver/core/services/hive_service.dart';
import 'package:subsaver/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:subsaver/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:uuid/uuid.dart';

class SubscriptionModel extends SubscriptionEntity {
  const SubscriptionModel({
    required super.id,
    required super.name,
    required super.provider,
    required super.category,
    required super.cost,
    required super.renewalDate,
    required super.billingCycle,
    required super.createdBy,
    super.groupId,
    super.members,
    super.status,
  });

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionModel(
      id: doc.id,
      name: data['name'] as String,
      provider: data['provider'] as String,
      category: SubscriptionCategory.fromString(data['category'] as String? ?? 'utilities'),
      cost: (data['cost'] as num).toDouble(),
      renewalDate: (data['renewalDate'] as Timestamp).toDate(),
      billingCycle: BillingCycle.fromString(data['billingCycle'] as String? ?? 'monthly'),
      createdBy: data['createdBy'] as String,
      groupId: data['groupId'] as String?,
      members: List<String>.from(data['members'] as List? ?? []),
      status: data['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'provider': provider,
        'category': category.label,
        'cost': cost,
        'renewalDate': Timestamp.fromDate(renewalDate),
        'billingCycle': billingCycle.name,
        'createdBy': createdBy,
        'groupId': groupId,
        'members': members,
        'status': status,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        ...toFirestore(),
        'renewalDate': renewalDate.toIso8601String(),
      };

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) => SubscriptionModel(
        id: json['id'] as String,
        name: json['name'] as String,
        provider: json['provider'] as String,
        category: SubscriptionCategory.fromString(json['category'] as String? ?? 'utilities'),
        cost: (json['cost'] as num).toDouble(),
        renewalDate: DateTime.parse(json['renewalDate'] as String),
        billingCycle: BillingCycle.fromString(json['billingCycle'] as String? ?? 'monthly'),
        createdBy: json['createdBy'] as String,
        groupId: json['groupId'] as String?,
        members: List<String>.from(json['members'] as List? ?? []),
        status: json['status'] as String? ?? 'active',
      );
}

class SubscriptionRemoteDataSource {
  SubscriptionRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  Stream<List<SubscriptionModel>> watchSubscriptions(String userId) {
    return _firestore
        .collection(AppConstants.subscriptionsCollection)
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs.map(SubscriptionModel.fromFirestore).toList());
  }

  Future<List<SubscriptionModel>> getSubscriptions(String userId) async {
    final snap = await _firestore
        .collection(AppConstants.subscriptionsCollection)
        .where('members', arrayContains: userId)
        .get();
    return snap.docs.map(SubscriptionModel.fromFirestore).toList();
  }

  Future<SubscriptionModel> getSubscription(String id) async {
    final doc = await _firestore.doc(FirestorePaths.subscription(id)).get();
    if (!doc.exists) throw StateError('Subscription not found');
    return SubscriptionModel.fromFirestore(doc);
  }

  Future<SubscriptionModel> createSubscription(SubscriptionModel sub) async {
    final id = sub.id.isEmpty ? _uuid.v4() : sub.id;
    final model = SubscriptionModel(
      id: id,
      name: sub.name,
      provider: sub.provider,
      category: sub.category,
      cost: sub.cost,
      renewalDate: sub.renewalDate,
      billingCycle: sub.billingCycle,
      createdBy: sub.createdBy,
      groupId: sub.groupId,
      members: sub.members,
      status: sub.status,
    );
    await _firestore.doc(FirestorePaths.subscription(id)).set(model.toFirestore());
    return model;
  }

  Future<SubscriptionModel> updateSubscription(SubscriptionModel sub) async {
    await _firestore.doc(FirestorePaths.subscription(sub.id)).update(sub.toFirestore());
    return sub;
  }

  Future<void> leaveSubscription(String subscriptionId, String userId) async {
    final doc = await _firestore.doc(FirestorePaths.subscription(subscriptionId)).get();
    if (!doc.exists) return;
    final members = List<String>.from((doc.data()?['members'] as List?) ?? []);
    members.remove(userId);
    await _firestore.doc(FirestorePaths.subscription(subscriptionId)).update({
      'members': members,
    });
  }

  Future<void> removeMember(String subscriptionId, String memberId) async {
    final doc = await _firestore.doc(FirestorePaths.subscription(subscriptionId)).get();
    if (!doc.exists) return;
    final members = List<String>.from((doc.data()?['members'] as List?) ?? []);
    members.remove(memberId);
    await _firestore.doc(FirestorePaths.subscription(subscriptionId)).update({
      'members': members,
    });
  }

  Future<void> cancelSubscription(String id) async {
    await _firestore.doc(FirestorePaths.subscription(id)).update({'status': 'cancelled'});
  }

  Future<void> deleteSubscription(String id) async {
    await _firestore.doc(FirestorePaths.subscription(id)).delete();
  }
}

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl(this._remote, this._hive);

  final SubscriptionRemoteDataSource _remote;
  final HiveService _hive;

  @override
  Future<List<SubscriptionEntity>> getSubscriptions(String userId) async {
    try {
      final subs = await _remote.getSubscriptions(userId);
      for (final s in subs) {
        await _hive.cacheData(AppConstants.subscriptionsBox, s.id, s.toJson());
      }
      return subs;
    } catch (_) {
      return _hive
          .getAllCached(AppConstants.subscriptionsBox)
          .map(SubscriptionModel.fromJson)
          .where((s) => s.members.contains(userId))
          .toList();
    }
  }

  @override
  Stream<List<SubscriptionEntity>> watchSubscriptions(String userId) =>
      _remote.watchSubscriptions(userId);

  @override
  Future<SubscriptionEntity> getSubscription(String id) async {
    try {
      final sub = await _remote.getSubscription(id);
      await _hive.cacheData(AppConstants.subscriptionsBox, id, sub.toJson());
      return sub;
    } catch (_) {
      final cached = _hive.getCachedData(AppConstants.subscriptionsBox, id);
      if (cached != null) return SubscriptionModel.fromJson(cached);
      rethrow;
    }
  }

  @override
  Future<SubscriptionEntity> createSubscription(SubscriptionEntity subscription) async {
    final model = SubscriptionModel(
      id: subscription.id,
      name: subscription.name,
      provider: subscription.provider,
      category: subscription.category,
      cost: subscription.cost,
      renewalDate: subscription.renewalDate,
      billingCycle: subscription.billingCycle,
      createdBy: subscription.createdBy,
      groupId: subscription.groupId,
      members: subscription.members,
      status: subscription.status,
    );
    final created = await _remote.createSubscription(model);
    await _hive.cacheData(AppConstants.subscriptionsBox, created.id, created.toJson());
    return created;
  }

  @override
  Future<SubscriptionEntity> updateSubscription(SubscriptionEntity subscription) async {
    final model = SubscriptionModel(
      id: subscription.id,
      name: subscription.name,
      provider: subscription.provider,
      category: subscription.category,
      cost: subscription.cost,
      renewalDate: subscription.renewalDate,
      billingCycle: subscription.billingCycle,
      createdBy: subscription.createdBy,
      groupId: subscription.groupId,
      members: subscription.members,
      status: subscription.status,
    );
    return _remote.updateSubscription(model);
  }

  @override
  Future<void> deleteSubscription(String id) async {
    await _remote.deleteSubscription(id);
    await _hive.subscriptionsBox.delete(id);
  }

  @override
  Future<void> leaveSubscription(String subscriptionId, String userId) =>
      _remote.leaveSubscription(subscriptionId, userId);

  @override
  Future<void> removeMember(String subscriptionId, String memberId) =>
      _remote.removeMember(subscriptionId, memberId);

  @override
  Future<void> cancelSubscription(String id) => _remote.cancelSubscription(id);
}
