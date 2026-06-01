import 'package:cloud_firestore/cloud_firestore.dart';

enum PoolRole { owner, admin, member }

extension PoolRoleX on PoolRole {
  String get value {
    switch (this) {
      case PoolRole.owner:
        return 'owner';
      case PoolRole.admin:
        return 'admin';
      case PoolRole.member:
        return 'member';
    }
  }

  static PoolRole fromValue(String value) {
    switch (value) {
      case 'owner':
        return PoolRole.owner;
      case 'admin':
        return PoolRole.admin;
      default:
        return PoolRole.member;
    }
  }
}

class PoolMember {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final PoolRole role;
  final bool isCustom;
  final DateTime? joinedAt;
  final double dueAmount;
  final DateTime? lastDueAppliedAt;

  const PoolMember({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.role,
    this.isCustom = false,
    this.joinedAt,
    this.dueAmount = 0.0,
    this.lastDueAppliedAt,
  });

  factory PoolMember.fromJson(String id, Map<String, dynamic> json) {
    return PoolMember(
      id: id,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      role: PoolRoleX.fromValue(json['role'] as String? ?? 'member'),
      isCustom: json['isCustom'] as bool? ?? false,
      joinedAt: _asDateTime(json['joinedAt']),
      dueAmount: (json['dueAmount'] as num?)?.toDouble() ?? 0.0,
      lastDueAppliedAt: _asDateTime(json['lastDueAppliedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role.value,
      'isCustom': isCustom,
      'joinedAt': joinedAt?.toIso8601String(),
      'dueAmount': dueAmount,
      'lastDueAppliedAt': lastDueAppliedAt?.toIso8601String(),
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
