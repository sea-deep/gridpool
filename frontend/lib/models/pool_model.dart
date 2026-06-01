import 'package:cloud_firestore/cloud_firestore.dart';

class Pool {
  final String id;
  final String name;
  final String description;
  final String currency;
  final String inviteCode;
  final String? upiId;
  final String createdBy;
  final DateTime? createdAt;
  final int memberCount;
  final List<String> memberIds;
  final double totalCollected;
  final double totalSpent;
  final double currentBalance;
  final double pendingAmount;
  final String frequency;
  final int? customInterval;
  final double expectedContribution;

  const Pool({
    required this.id,
    required this.name,
    required this.description,
    required this.currency,
    required this.inviteCode,
    required this.createdBy,
    required this.memberCount,
    required this.memberIds,
    required this.totalCollected,
    required this.totalSpent,
    required this.currentBalance,
    required this.pendingAmount,
    required this.frequency,
    this.customInterval,
    this.expectedContribution = 0.0,
    this.createdAt,
    this.upiId,
  });

  factory Pool.fromJson(String id, Map<String, dynamic> json) {
    return Pool(
      id: id,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      currency: json['currency'] as String? ?? 'INR',
      inviteCode: json['inviteCode'] as String? ?? '',
      upiId: json['upiId'] as String?,
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: _asDateTime(json['createdAt']),
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      memberIds: List<String>.from(json['memberIds'] as List? ?? const []),
      totalCollected: (json['totalCollected'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0.0,
      pendingAmount: (json['pendingAmount'] as num?)?.toDouble() ?? 0.0,
      frequency: json['frequency'] as String? ?? 'once',
      customInterval: json['customInterval'] != null ? int.tryParse(json['customInterval'].toString()) : null,
      expectedContribution: (json['expectedContribution'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'currency': currency,
      'inviteCode': inviteCode,
      'upiId': upiId,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'memberCount': memberCount,
      'memberIds': memberIds,
      'totalCollected': totalCollected,
      'totalSpent': totalSpent,
      'currentBalance': currentBalance,
      'pendingAmount': pendingAmount,
      'frequency': frequency,
      'customInterval': customInterval,
      'expectedContribution': expectedContribution,
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
