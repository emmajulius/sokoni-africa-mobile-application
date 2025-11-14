import 'dart:math' as math;
import 'constants.dart';

class Helpers {
  static String formatCurrency(double amount, {int decimals = 2}) {
    final clampedDecimals = decimals.clamp(0, 6);
    final sign = amount < 0 ? '-' : '';
    final absAmount = amount.abs();
    final fixed = absAmount.toStringAsFixed(clampedDecimals);
    final parts = fixed.split('.');
    final integer = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    final decimalPart =
        clampedDecimals > 0 && parts.length > 1 ? '.${parts[1]}' : '';
    return '$sign${AppConstants.currencySymbol} $integer$decimalPart';
  }

  static String formatDate(DateTime date) {
    // Convert UTC time to local time for display
    final localDate = date.isUtc ? date.toLocal() : date;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${localDate.day} ${months[localDate.month - 1]}, ${localDate.year}';
  }

  static String formatDateTime(DateTime date) {
    // Convert UTC time to local time for display
    final localDate = date.isUtc ? date.toLocal() : date;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    return '${localDate.day} ${months[localDate.month - 1]}, ${localDate.year} • $hour:$minute';
  }

  static String formatRelativeTime(DateTime date) {
    // Convert UTC time to local time for comparison
    final localDate = date.isUtc ? date.toLocal() : date;
    final now = DateTime.now();
    final difference = now.difference(localDate);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final double c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }
  
  static double _toRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }
  
  /// Format distance for display
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toStringAsFixed(0)}m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceInKm.toStringAsFixed(0)}km';
    }
  }
  
  /// Parse location string (format: "lat,lng" or "lat, lng")
  static Map<String, double>? parseLocation(String? locationString) {
    if (locationString == null || locationString.isEmpty) {
      return null;
    }
    
    try {
      final parts = locationString.split(',');
      if (parts.length != 2) {
        return null;
      }
      
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      
      if (lat == null || lng == null) {
        return null;
      }
      
      return {'lat': lat, 'lng': lng};
    } catch (e) {
      return null;
    }
  }
}

