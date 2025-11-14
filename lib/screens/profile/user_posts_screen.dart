import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../widgets/product_card.dart';
import '../product/product_detail_screen.dart';

class UserPostsScreen extends StatefulWidget {
  final int userId;
  final String username;

  const UserPostsScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<UserPostsScreen> createState() => _UserPostsScreenState();
}

class _UserPostsScreenState extends State<UserPostsScreen> {
  final ApiService _apiService = ApiService();
  List<ProductModel> _products = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMore) {
        _loadMoreProducts();
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _apiService.getProducts(
        page: 1,
        limit: 20,
        sellerId: widget.userId,
      );

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
          _hasMore = products.length >= 20;
          _currentPage = 1;
        });
      }
    } catch (e) {
      print('Error loading products: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading posts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final products = await _apiService.getProducts(
        page: nextPage,
        limit: 20,
        sellerId: widget.userId,
      );

      if (mounted) {
        setState(() {
          if (products.isEmpty) {
            _hasMore = false;
          } else {
            _products.addAll(products);
            _currentPage = nextPage;
            _hasMore = products.length >= 20;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading more products: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.username}\'s Posts'),
      ),
      body: _isLoading && _products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.grid_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No posts yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _products.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _products.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final product = _products[index];
                      return ProductCard(
                        product: product,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(product: product),
                            ),
                          );
                          if (result == true && mounted) {
                            // Reload products if engagement was updated
                            await _loadProducts();
                          }
                        },
                        onLikeChanged: (isLiked) {
                          // Update local product state if needed
                          setState(() {
                            // Product card handles its own state
                          });
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

