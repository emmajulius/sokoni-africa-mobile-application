import 'product_model.dart';

class CartItemModel {
  final String id;
  final ProductModel product;
  final int quantity;
  final Map<String, String>? selectedAttributes; // e.g., {'color': 'purple', 'size': '256GB'}

  CartItemModel({
    required this.id,
    required this.product,
    required this.quantity,
    this.selectedAttributes,
  });

  double get totalPrice => product.price * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id']?.toString() ?? '',
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] ?? 1,
      selectedAttributes: json['selected_attributes'] != null
          ? Map<String, String>.from(json['selected_attributes'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'selected_attributes': selectedAttributes,
    };
  }
}

