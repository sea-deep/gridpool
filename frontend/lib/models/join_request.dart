import 'package:cloud_firestore/cloud_firestore.dart';

enum JoinRequestStatus { pending, approved, rejected }

extension JoinRequestStatusX on JoinRequestStatus {
  String get value {
    switch (this) {
      case JoinRequestStatus.pending:
        return 'pending';
      case JoinRequestStatus.approved:
        return 'approved';
      case JoinRequestStatus.rejected:
        return 'rejected';
    }
  }

  static JoinRequestStatus fromValue(String value) {
    switch (value) {
      case 'approved':
        return JoinRequestStatus.approved;
      case 'rejected':
        return JoinRequestStatus.rejected;
      default:
        return JoinRequestStatus.pending;
    }
  }
}

class JoinRequest {
  final String id;
  final String userId;
  final String poolId;
  final String userName;
  final String userEmail;
  final String userAvatarUrl;
  final JoinRequestStatus status;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  const JoinRequest({
    required this.id,
    required this.userId,
    required this.poolId,
    required this.userName,
    required this.userEmail,
    required this.userAvatarUrl,
    required this.status,
    this.createdAt,
    this.reviewedAt,
  });

  factory JoinRequest.fromJson(String id, Map<String, dynamic> json) {
    return JoinRequest(
      id: id,
      userId: json['userId'] as String? ?? '',
      poolId: json['poolId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      userAvatarUrl: json['userAvatarUrl'] as String? ?? '',
      status: JoinRequestStatusX.fromValue(
        json['status'] as String? ?? 'pending',
      ),
      createdAt: _asDateTime(json['createdAt']),
      reviewedAt: _asDateTime(json['reviewedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'poolId': poolId,
      'userName': userName,
      'userEmail': userEmail,
      'userAvatarUrl': userAvatarUrl,
      'status': status.value,
      'createdAt': createdAt?.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
    };
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
