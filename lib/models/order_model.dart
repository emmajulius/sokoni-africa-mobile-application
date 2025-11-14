import 'cart_item_model.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return DateTime.now();
}

String? _parseNullableString(dynamic value) {
  if (value == null) return null;
  final stringValue = value.toString().trim();
  return stringValue.isEmpty ? null : stringValue;
}

int _parseInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
}

class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double totalAmount;
  final double shippingCost;
  final double tax;
  final double discount;
  final double processingFee;
  final double shippingDistanceKm;
  final bool includesShipping;
  final double productsSubtotal;
  final OrderStatus status;
  final String? shippingAddress;
  final String? paymentMethod;
  final String? paymentStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? customerUsername;
  final String? customerFullName;
  final String? customerProfileImage;
  final String? customerEmail;
  final String? customerPhone;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    this.shippingCost = 0.0,
    this.tax = 0.0,
    this.discount = 0.0,
    this.processingFee = 0.0,
    this.shippingDistanceKm = 0.0,
    this.includesShipping = false,
    this.productsSubtotal = 0.0,
    required this.status,
    this.shippingAddress,
    this.paymentMethod,
    this.paymentStatus,
    required this.createdAt,
    this.updatedAt,
    this.customerUsername,
    this.customerFullName,
    this.customerProfileImage,
    this.customerEmail,
    this.customerPhone,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Convert backend order items to CartItemModel format
    List<CartItemModel> items = [];
    if (json['items'] != null) {
      final itemsList = (json['items'] as List?) ?? [];
      for (var item in itemsList) {
        final itemMap = Map<String, dynamic>.from(item as Map);
        // Backend returns OrderItemResponse with product nested
        if (itemMap['product'] != null) {
          final product = itemMap['product'] as Map<String, dynamic>;
          items.add(CartItemModel.fromJson({
            'id': itemMap['id']?.toString() ?? '',
            'product': product,
            'quantity': _parseInt(itemMap['quantity'], 1),
          }));
        }
      }
    }
    
    return OrderModel(
      id: json['id']?.toString() ?? '',
      userId: json['customer_id']?.toString() ?? json['user_id']?.toString() ?? '',
      items: items,
      totalAmount: _parseDouble(json['total_amount']),
      shippingCost: _parseDouble(json['shipping_cost']),
      tax: _parseDouble(json['tax']),
      discount: _parseDouble(json['discount']),
      processingFee: _parseDouble(json['processing_fee']),
      shippingDistanceKm: _parseDouble(json['shipping_distance_km']),
      includesShipping: json['includes_shipping'] == true,
      productsSubtotal: _parseDouble(json['products_subtotal']),
      status: _parseOrderStatus(json['status']),
      shippingAddress: _parseNullableString(json['shipping_address']),
      paymentMethod: _parseNullableString(json['payment_method']),
      paymentStatus: _parseNullableString(json['payment_status']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: json['updated_at'] != null ? _parseDateTime(json['updated_at']) : null,
      customerUsername: _parseNullableString(json['customer_username']),
      customerFullName: _parseNullableString(json['customer_full_name']),
      customerProfileImage: _parseNullableString(json['customer_profile_image']),
      customerEmail: _parseNullableString(json['customer_email']),
      customerPhone: _parseNullableString(json['customer_phone']),
    );
  }
  
  static OrderStatus _parseOrderStatus(dynamic status) {
    if (status == null) return OrderStatus.pending;
    final statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'total_amount': totalAmount,
      'shipping_cost': shippingCost,
      'tax': tax,
      'discount': discount,
      'processing_fee': processingFee,
      'shipping_distance_km': shippingDistanceKm,
      'includes_shipping': includesShipping,
      'products_subtotal': productsSubtotal,
      'status': status.toString().split('.').last,
      'shipping_address': shippingAddress,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'customer_username': customerUsername,
      'customer_full_name': customerFullName,
      'customer_profile_image': customerProfileImage,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
    };
  }
}

