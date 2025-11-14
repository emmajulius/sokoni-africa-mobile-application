/// Phone number validation utility for African countries
/// Supports validation for Tanzania, Kenya, Nigeria, and other African countries

class PhoneValidationUtils {
  // Minimum and maximum phone number lengths by country code
  // These are the lengths for the local number (without country code)
  static const Map<String, PhoneNumberRules> _countryRules = {
    '+255': PhoneNumberRules(minLength: 9, maxLength: 9, country: 'Tanzania'), // Tanzania: 9 digits
    '+254': PhoneNumberRules(minLength: 9, maxLength: 9, country: 'Kenya'), // Kenya: 9 digits
    '+234': PhoneNumberRules(minLength: 10, maxLength: 10, country: 'Nigeria'), // Nigeria: 10 digits
    '+212': PhoneNumberRules(minLength: 9, maxLength: 9, country: 'Morocco'), // Morocco: 9 digits
    '+233': PhoneNumberRules(minLength: 9, maxLength: 9, country: 'Ghana'), // Ghana: 9 digits
    '+256': PhoneNumberRules(minLength: 9, maxLength: 9, country: 'Uganda'), // Uganda: 9 digits
    '+250': PhoneNumberRules(minLength: 9, maxLength: 9, country: 'Rwanda'), // Rwanda: 9 digits
    '+27': PhoneNumberRules(minLength: 9, maxLength: 9, country: 'South Africa'), // South Africa: 9 digits
  };

  /// Validates a phone number based on country code
  /// 
  /// [phoneNumber] - The phone number without country code (digits only)
  /// [countryCode] - The country code (e.g., '+255', '+254')
  /// 
  /// Returns null if valid, error message if invalid
  static String? validatePhoneNumber(String? phoneNumber, String countryCode) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return 'Please enter phone number';
    }

    final phone = phoneNumber.trim();

    // Check if phone number contains only digits
    if (!RegExp(r'^\d+$').hasMatch(phone)) {
      return 'Phone number should contain only digits';
    }

    // Get rules for the country code
    final rules = _countryRules[countryCode];
    
    if (rules != null) {
      // Validate length based on country rules
      if (phone.length < rules.minLength) {
        return 'Phone number for ${rules.country} must be at least ${rules.minLength} digits';
      }
      if (phone.length > rules.maxLength) {
        return 'Phone number for ${rules.country} must be at most ${rules.maxLength} digits';
      }
    } else {
      // Default validation for unknown country codes
      // Most African countries use 9-10 digits
      if (phone.length < 7) {
        return 'Phone number is too short';
      }
      if (phone.length > 15) {
        return 'Phone number is too long';
      }
    }

    // Additional validation: Check for common invalid patterns
    if (phone.startsWith('0')) {
      // Remove leading zero if present (some users enter 0 instead of country code)
      final phoneWithoutZero = phone.substring(1);
      final minLength = rules?.minLength ?? 7;
      if (phoneWithoutZero.length < minLength) {
        return 'Please enter phone number without leading zero';
      }
    }

    // Validate that phone doesn't start with country code (common mistake)
    final countryCodeDigits = countryCode.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith(countryCodeDigits)) {
      return 'Please enter phone number without country code';
    }

    return null; // Valid phone number
  }

  /// Validates a phone number with a default minimum length
  /// Used when country code is not provided or unknown
  /// 
  /// [phoneNumber] - The phone number to validate
  /// [minLength] - Minimum length (default: 7)
  /// [maxLength] - Maximum length (default: 15)
  /// 
  /// Returns null if valid, error message if invalid
  static String? validatePhoneNumberGeneric(
    String? phoneNumber, {
    int minLength = 7,
    int maxLength = 15,
  }) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return 'Please enter phone number';
    }

    final phone = phoneNumber.trim();

    // Check if phone number contains only digits
    if (!RegExp(r'^\d+$').hasMatch(phone)) {
      return 'Phone number should contain only digits';
    }

    // Validate length
    if (phone.length < minLength) {
      return 'Phone number must be at least $minLength digits';
    }
    if (phone.length > maxLength) {
      return 'Phone number must be at most $maxLength digits';
    }

    return null; // Valid phone number
  }

  /// Gets the expected phone number format for a country
  /// 
  /// [countryCode] - The country code (e.g., '+255')
  /// 
  /// Returns a formatted string showing the expected format
  static String getPhoneFormat(String countryCode) {
    final rules = _countryRules[countryCode];
    if (rules != null) {
      final exampleDigits = 'X' * rules.minLength;
      return '$countryCode$exampleDigits';
    }
    return '${countryCode}XXXXXXXX';
  }

  /// Gets phone number rules for a country
  /// 
  /// [countryCode] - The country code (e.g., '+255')
  /// 
  /// Returns PhoneNumberRules or null if not found
  static PhoneNumberRules? getRules(String countryCode) {
    return _countryRules[countryCode];
  }

  /// Checks if a country code is supported
  /// 
  /// [countryCode] - The country code to check
  /// 
  /// Returns true if supported, false otherwise
  static bool isSupportedCountryCode(String countryCode) {
    return _countryRules.containsKey(countryCode);
  }
}

/// Phone number validation rules for a country
class PhoneNumberRules {
  final int minLength;
  final int maxLength;
  final String country;

  const PhoneNumberRules({
    required this.minLength,
    required this.maxLength,
    required this.country,
  });
}

