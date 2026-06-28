import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:subsaver/core/constants/app_constants.dart';
import 'package:subsaver/core/constants/firestore_paths.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';
import 'package:subsaver/core/services/hive_service.dart';
import 'package:subsaver/features/groups/domain/entities/group_entity.dart';
import 'package:subsaver/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:uuid/uuid.dart';

class GroupModel extends GroupEntity {
  const GroupModel({
    required super.id,
    required super.name,
    required super.ownerId,
    required super.inviteCode,
    required super.members,
    super.walletBalance,
    super.createdAt,
  });

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final membersList = (data['members'] as List? ?? [])
        .map((m) => GroupMemberModel.fromMap(m as Map<String, dynamic>))
        .toList();
    return GroupModel(
      id: doc.id,
      name: data['name'] as String,
      ownerId: data['ownerId'] as String,
      inviteCode: data['inviteCode'] as String,
      members: membersList,
      walletBalance: (data['walletBalance'] as num?)?.toDouble() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'ownerId': ownerId,
        'inviteCode': inviteCode,
        'members': members
            .map((m) => {
                  'uid': m.uid,
                  'role': m.role.name,
                  'joinedAt': Timestamp.fromDate(m.joinedAt),
                  'name': m.name,
                  'avatar': m.avatar,
                })
            .toList(),
        'walletBalance': walletBalance,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      };
}

class GroupMemberModel extends GroupMemberEntity {
  const GroupMemberModel({
    required super.uid,
    required super.role,
    required super.joinedAt,
    super.name,
    super.avatar,
  });

