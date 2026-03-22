/// Represents a payment transaction record (maps to PaymentTransactionResponseResource).
class PaymentTransaction {
  final int? id;
  final String? orderId;
  final double? payhereAmount;
  final String? currency;
  final String? status;
  final String? method;
  final DateTime? createdDate;

  PaymentTransaction({
    this.id,
    this.orderId,
    this.payhereAmount,
    this.currency,
    this.status,
    this.method,
    this.createdDate,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as int?,
      orderId: json['orderId'] as String?,
      payhereAmount: (json['payhereAmount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      status: json['status'] as String?,
      method: json['method'] as String?,
      createdDate: json['createdDate'] != null
          ? DateTime.tryParse(json['createdDate'].toString())
          : null,
    );
  }

  /// Whether this transaction succeeded.
  bool get isSuccess => status == 'SUCCESS';

  /// Whether this transaction failed.
  bool get isFailed => status == 'FAILED';

  /// Whether this transaction is still pending.
  bool get isPending => status == 'PENDING';
}

