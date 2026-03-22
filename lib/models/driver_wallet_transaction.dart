/// Represents a single driver wallet transaction
/// (maps to DriverWalletTransactionResponseResource).
class DriverWalletTransaction {
  final int? transactionId;
  final String? transactionType;
  final double? grossAmount;
  final double? commissionPercentage;
  final double? commissionAmount;
  final double? netAmount;
  final double? balanceAfter;
  final String? currency;
  final String? description;
  final int? rideDetailId;
  final String? startCity;
  final int? withdrawalRequestId;
  final DateTime? createdDate;

  DriverWalletTransaction({
    this.transactionId,
    this.transactionType,
    this.grossAmount,
    this.commissionPercentage,
    this.commissionAmount,
    this.netAmount,
    this.balanceAfter,
    this.currency,
    this.description,
    this.rideDetailId,
    this.startCity,
    this.withdrawalRequestId,
    this.createdDate,
  });

  factory DriverWalletTransaction.fromJson(Map<String, dynamic> json) {
    return DriverWalletTransaction(
      transactionId: json['transactionId'] as int?,
      transactionType: json['transactionType'] as String?,
      grossAmount: (json['grossAmount'] as num?)?.toDouble(),
      commissionPercentage: (json['commissionPercentage'] as num?)?.toDouble(),
      commissionAmount: (json['commissionAmount'] as num?)?.toDouble(),
      netAmount: (json['netAmount'] as num?)?.toDouble(),
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      description: json['description'] as String?,
      rideDetailId: json['rideDetailId'] as int?,
      startCity: json['startCity'] as String?,
      withdrawalRequestId: json['withdrawalRequestId'] as int?,
      createdDate: json['createdDate'] != null
          ? DateTime.tryParse(json['createdDate'].toString())
          : null,
    );
  }

  bool get isEarning => transactionType == 'RIDE_EARNING';
  bool get isWithdrawal => transactionType == 'WITHDRAWAL';
  bool get isCommission => transactionType == 'COMMISSION_DEDUCTION';
}