  factory GroupMemberModel.fromMap(Map<String, dynamic> map) => GroupMemberModel(
        uid: map['uid'] as String,
        role: GroupRole.values.firstWhere(
          (r) => r.name == map['role'],
          orElse: () => GroupRole.member,
        ),
        joinedAt: (map['joinedAt'] as Timestamp).toDate(),
        name: map['name'] as String?,
        avatar: map['avatar'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'role': role.name,
        'joinedAt': Timestamp.fromDate(joinedAt),
        'name': name,
        'avatar': avatar,
      };
}

class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.groupId,
    required super.subscriptionId,
    required super.amount,
    required super.splitType,
    required super.splits,
    required super.paidBy,
    super.subscriptionName,
    super.createdAt,
  });

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc, String groupId) {
    final data = doc.data() as Map<String, dynamic>;
    final splits = (data['splits'] as List? ?? [])
        .map((s) => SplitModel.fromMap(s as Map<String, dynamic>))
        .toList();
    return ExpenseModel(
      id: doc.id,
      groupId: groupId,
      subscriptionId: data['subscriptionId'] as String,
      amount: (data['amount'] as num).toDouble(),
      splitType: SplitType.values.firstWhere(
        (t) => t.name == data['splitType'],
        orElse: () => SplitType.equal,
      ),
      splits: splits,
      paidBy: data['paidBy'] as String,
      subscriptionName: data['subscriptionName'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'subscriptionId': subscriptionId,
        'amount': amount,
        'splitType': splitType.name,
        'splits': splits
            .map((s) => {
                  'uid': s.uid,
                  'amount': s.amount,
                  'status': s.status.name,
                  'name': s.name,
                })
            .toList(),
        'paidBy': paidBy,
        'subscriptionName': subscriptionName,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      };
}

class SplitModel extends SplitEntity {
  const SplitModel({required super.uid, required super.amount, required super.status, super.name});

  factory SplitModel.fromMap(Map<String, dynamic> map) => SplitModel(
        uid: map['uid'] as String,
        amount: (map['amount'] as num).toDouble(),
        status: PaymentStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => PaymentStatus.pending,
        ),
        name: map['name'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'amount': amount,
        'status': status.name,
        'name': name,
      };
}

class GroupRemoteDataSource {
  GroupRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  String _generateInviteCode() => _uuid.v4().substring(0, 8).toUpperCase();

  Stream<List<GroupModel>> watchGroups(String userId) {
    return _firestore
        .collection(AppConstants.groupsCollection)
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs.map(GroupModel.fromFirestore).toList());
  }

  Future<GroupModel> createGroup(GroupModel group) async {
    final id = group.id.isEmpty ? _uuid.v4() : group.id;
    final inviteCode = group.inviteCode.isEmpty ? _generateInviteCode() : group.inviteCode;
    final model = GroupModel(
      id: id,
      name: group.name,
      ownerId: group.ownerId,
      inviteCode: inviteCode,
      members: group.members,
      walletBalance: group.walletBalance,
      createdAt: DateTime.now(),
    );
    await _firestore.doc(FirestorePaths.group(id)).set({
      ...model.toFirestore(),
      'memberIds': model.members.map((m) => m.uid).toList(),
    });
    return model;
  }

  Future<GroupModel> joinGroup(String inviteCode, String userId, {String? userName}) async {
    final snap = await _firestore
        .collection(AppConstants.groupsCollection)
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) throw Exception('Invalid invite code');
    final doc = snap.docs.first;
    final group = GroupModel.fromFirestore(doc);
    if (group.members.any((m) => m.uid == userId)) return group;

    final newMember = GroupMemberModel(
      uid: userId,
      role: GroupRole.member,
      joinedAt: DateTime.now(),
      name: userName,
    );
    final updatedMembers = [...group.members, newMember];
    await doc.reference.update({
      'members': updatedMembers.map((m) => (m as GroupMemberModel).toMap()).toList(),
      'memberIds': FieldValue.arrayUnion([userId]),
    });
    return GroupModel(
      id: group.id,
      name: group.name,
      ownerId: group.ownerId,
      inviteCode: group.inviteCode,
      members: updatedMembers,
      walletBalance: group.walletBalance,
      createdAt: group.createdAt,
    );
  }

  Future<void> removeMember(String groupId, String memberId) async {
    final doc = await _firestore.doc(FirestorePaths.group(groupId)).get();
    final group = GroupModel.fromFirestore(doc);
    final updated = group.members.where((m) => m.uid != memberId).toList();
    await doc.reference.update({
      'members': updated.map((m) => (m as GroupMemberModel).toMap()).toList(),
      'memberIds': FieldValue.arrayRemove([memberId]),
    });
  }

  Future<void> transferOwnership(String groupId, String newOwnerId) async {
    final doc = await _firestore.doc(FirestorePaths.group(groupId)).get();
    final group = GroupModel.fromFirestore(doc);
    final updated = group.members.map((m) {
      if (m.uid == newOwnerId) {
        return GroupMemberModel(uid: m.uid, role: GroupRole.owner, joinedAt: m.joinedAt, name: m.name, avatar: m.avatar);
      }
      if (m.uid == group.ownerId) {
        return GroupMemberModel(uid: m.uid, role: GroupRole.admin, joinedAt: m.joinedAt, name: m.name, avatar: m.avatar);
      }
      return m as GroupMemberModel;
    }).toList();
    await doc.reference.update({
      'ownerId': newOwnerId,
      'members': updated.map((m) => m.toMap()).toList(),
    });
  }

  Stream<List<ActivityEntity>> watchActivity(String groupId) {
    return _firestore
        .collection(FirestorePaths.groupActivity(groupId))
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return ActivityEntity(
                id: doc.id,
                type: data['type'] as String,
                actorId: data['actorId'] as String,
                actorName: data['actorName'] as String? ?? 'User',
                message: data['message'] as String,
                timestamp: (data['timestamp'] as Timestamp).toDate(),
                metadata: data['metadata'] as Map<String, dynamic>?,
              );
            }).toList());
  }

  Future<void> addActivity(String groupId, ActivityEntity activity) async {
    await _firestore.collection(FirestorePaths.groupActivity(groupId)).add({
      'type': activity.type,
      'actorId': activity.actorId,
      'actorName': activity.actorName,
      'message': activity.message,
      'timestamp': Timestamp.fromDate(activity.timestamp),
      'metadata': activity.metadata,
    });
  }
}

