import 'package:cloud_firestore/cloud_firestore.dart';

enum LedgerEntryType {
  contributionCreated,
  contributionPaid,
  expenseAdded,
  manualAdjustment,
  paymentMarkedOffline,
  payment,
}

extension LedgerEntryTypeX on LedgerEntryType {
  String get value {
    switch (this) {
      case LedgerEntryType.contributionCreated:
        return 'contribution_created';
      case LedgerEntryType.contributionPaid:
        return 'contribution_paid';
      case LedgerEntryType.expenseAdded:
        return 'expense_added';
      case LedgerEntryType.manualAdjustment:
        return 'manual_adjustment';
      case LedgerEntryType.paymentMarkedOffline:
        return 'payment_marked_offline';
      case LedgerEntryType.payment:
        return 'payment';
    }
  }

  static LedgerEntryType fromValue(String value) {
    switch (value) {
      case 'contribution_paid':
        return LedgerEntryType.contributionPaid;
      case 'expense_added':
        return LedgerEntryType.expenseAdded;
      case 'manual_adjustment':
        return LedgerEntryType.manualAdjustment;
      case 'payment_marked_offline':
        return LedgerEntryType.paymentMarkedOffline;
      case 'payment':
        return LedgerEntryType.payment;
      default:
        return LedgerEntryType.contributionCreated;
    }
  }
}

enum PaymentMethod { upi, cash, transfer, offline, other }

extension PaymentMethodX on PaymentMethod {
  String get value {
    switch (this) {
      case PaymentMethod.upi:
        return 'upi';
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.transfer:
        return 'transfer';
      case PaymentMethod.offline:
        return 'offline';
      case PaymentMethod.other:
        return 'other';
    }
  }

  static PaymentMethod fromValue(String value) {
    switch (value) {
      case 'upi':
        return PaymentMethod.upi;
      case 'cash':
        return PaymentMethod.cash;
      case 'transfer':
        return PaymentMethod.transfer;
      case 'offline':
        return PaymentMethod.offline;
      default:
        return PaymentMethod.other;
    }
  }
}

class LedgerEntry {
  final String id;
  final String poolId;
  final LedgerEntryType type;
  final double amount;
  final DateTime? timestamp;
  final String createdBy;
  final String? memberId;
  final String? description;
  final PaymentMethod? paymentMethod;
  final String? relatedContributionId;
  final String? relatedExpenseId;

  const LedgerEntry({
    required this.id,
    required this.poolId,
    required this.type,
    required this.amount,
    required this.createdBy,
    this.timestamp,
    this.memberId,
    this.description,
    this.paymentMethod,
    this.relatedContributionId,
    this.relatedExpenseId,
  });

  factory LedgerEntry.fromJson(String id, Map<String, dynamic> json) {
    return LedgerEntry(
      id: id,
      poolId: json['poolId'] as String? ?? '',
      type: LedgerEntryTypeX.fromValue(json['type'] as String? ?? ''),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      timestamp: _asDateTime(json['timestamp']),
      createdBy: json['createdBy'] as String? ?? '',
      memberId: json['memberId'] as String?,
      description: json['description'] as String?,
      paymentMethod: json['paymentMethod'] == null
          ? null
          : PaymentMethodX.fromValue(json['paymentMethod'] as String),
      relatedContributionId: json['relatedContributionId'] as String?,
      relatedExpenseId: json['relatedExpenseId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'poolId': poolId,
      'type': type.value,
      'amount': amount,
      'timestamp': timestamp?.toIso8601String(),
      'createdBy': createdBy,
      'memberId': memberId,
      'description': description,
      'paymentMethod': paymentMethod?.value,
      'relatedContributionId': relatedContributionId,
      'relatedExpenseId': relatedExpenseId,
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
