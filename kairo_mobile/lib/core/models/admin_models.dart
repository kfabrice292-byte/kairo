import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogModel {
  final String id;
  final String uid;
  final String actionType;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  ActivityLogModel({
    required this.id,
    required this.uid,
    required this.actionType,
    required this.metadata,
    required this.timestamp,
  });

  factory ActivityLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ActivityLogModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      actionType: data['actionType'] ?? '',
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'actionType': actionType,
      'metadata': metadata,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

class PromoCodeModel {
  final String id;
  final String code;
  final int durationDays;
  final int maxUses;
  final int currentUses;
  final String type; // 'SINGLE', 'MULTI', 'UNLIMITED'
  final DateTime? expiresAt;
  final String createdBy;
  final DateTime createdAt;

  PromoCodeModel({
    required this.id,
    required this.code,
    required this.durationDays,
    required this.maxUses,
    required this.currentUses,
    required this.type,
    this.expiresAt,
    required this.createdBy,
    required this.createdAt,
  });

  bool get isValid {
    if (expiresAt != null && expiresAt!.isBefore(DateTime.now())) {
      return false;
    }
    if (type != 'UNLIMITED' && currentUses >= maxUses) {
      return false;
    }
    return true;
  }

  factory PromoCodeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PromoCodeModel(
      id: doc.id,
      code: data['code'] ?? '',
      durationDays: data['durationDays'] ?? 0,
      maxUses: data['maxUses'] ?? 0,
      currentUses: data['currentUses'] ?? 0,
      type: data['type'] ?? 'SINGLE',
      expiresAt: data['expiresAt'] != null 
          ? (data['expiresAt'] as Timestamp).toDate() 
          : null,
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'durationDays': durationDays,
      'maxUses': maxUses,
      'currentUses': currentUses,
      'type': type,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class AdminActionModel {
  final String id;
  final String adminUid;
  final String targetUid;
  final String action;
  final String reason;
  final DateTime timestamp;

  AdminActionModel({
    required this.id,
    required this.adminUid,
    required this.targetUid,
    required this.action,
    required this.reason,
    required this.timestamp,
  });

  factory AdminActionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdminActionModel(
      id: doc.id,
      adminUid: data['adminUid'] ?? '',
      targetUid: data['targetUid'] ?? '',
      action: data['action'] ?? '',
      reason: data['reason'] ?? '',
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adminUid': adminUid,
      'targetUid': targetUid,
      'action': action,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
