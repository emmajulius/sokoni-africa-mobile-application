import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/product_model.dart';

class CreateProductScreen extends StatefulWidget {
  final ProductModel? productToEdit;
  
  const CreateProductScreen({
    super.key,
    this.productToEdit,
  });

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _startingPriceController = TextEditingController();
  final _bidIncrementController = TextEditingController();
  final _auctionDurationController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  String? _selectedCategory;
  String? _selectedUnitType;
  String _productType = 'product'; // 'product' or 'live_auction'
  bool _isWingaEnabled = false;
  bool _hasWarranty = false;
  bool _isPrivate = false;
  bool _isAdultContent = false;
  final List<XFile> _selectedImages = []; // Use XFile for both web and mobile
  final List<String> _existingImageUrls = []; // Existing images from product being edited
  bool _isLoading = false;
  String _selectedCurrency = 'TZS';
  final List<String> _supportedCurrencies = const ['TZS', 'KES', 'NGN'];
  bool get _isEditMode => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode && widget.productToEdit != null) {
      _loadProductData(widget.productToEdit!);
    }
  }

  void _loadProductData(ProductModel product) {
    _titleController.text = product.title;
    _descriptionController.text = product.description;
    _selectedCategory = product.category;
    _selectedUnitType = product.unitType;
    _isWingaEnabled = product.isWingaEnabled;
    _hasWarranty = product.hasWarranty;
    _isPrivate = product.isPrivate;
    _isAdultContent = product.isAdultContent;
    
    // Load price - use price field (in Sokocoin, will be converted back to local currency)
    // For editing, we'll use the price as-is and let the user adjust if needed
    _priceController.text = product.price.toString();
    
    // Default currency (can be changed by user)
    _selectedCurrency = 'TZS';
    
    // Load existing images
    if (product.images.isNotEmpty) {
      _existingImageUrls.addAll(product.images);
    } else if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      _existingImageUrls.add(product.imageUrl!);
    }
    
    // Load auction data if applicable
    if (product.isAuction) {
      _productType = 'live_auction';
      if (product.startingPrice != null) {
        _startingPriceController.text = product.startingPrice.toString();
      }
      if (product.bidIncrement != null) {
        _bidIncrementController.text = product.bidIncrement.toString();
      }
      if (product.auctionDurationMinutes != null) {
        _auctionDurationController.text = product.auctionDurationMinutes.toString();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _startingPriceController.dispose();
    _bidIncrementController.dispose();
    _auctionDurationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromSource(ImageSource.camera);
                },
              ),
              if (_selectedImages.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove All Images', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImages.clear();
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    final totalImages = _existingImageUrls.length + _selectedImages.length;
    if (totalImages >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 images allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }
  
  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  Future<void> _handleContinue() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a category'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check if user is authenticated
      final authService = AuthService();
      await authService.initialize(); // Ensure auth state is loaded
      if (!authService.isAuthenticated || authService.authToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to create products'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if user can sell
      if (!authService.canSell) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only suppliers and retailers can create products'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final apiService = ApiService();
        final isAuction = _productType == 'live_auction';
        
        // Validate price for regular products
        if (!isAuction) {
          if (_priceController.text.isEmpty) {
            throw Exception('Price is required for regular products');
          }
        }
        
        final price = isAuction ? null : double.parse(_priceController.text);
        
        // Upload images first if any are selected
        List<String> imageUrls = [];
        if (_selectedImages.isNotEmpty) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isEditMode ? 'Uploading new images...' : 'Uploading images...'),
                duration: const Duration(seconds: 2),
              ),
            );
            
            imageUrls = await apiService.uploadImages(_selectedImages);
            
            // Only require images for regular products, not auctions
            if (imageUrls.isEmpty && !_isEditMode && !isAuction) {
              throw Exception('No images were uploaded successfully. At least one image is required for regular products.');
            }
          } catch (e) {
            // If upload fails, show error but don't block product creation/update
            print('Warning: Image upload failed: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image upload failed: ${e.toString()}. ${_isEditMode ? 'Product will be updated with existing images.' : 'Product will be created without images.'}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
            imageUrls = [];
          }
        }
        
        // Merge existing images with new images when editing
        List<String> finalImages = [];
        if (_isEditMode) {
          // Keep existing images
          finalImages.addAll(_existingImageUrls);
          // Add new uploaded images
          finalImages.addAll(imageUrls);
        } else {
          // For new products, use only new images
          finalImages = imageUrls;
        }
        
        // Declare product data variable for return value (used when creating new products)
        Map<String, dynamic>? createdProductData;
        
        if (_isEditMode) {
          // Update existing product
          final productId = int.tryParse(widget.productToEdit!.id);
          if (productId == null) {
            throw Exception('Invalid product ID');
          }
          
          if (isAuction) {
            // Validate auction fields
            if (_startingPriceController.text.isEmpty) {
              throw Exception('Starting price is required for auctions');
            }
            if (_bidIncrementController.text.isEmpty) {
              throw Exception('Bid increment is required for auctions');
            }
            if (_auctionDurationController.text.isEmpty) {
              throw Exception('Auction duration is required for auctions');
            }
            
            final startingPrice = double.parse(_startingPriceController.text);
            final bidIncrement = double.parse(_bidIncrementController.text);
            final auctionDurationMinutes = int.parse(_auctionDurationController.text);
            
            if (startingPrice <= 0) {
              throw Exception('Starting price must be greater than 0');
            }
            if (bidIncrement <= 0) {
              throw Exception('Bid increment must be greater than 0');
            }
            // Require at least 60 minutes (1 hour) to ensure whole hours
            if (auctionDurationMinutes < 60) {
              throw Exception('Auction duration must be at least 60 minutes (1 hour)');
            }
            if (auctionDurationMinutes > 43200) {
              throw Exception('Auction duration cannot exceed 43200 minutes (720 hours)');
            }
            
            await apiService.updateProduct(
              productId: productId,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              category: _selectedCategory!,
              unitType: _selectedUnitType,
              isWingaEnabled: _isWingaEnabled,
              hasWarranty: _hasWarranty,
              isPrivate: _isPrivate,
              isAdultContent: _isAdultContent,
              images: finalImages.isNotEmpty ? finalImages : null,
              imageUrl: finalImages.isNotEmpty ? finalImages[0] : null,
              startingPrice: startingPrice,
              bidIncrement: bidIncrement,
              auctionDurationMinutes: auctionDurationMinutes,
            );
          } else {
            // Regular product update
            await apiService.updateProduct(
              productId: productId,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              price: price,
              currency: _selectedCurrency,
              category: _selectedCategory!,
              unitType: _selectedUnitType,
              isWingaEnabled: _isWingaEnabled,
              hasWarranty: _hasWarranty,
              isPrivate: _isPrivate,
              isAdultContent: _isAdultContent,
              images: finalImages.isNotEmpty ? finalImages : null,
              imageUrl: finalImages.isNotEmpty ? finalImages[0] : null,
            );
          }
        } else {
          // Create new product - store result for optimistic update
          if (isAuction) {
            // Validate auction fields
            if (_startingPriceController.text.isEmpty) {
              throw Exception('Starting price is required for auctions');
            }
            if (_bidIncrementController.text.isEmpty) {
              throw Exception('Bid increment is required for auctions');
            }
            if (_auctionDurationController.text.isEmpty) {
              throw Exception('Auction duration is required for auctions');
            }
            
            final startingPrice = double.parse(_startingPriceController.text);
            final bidIncrement = double.parse(_bidIncrementController.text);
            final auctionDurationMinutes = int.parse(_auctionDurationController.text);
            
            if (startingPrice <= 0) {
              throw Exception('Starting price must be greater than 0');
            }
            if (bidIncrement <= 0) {
              throw Exception('Bid increment must be greater than 0');
            }
            // Require at least 60 minutes (1 hour) to ensure whole hours
            if (auctionDurationMinutes < 60) {
              throw Exception('Auction duration must be at least 60 minutes (1 hour)');
            }
            if (auctionDurationMinutes > 43200) {
              throw Exception('Auction duration cannot exceed 43200 minutes (720 hours)');
            }
            
            final result = await apiService.createProduct(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              category: _selectedCategory!,
              unitType: _selectedUnitType,
              isWingaEnabled: _isWingaEnabled,
              hasWarranty: _hasWarranty,
              isPrivate: _isPrivate,
              isAdultContent: _isAdultContent,
              images: imageUrls,
              imageUrl: imageUrls.isNotEmpty ? imageUrls[0] : null,
              isAuction: true,
              startingPrice: startingPrice,
              bidIncrement: bidIncrement,
              auctionDurationMinutes: auctionDurationMinutes,
            );
            createdProductData = result['product'] as Map<String, dynamic>?;
          } else {
            // Regular product
            final result = await apiService.createProduct(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              price: price,
              currency: _selectedCurrency,
              category: _selectedCategory!,
              unitType: _selectedUnitType,
              isWingaEnabled: _isWingaEnabled,
              hasWarranty: _hasWarranty,
              isPrivate: _isPrivate,
              isAdultContent: _isAdultContent,
              images: imageUrls,
              imageUrl: imageUrls.isNotEmpty ? imageUrls[0] : null,
              isAuction: false,
            );
            createdProductData = result['product'] as Map<String, dynamic>?;
          }
        }

        // Product created/updated successfully
        if (mounted) {
          setState(() => _isLoading = false);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditMode 
                  ? 'Product updated successfully!' 
                  : 'Product created successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate back with product data for optimistic update
          Navigator.pop(context, createdProductData ?? true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditMode 
                  ? 'Failed to update product: ${e.toString()}'
                  : 'Failed to create product: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          _isEditMode ? 'Edit Product' : 'Create Product',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.grey[900],
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.grey[900],
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.grey[850]!, Colors.grey[900]!]
                        : [Colors.white, Colors.grey[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (_productType == 'live_auction' 
                                ? Colors.orange 
                                : Colors.blue).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _productType == 'live_auction' 
                                ? Icons.gavel 
                                : Icons.shopping_bag,
                            color: _productType == 'live_auction' 
                                ? Colors.orange[700] 
                                : Colors.blue[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isEditMode ? 'Edit Product' : 'Create New Product',
                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.grey[900],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _productType == 'live_auction' 
                                    ? 'Set up your live auction' 
                                    : 'Add product details',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Product Type Selection - Modern Cards
                    Text(
                      'Select Product Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernTypeOption(
                            'Product', 
                            'product', 
                            Icons.shopping_bag_rounded,
                            Colors.blue,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildModernTypeOption(
                            'Live Auction', 
                            'live_auction', 
                            Icons.gavel_rounded,
                            Colors.orange,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Image Upload Section - Modern Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.photo_library_rounded,
                          size: 20,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Product Images',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add up to 10 images. First image will be the main product image.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // Image Grid - Show both existing and new images
              Builder(
                builder: (context) {
                  final totalImages = _existingImageUrls.length + _selectedImages.length;
                  final canAddMore = totalImages < 10;
                  
                  if (totalImages == 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: InkWell(
                      onTap: _pickImage,
                        borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.grey[100],
                            border: Border.all(
                              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.grey[800]! : Colors.white).withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 48,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tap to Add Photos',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Up to 10 images',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: totalImages + (canAddMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Existing images first
                      if (index < _existingImageUrls.length) {
                        final imageUrl = _existingImageUrls[index];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (index == 0 && _selectedImages.isEmpty)
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Main',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeExistingImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            if (_isEditMode)
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Existing',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }
                      
                      // New images
                      final newImageIndex = index - _existingImageUrls.length;
                      if (newImageIndex < _selectedImages.length) {
                        final imageFile = _selectedImages[newImageIndex];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FutureBuilder<Uint8List>(
                                future: imageFile.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    );
                                  }
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (index == 0 && _existingImageUrls.isEmpty)
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Main',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(newImageIndex),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'New',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      
                      // Add more button
                      return InkWell(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, size: 32, color: Colors.grey),
                              SizedBox(height: 4),
                              Text(
                                'Add',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Product Details Section - Modern Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.description_rounded,
                          size: 20,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Product Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                      decoration: InputDecoration(
                        labelText: 'Product Title',
                        hintText: 'Enter a clear and descriptive title',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey[850] : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        hintText: 'Select a category',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey[850] : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'electronics', child: Text('Electronics')),
                        DropdownMenuItem(value: 'fashion', child: Text('Fashion')),
                        DropdownMenuItem(value: 'food', child: Text('Food')),
                        DropdownMenuItem(value: 'beauty', child: Text('Beauty')),
                        DropdownMenuItem(value: 'home_kitchen', child: Text('Home/Kitchen')),
                        DropdownMenuItem(value: 'sports', child: Text('Sports')),
                        DropdownMenuItem(value: 'automotives', child: Text('Automotives')),
                        DropdownMenuItem(value: 'books', child: Text('Books')),
                        DropdownMenuItem(value: 'kids', child: Text('Kids')),
                        DropdownMenuItem(value: 'agriculture', child: Text('Agriculture')),
                        DropdownMenuItem(value: 'art_craft', child: Text('Art/Craft')),
                        DropdownMenuItem(value: 'computer_software', child: Text('Computer/Software')),
                        DropdownMenuItem(value: 'health_wellness', child: Text('Health/Wellness')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedUnitType,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                      decoration: InputDecoration(
                        labelText: 'Unit Type',
                        hintText: 'Select unit type',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey[850] : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'piece', child: Text('Piece')),
                        DropdownMenuItem(value: 'kg', child: Text('Kilogram')),
                        DropdownMenuItem(value: 'liter', child: Text('Liter')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedUnitType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Show regular product price fields or auction fields based on product type
                    if (_productType == 'product') ...[
                      // Price Section Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.attach_money_rounded,
                                    color: Colors.blue[700],
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Pricing',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.grey[900],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.grey[900],
                              ),
                              decoration: InputDecoration(
                                labelText: 'Price (Local Currency)',
                                hintText: 'Enter the price in your local currency',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              validator: (value) {
                                if (_productType == 'product' && (value == null || value.isEmpty)) {
                                  return 'Please enter price';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedCurrency,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.grey[900],
                              ),
                              decoration: InputDecoration(
                                labelText: 'Local Currency',
                                filled: true,
                                fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              items: _supportedCurrencies
                                  .map(
                                    (code) => DropdownMenuItem(
                                      value: code,
                                      child: Text(code),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedCurrency = value;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'All prices are displayed to customers in SOK. We will convert $_selectedCurrency to SOK automatically.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_productType == 'live_auction') ...[
                      // Auction Section Card - Modern Design
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange[50]!,
                              Colors.orange[100]!.withOpacity(0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange[300]!,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[700],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.gavel_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Live Auction Mode',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.orange[900],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Auctions use Sokocoin (SOK)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.orange[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _startingPriceController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.grey[900],
                              ),
                              decoration: InputDecoration(
                                labelText: 'Starting Price',
                                hintText: 'Enter starting bid in Sokocoin',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'SOK',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.orange[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.orange[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.orange[700]!,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              validator: (value) {
                                if (_productType == 'live_auction' && (value == null || value.isEmpty)) {
                                  return 'Please enter starting price';
                                }
                                if (value != null && value.isNotEmpty) {
                                  final price = double.tryParse(value);
                                  if (price == null || price <= 0) {
                                    return 'Starting price must be greater than 0';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _bidIncrementController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.grey[900],
                              ),
                              decoration: InputDecoration(
                                labelText: 'Bid Increment',
                                hintText: 'Minimum bid increase amount',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'SOK',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.orange[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.orange[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.orange[700]!,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              validator: (value) {
                                if (_productType == 'live_auction' && (value == null || value.isEmpty)) {
                                  return 'Please enter bid increment';
                                }
                                if (value != null && value.isNotEmpty) {
                                  final increment = double.tryParse(value);
                                  if (increment == null || increment <= 0) {
                                    return 'Bid increment must be greater than 0';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _auctionDurationController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.grey[900],
                              ),
                              decoration: InputDecoration(
                                labelText: 'Auction Duration',
                                hintText: 'Minimum 60 minutes (1 hour)',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                ),
                                suffixIcon: Container(
                                  margin: const EdgeInsets.all(8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'min',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.orange[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.orange[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.orange[700]!,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              validator: (value) {
                                if (_productType == 'live_auction' && (value == null || value.isEmpty)) {
                                  return 'Please enter auction duration';
                                }
                                if (value != null && value.isNotEmpty) {
                                  final duration = int.tryParse(value);
                                  if (duration == null || duration < 60) {
                                    return 'Duration must be at least 60 minutes (1 hour)';
                                  }
                                  if (duration > 43200) {
                                    return 'Duration cannot exceed 43200 minutes (720 hours)';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[200]!.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, size: 16, color: Colors.orange[900]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Auction starts immediately and ends after the specified duration. Highest bidder wins.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[900],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your product in detail...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[850] : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter description';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Settings & Features - Modern Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings_rounded,
                          size: 20,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Settings & Features',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildModernSwitchTile(
                        'Winga Mode',
                        'Enable this, 3rd party clients can post your products',
                        Icons.storefront_rounded,
                        Colors.blue,
                        _isWingaEnabled,
                        (value) {
                  setState(() {
                    _isWingaEnabled = value;
                  });
                },
                        isDark,
                      ),
                      Divider(height: 1, color: isDark ? Colors.grey[700] : Colors.grey[200]),
                      _buildModernSwitchTile(
                        'Warranty',
                        'Enable product Annual warranty to gain more trust',
                        Icons.verified_rounded,
                        Colors.green,
                        _hasWarranty,
                        (value) {
                  setState(() {
                    _hasWarranty = value;
                  });
                },
                        isDark,
                      ),
                      Divider(height: 1, color: isDark ? Colors.grey[700] : Colors.grey[200]),
                      _buildModernSwitchTile(
                        'Private Product',
                        'Only your Followers can see this product',
                        Icons.lock_rounded,
                        Colors.purple,
                        _isPrivate,
                        (value) {
                  setState(() {
                    _isPrivate = value;
                  });
                },
                        isDark,
                      ),
                      Divider(height: 1, color: isDark ? Colors.grey[700] : Colors.grey[200]),
                      _buildModernSwitchTile(
                        'Adult Content',
                        'Only users above 18+ can see this product',
                        Icons.warning_rounded,
                        Colors.red,
                        _isAdultContent,
                        (value) {
                  setState(() {
                    _isAdultContent = value;
                  });
                },
                        isDark,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Submit Button - Modern Design
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _productType == 'live_auction'
                          ? [Colors.orange[600]!, Colors.orange[700]!]
                          : [Colors.blue[600]!, Colors.blue[700]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (_productType == 'live_auction' ? Colors.orange : Colors.blue)
                            .withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isEditMode ? Icons.update_rounded : Icons.add_circle_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isEditMode ? 'Update Product' : 'Create Product',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTypeOption(String title, String value, IconData icon, Color color, bool isDark) {
    final isSelected = _productType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _productType = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : (isDark ? Colors.grey[850] : Colors.white),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isSelected ? Colors.white : color).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
              icon,
              size: 32,
                color: isSelected ? Colors.white : color,
            ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.grey[900]),
              ),
            ),
            const SizedBox(height: 4),
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Selected',
                  style: TextStyle(
                    fontSize: 11,
                fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }
}

