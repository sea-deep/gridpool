enum PaymentRequestStatus { pending, approved, rejected }

extension PaymentRequestStatusX on PaymentRequestStatus {
  String get value {
    switch (this) {
      case PaymentRequestStatus.pending:
        return 'PENDING';
      case PaymentRequestStatus.approved:
        return 'APPROVED';
      case PaymentRequestStatus.rejected:
        return 'REJECTED';
    }
  }

  static PaymentRequestStatus fromValue(String value) {
    switch (value.toUpperCase()) {
      case 'APPROVED':
        return PaymentRequestStatus.approved;
      case 'REJECTED':
        return PaymentRequestStatus.rejected;
      default:
        return PaymentRequestStatus.pending;
    }
  }
}

class PaymentRequest {
  final String id;
  final String poolId;
  final String userId;
  final String name;
  final double amount;
  final String screenshotUrl;
  final PaymentRequestStatus status;
  final DateTime submittedAt;

  PaymentRequest({
    required this.id,
    required this.poolId,
    required this.userId,
    required this.name,
    required this.amount,
    required this.screenshotUrl,
    required this.status,
    required this.submittedAt,
  });

  factory PaymentRequest.fromJson(String id, Map<String, dynamic> json) {
    return PaymentRequest(
      id: json['id'] ?? json['_id'] ?? id,
      poolId: json['poolId'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      screenshotUrl: json['screenshotUrl'] ?? '',
      status: PaymentRequestStatusX.fromValue(json['status'] ?? 'PENDING'),
      submittedAt: _asDateTime(json['submittedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poolId': poolId,
      'userId': userId,
      'name': name,
      'amount': amount,
      'screenshotUrl': screenshotUrl,
      'status': status.value,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  PaymentRequest copyWith({
    String? id,
    String? poolId,
    String? userId,
    String? name,
    double? amount,
    String? screenshotUrl,
    PaymentRequestStatus? status,
    DateTime? submittedAt,
  }) {
    return PaymentRequest(
      id: id ?? this.id,
      poolId: poolId ?? this.poolId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  static DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) {
      return DateTime.tryParse(v);
    }
    return null;
  }
}
