import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String poolId;
  final String title;
  final double amount;
  final String category;
  final String createdBy;
  final String? paidByMemberId;
  final DateTime? createdAt;
  final String? note;
  final String? receiptUrl;

  const Expense({
    required this.id,
    required this.poolId,
    required this.title,
    required this.amount,
    required this.category,
    required this.createdBy,
    this.paidByMemberId,
    this.createdAt,
    this.note,
    this.receiptUrl,
  });

  factory Expense.fromJson(String id, Map<String, dynamic> json) {
    return Expense(
      id: id,
      poolId: json['poolId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'Other',
      createdBy: json['createdBy'] as String? ?? '',
      paidByMemberId: json['paidByMemberId'] as String?,
      createdAt: _asDateTime(json['createdAt']),
      note: json['note'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'poolId': poolId,
      'title': title,
      'amount': amount,
      'category': category,
      'createdBy': createdBy,
      'paidByMemberId': paidByMemberId,
      'createdAt': createdAt?.toIso8601String(),
      'note': note,
      'receiptUrl': receiptUrl,
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
