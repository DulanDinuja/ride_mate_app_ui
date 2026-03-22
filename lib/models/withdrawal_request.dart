/// Represents a driver withdrawal request (maps to WithdrawalRequest entity).
class WithdrawalRequest {
  final int? id;
  final int? driverProfileId;
  final double? amount;
  final String? currency;
  final String? bankName;
  final String? accountNumber;
  final String? accountHolderName;
  final String? status;
  final String? remarks;
  final DateTime? createdDate;

  WithdrawalRequest({
    this.id,
    this.driverProfileId,
    this.amount,
    this.currency,
    this.bankName,
    this.accountNumber,
    this.accountHolderName,
    this.status,
    this.remarks,
    this.createdDate,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    // The backend returns the entity directly with nested driverProfile
    final driverProfile = json['driverProfile'];
    return WithdrawalRequest(
      id: json['id'] as int?,
      driverProfileId: driverProfile is Map
          ? driverProfile['id'] as int?
          : json['driverProfileId'] as int?,
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      accountHolderName: json['accountHolderName'] as String?,
      status: json['status'] as String?,
      remarks: json['remarks'] as String?,
      createdDate: json['createdDate'] != null
          ? DateTime.tryParse(json['createdDate'].toString())
          : null,
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
}