class ExpenseRemoteDataSource {
  ExpenseRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  Stream<List<ExpenseModel>> watchExpenses(String groupId) {
    return _firestore
        .collection(FirestorePaths.groupExpenses(groupId))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ExpenseModel.fromFirestore(d, groupId)).toList());
  }

  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    final id = expense.id.isEmpty ? _uuid.v4() : expense.id;
    final model = ExpenseModel(
      id: id,
      groupId: expense.groupId,
      subscriptionId: expense.subscriptionId,
      amount: expense.amount,
      splitType: expense.splitType,
      splits: expense.splits,
      paidBy: expense.paidBy,
      subscriptionName: expense.subscriptionName,
      createdAt: DateTime.now(),
    );
    await _firestore
        .doc(FirestorePaths.groupExpense(expense.groupId, id))
        .set(model.toFirestore());
    return model;
  }

  Future<void> updateSplitStatus(String groupId, String expenseId, String uid, PaymentStatus status) async {
    final doc = await _firestore.doc(FirestorePaths.groupExpense(groupId, expenseId)).get();
    final expense = ExpenseModel.fromFirestore(doc, groupId);
    final updatedSplits = expense.splits.map((s) {
      if (s.uid == uid) {
        return SplitModel(uid: s.uid, amount: s.amount, status: status, name: s.name);
      }
      return s as SplitModel;
    }).toList();
    await doc.reference.update({
      'splits': updatedSplits.map((s) => s.toMap()).toList(),
    });
  }
}

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl(this._remote, HiveService hive);

  final GroupRemoteDataSource _remote;

  @override
  Future<List<GroupEntity>> getGroups(String userId) async {
    try {
      final groups = await _remote.watchGroups(userId).first;
      return groups;
    } catch (_) {
      return [];
    }
  }

  @override
  Stream<List<GroupEntity>> watchGroups(String userId) => _remote.watchGroups(userId);

  @override
  Future<GroupEntity> getGroup(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<GroupEntity> createGroup(GroupEntity group) async {
    final model = GroupModel(
      id: group.id,
      name: group.name,
      ownerId: group.ownerId,
      inviteCode: group.inviteCode,
      members: group.members,
      walletBalance: group.walletBalance,
      createdAt: group.createdAt,
    );
    return _remote.createGroup(model);
  }

  @override
  Future<GroupEntity> joinGroup(String inviteCode, String userId) =>
      _remote.joinGroup(inviteCode, userId);

  @override
  Future<void> removeMember(String groupId, String memberId) =>
      _remote.removeMember(groupId, memberId);

  @override
  Future<void> transferOwnership(String groupId, String newOwnerId) =>
      _remote.transferOwnership(groupId, newOwnerId);

  @override
  Stream<List<ActivityEntity>> watchActivity(String groupId) =>
      _remote.watchActivity(groupId);

  @override
  Future<void> addActivity(ActivityEntity activity) async {
    final groupId = activity.metadata?['groupId'] as String? ?? '';
    if (groupId.isEmpty) return;
    await _remote.addActivity(groupId, activity);
  }
}

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl(this._remote);

  final ExpenseRemoteDataSource _remote;

  @override
  Future<List<ExpenseEntity>> getExpenses(String groupId) async =>
      _remote.watchExpenses(groupId).first;

  @override
  Stream<List<ExpenseEntity>> watchExpenses(String groupId) =>
      _remote.watchExpenses(groupId);

  @override
  Future<ExpenseEntity> createExpense(ExpenseEntity expense) async {
    final model = ExpenseModel(
      id: expense.id,
      groupId: expense.groupId,
      subscriptionId: expense.subscriptionId,
      amount: expense.amount,
      splitType: expense.splitType,
      splits: expense.splits,
      paidBy: expense.paidBy,
      subscriptionName: expense.subscriptionName,
      createdAt: expense.createdAt,
    );
    return _remote.createExpense(model);
  }

  @override
  Future<void> updateSplitStatus(String groupId, String expenseId, String uid, PaymentStatus status) =>
      _remote.updateSplitStatus(groupId, expenseId, uid, status);
}
