import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/product_card.dart';
import '../product/product_detail_screen.dart';
import 'addresses_screen.dart';

class SoldProductsScreen extends StatefulWidget {
  final int sellerId;

  const SoldProductsScreen({
    super.key,
    required this.sellerId,
  });

  @override
  State<SoldProductsScreen> createState() => _SoldProductsScreenState();
}

class _SoldProductsScreenState extends State<SoldProductsScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  List<ProductModel> _soldProducts = [];
  bool _isLoading = true;
  bool _hasChanges = false;

  Future<void> _openAddressManager() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressesScreen(),
      ),
    );
    await _loadSoldProducts();
  }

  @override
  void initState() {
    super.initState();
    _loadSoldProducts();
  }

  Future<void> _loadSoldProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.initialize();
      final products = await _apiService.getProducts(
        sellerId: widget.sellerId,
        onlySold: true,
      );

      if (!mounted) return;

      setState(() {
        _soldProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load sold products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDeleteProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final productId = int.tryParse(product.id);
      if (productId == null) {
        throw Exception('Invalid product ID');
      }

      await _apiService.deleteProduct(productId);

      if (!mounted) return;

      setState(() {
        _soldProducts.removeWhere((item) => item.id == product.id);
        _hasChanges = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${product.title}"'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleBack() {
    Navigator.of(context).pop(_hasChanges);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _handleBack();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sold Products'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSoldProducts,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadSoldProducts,
                child: _soldProducts.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: const [
                          SizedBox(height: 80),
                          Icon(
                            Icons.inventory_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No products found.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Once you sell products, they will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        itemCount: _soldProducts.length,
                        itemBuilder: (context, index) {
                          final product = _soldProducts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ProductCard(
                              product: product,
                              showOwnerActions: true,
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(
                                      product: product,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  await _loadSoldProducts();
                                  if (mounted) {
                                    setState(() {
                                      _hasChanges = true;
                                    });
                                  }
                                }
                              },
                              onDelete: () => _confirmDeleteProduct(product),
                              onUpdateAddress: _openAddressManager,
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}

