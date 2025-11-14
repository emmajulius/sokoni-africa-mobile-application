// Helper function to parse datetime strings and ensure UTC is preserved
DateTime _parseDateTime(String dateString) {
  try {
    // Try parsing as-is first
    final date = DateTime.parse(dateString);
    // If the string doesn't have timezone info, assume it's UTC
    if (!dateString.endsWith('Z') && !dateString.contains('+') && !dateString.contains('-', dateString.indexOf('T') + 1)) {
      return date.toUtc();
    }
    return date;
  } catch (e) {
    // Fallback: try parsing and converting to UTC
    return DateTime.parse(dateString).toUtc();
  }
}

class WalletModel {
  final int id;
  final int userId;
  final double sokocoinBalance;
  final double totalEarned;
  final double totalSpent;
  final double totalTopup;
  final double totalCashout;
  final DateTime createdAt;
  final DateTime? updatedAt;

  WalletModel({
    required this.id,
    required this.userId,
    required this.sokocoinBalance,
    required this.totalEarned,
    required this.totalSpent,
    required this.totalTopup,
    required this.totalCashout,
    required this.createdAt,
    this.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      sokocoinBalance: (json['sokocoin_balance'] as num).toDouble(),
      totalEarned: (json['total_earned'] as num).toDouble(),
      totalSpent: (json['total_spent'] as num).toDouble(),
      totalTopup: (json['total_topup'] as num).toDouble(),
      totalCashout: (json['total_cashout'] as num).toDouble(),
      createdAt: _parseDateTime(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? _parseDateTime(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'sokocoin_balance': sokocoinBalance,
      'total_earned': totalEarned,
      'total_spent': totalSpent,
      'total_topup': totalTopup,
      'total_cashout': totalCashout,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

enum WalletTransactionType {
  topup,
  cashout,
  purchase,
  earn,
  refund,
  fee;

  static WalletTransactionType fromString(String value) {
    return WalletTransactionType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => WalletTransactionType.topup,
    );
  }
}

enum WalletTransactionStatus {
  pending,
  completed,
  failed,
  cancelled;

  static WalletTransactionStatus fromString(String value) {
    return WalletTransactionStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => WalletTransactionStatus.pending,
    );
  }
}

class WalletTransactionModel {
  final int id;
  final int walletId;
  final int userId;
  final WalletTransactionType transactionType;
  final WalletTransactionStatus status;
  final double sokocoinAmount;
  final double? localCurrencyAmount;
  final String? localCurrencyCode;
  final double? exchangeRate;
  final String? paymentGateway;
  final String? paymentReference;
  final String? gatewayTransactionId;
  final String? payoutMethod;
  final String? payoutAccount;
  final String? payoutReference;
  final String? description;
  final Map<String, dynamic>? extraData;
  final DateTime createdAt;
  final DateTime? completedAt;

  WalletTransactionModel({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.transactionType,
    required this.status,
    required this.sokocoinAmount,
    this.localCurrencyAmount,
    this.localCurrencyCode,
    this.exchangeRate,
    this.paymentGateway,
    this.paymentReference,
    this.gatewayTransactionId,
    this.payoutMethod,
    this.payoutAccount,
    this.payoutReference,
    this.description,
    this.extraData,
    required this.createdAt,
    this.completedAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as int,
      walletId: json['wallet_id'] as int,
      userId: json['user_id'] as int,
      transactionType: WalletTransactionType.fromString(
        json['transaction_type'] as String,
      ),
      status: WalletTransactionStatus.fromString(
        json['status'] as String,
      ),
      sokocoinAmount: (json['sokocoin_amount'] as num).toDouble(),
      localCurrencyAmount: json['local_currency_amount'] != null
          ? (json['local_currency_amount'] as num).toDouble()
          : null,
      localCurrencyCode: json['local_currency_code'] as String?,
      exchangeRate: json['exchange_rate'] != null
          ? (json['exchange_rate'] as num).toDouble()
          : null,
      paymentGateway: json['payment_gateway'] as String?,
      paymentReference: json['payment_reference'] as String?,
      gatewayTransactionId: json['gateway_transaction_id'] as String?,
      payoutMethod: json['payout_method'] as String?,
      payoutAccount: json['payout_account'] as String?,
      payoutReference: json['payout_reference'] as String?,
      description: json['description'] as String?,
      extraData: json['extra_data'] as Map<String, dynamic>?,
      createdAt: _parseDateTime(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? _parseDateTime(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'user_id': userId,
      'transaction_type': transactionType.name,
      'status': status.name,
      'sokocoin_amount': sokocoinAmount,
      'local_currency_amount': localCurrencyAmount,
      'local_currency_code': localCurrencyCode,
      'exchange_rate': exchangeRate,
      'payment_gateway': paymentGateway,
      'payment_reference': paymentReference,
      'gateway_transaction_id': gatewayTransactionId,
      'payout_method': payoutMethod,
      'payout_account': payoutAccount,
      'payout_reference': payoutReference,
      'description': description,
      'extra_data': extraData,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}

