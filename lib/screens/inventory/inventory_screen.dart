import 'package:flutter/material.dart';
import 'create_product_screen.dart';
import '../../models/product_model.dart';
import '../../widgets/product_card.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../product/product_detail_screen.dart';
import '../profile/addresses_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<ProductModel> _products = [];
  bool _isLoading = true;
  final AuthService _authService = AuthService();
  final LanguageService _languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
    _loadProducts();
  }

  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openAddressManager() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressesScreen(),
      ),
    );
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.initialize();
      final currentUserIdStr = _authService.userId;
      
      if (currentUserIdStr == null) {
        if (mounted) {
          setState(() {
            _products = [];
            _isLoading = false;
          });
        }
        return;
      }
      
      // Convert string ID to int for API call
      final currentUserId = int.tryParse(currentUserIdStr);
      if (currentUserId == null) {
        if (mounted) {
          setState(() {
            _products = [];
            _isLoading = false;
          });
        }
        return;
      }
      
      // Use seller_id filter to fetch only user's products (much faster than fetching all)
      final apiService = ApiService();
      final products = await apiService.getProducts(sellerId: currentUserId);
      
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        final l10n = AppLocalizations.of(context) ?? 
                     AppLocalizations(_languageService.currentLocale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorLoadingProducts}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteProduct(ProductModel product) async {
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          l10n.deleteProduct,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          l10n.areYouSureDeleteProduct(product.title),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final apiService = ApiService();
      final productId = int.tryParse(product.id);
      if (productId == null) {
        throw Exception('Invalid product ID');
      }

      await apiService.deleteProduct(productId);

      if (!mounted) return;

      final l10n = AppLocalizations.of(context) ?? 
                   AppLocalizations(_languageService.currentLocale);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.productDeleted}: "${product.title}"'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      await _loadProducts();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context) ?? 
                   AppLocalizations(_languageService.currentLocale);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.failedToDeleteProduct}: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark 
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        automaticallyImplyLeading: false, // No back button for tab screen
        title: Text(l10n.myInventory),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadProducts,
            tooltip: l10n.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateProductScreen(),
                ),
              );
              if (result != null) {
                // If result is a Map, it's the created product data - add it optimistically
                if (result is Map<String, dynamic>) {
                  try {
                    final newProduct = ProductModel.fromJson(result);
                    if (mounted) {
                      setState(() {
                        // Add new product at the beginning of the list
                        _products.insert(0, newProduct);
                      });
                    }
                  } catch (e) {
                    print('Error adding created product: $e');
                    // Fallback to full refresh
                    _loadProducts();
                  }
                } else if (result == true) {
                  // Fallback: full refresh if no product data
                  _loadProducts();
                }
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProducts,
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  Colors.grey[850]!,
                                  Colors.grey[900]!,
                                ]
                              : [
                                  const Color(0xFFF5F7FA),
                                  const Color(0xFFE8ECF1),
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              size: 32,
                              color: Color(0xFFFF9800),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.myInventory,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: isDark 
                                  ? Colors.white 
                                  : Colors.grey[900],
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.manageYourProducts,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark 
                                  ? Colors.grey[400] 
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Stats
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    Colors.grey[850]!.withOpacity(0.7),
                                    Colors.grey[850]!.withOpacity(0.5),
                                  ]
                                : [
                                    Colors.white,
                                    Colors.grey[50]!,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? Colors.grey[800]!
                                : Colors.grey[200]!,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: _buildStatColumn(
                                context,
                                _products.isEmpty ? '0' : _products.length.toString(),
                                l10n.totalProducts,
                                isDark,
                                const Color(0xFF2196F3),
                              ),
                            ),
                            Expanded(
                              child: _buildStatColumn(
                                context,
                                _products.isEmpty ? '0' : _products.length.toString(),
                                l10n.active,
                                isDark,
                                const Color(0xFF4CAF50),
                              ),
                            ),
                            Expanded(
                              child: _buildStatColumn(
                                context,
                                '0',
                                l10n.pending,
                                isDark,
                                const Color(0xFFFF9800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Products List or Empty State
                  _products.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: isDark 
                                          ? Colors.grey[850]!.withOpacity(0.3)
                                          : Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      size: 64,
                                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    l10n.noProductsYet,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.grey[900],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.createYourFirstProduct,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final product = _products[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ProductCard(
                                    product: product,
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetailScreen(
                                            product: product,
                                          ),
                                        ),
                                      );
                                      
                                      // Reload products if engagement was updated
                                      if (result == true && mounted) {
                                        await _loadProducts();
                                      }
                                    },
                                    showOwnerActions: true,
                                    onEdit: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CreateProductScreen(
                                            productToEdit: product,
                                          ),
                                        ),
                                      );
                                      
                                      // Reload products if product was updated
                                      if (result == true && mounted) {
                                        await _loadProducts();
                                      }
                                    },
                                    onDelete: () => _confirmDeleteProduct(product),
                                    onUpdateAddress: _openAddressManager,
                                  ),
                                );
                              },
                              childCount: _products.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateProductScreen(),
            ),
          );
          if (result != null) {
            // If result is a Map, it's the created product data - add it optimistically
            if (result is Map<String, dynamic>) {
              try {
                final newProduct = ProductModel.fromJson(result);
                if (mounted) {
                  setState(() {
                    // Add new product at the beginning of the list
                    _products.insert(0, newProduct);
                  });
                }
              } catch (e) {
                print('Error adding created product: $e');
                // Fallback to full refresh
                _loadProducts();
              }
            } else if (result == true) {
              // Fallback: full refresh if no product data
              _loadProducts();
            }
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(
          l10n.createProduct,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String value, String label, bool isDark, Color color) {
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _getStatIcon(label, l10n),
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.grey[900],
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
  
  IconData _getStatIcon(String label, AppLocalizations l10n) {
    if (label == l10n.totalProducts) {
      return Icons.inventory_2_rounded;
    } else if (label == l10n.active) {
      return Icons.check_circle_rounded;
    } else {
      return Icons.pending_rounded;
    }
  }
}
