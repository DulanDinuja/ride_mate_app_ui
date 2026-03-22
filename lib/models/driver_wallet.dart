/// Represents the driver wallet summary (maps to DriverWalletResponseResource).
class DriverWallet {
  final int? walletId;
  final int? driverProfileId;
  final String? driverName;
  final double? availableBalance;
  final double? totalEarnings;
  final double? totalCommission;
  final double? totalWithdrawn;
  final double? totalNetEarnings;
  final String? currency;

  DriverWallet({
    this.walletId,
    this.driverProfileId,
    this.driverName,
    this.availableBalance,
    this.totalEarnings,
    this.totalCommission,
    this.totalWithdrawn,
    this.totalNetEarnings,
    this.currency,
  });

  factory DriverWallet.fromJson(Map<String, dynamic> json) {
    return DriverWallet(
      walletId: json['walletId'] as int?,
      driverProfileId: json['driverProfileId'] as int?,
      driverName: json['driverName'] as String?,
      availableBalance: (json['availableBalance'] as num?)?.toDouble(),
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble(),
      totalCommission: (json['totalCommission'] as num?)?.toDouble(),
      totalWithdrawn: (json['totalWithdrawn'] as num?)?.toDouble(),
      totalNetEarnings: (json['totalNetEarnings'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
    );
  }
}

