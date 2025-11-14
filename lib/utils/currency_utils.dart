class CurrencyUtils {
  static const Map<String, double> _sokExchangeRates = {
    'TZS': 1000.0, // 1 SOK = 1000 TZS
    'KES': 0.05,   // 1 SOK = 0.05 KES
    'NGN': 0.5,    // 1 SOK = 0.5 NGN
  };

  static double _getExchangeRate(String currency) {
    return _sokExchangeRates[currency.toUpperCase()] ??
        _sokExchangeRates['TZS']!;
  }

  static double localToSok(double localAmount, String currency) {
    final rate = _getExchangeRate(currency);
    if (rate <= 0) {
      return localAmount;
    }
    return localAmount / rate;
  }

  static double sokToLocal(double sokAmount, String currency) {
    final rate = _getExchangeRate(currency);
    return sokAmount * rate;
  }
}

