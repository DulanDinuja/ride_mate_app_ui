/// Represents a user's saved payment card (maps to SavedCardResponseResource).
class SavedCard {
  final int? id;
  final String? cardHolderName;
  final String? cardNoMasked;
  final String? cardExpiry;
  final String? paymentMethod;
  final String? isActive;

  SavedCard({
    this.id,
    this.cardHolderName,
    this.cardNoMasked,
    this.cardExpiry,
    this.paymentMethod,
    this.isActive,
  });

  factory SavedCard.fromJson(Map<String, dynamic> json) {
    return SavedCard(
      id: json['id'] as int?,
      cardHolderName: json['cardHolderName'] as String?,
      cardNoMasked: json['cardNoMasked'] as String?,
      cardExpiry: json['cardExpiry'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      isActive: json['isActive'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cardHolderName': cardHolderName,
        'cardNoMasked': cardNoMasked,
        'cardExpiry': cardExpiry,
        'paymentMethod': paymentMethod,
        'isActive': isActive,
      };

  /// Whether this card is currently active.
  bool get active => isActive == 'YES';

  /// Display-friendly card brand icon name.
  String get brandIcon {
    switch (paymentMethod?.toUpperCase()) {
      case 'VISA':
        return 'visa';
      case 'MASTER':
        return 'mastercard';
      case 'AMEX':
        return 'amex';
      default:
        return 'card';
    }
  }
}

