import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/product_card.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'product_details_page.dart';
import 'add_product_page.dart';
import 'search_page.dart';

class StorePage extends StatefulWidget {
  final bool isVendorView;
  final int? vendorId;

  const StorePage({
    super.key,
    this.isVendorView = false,
    this.vendorId,
  });

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    Map<String, dynamic> result;
    if (widget.isVendorView) {
        int? id = widget.vendorId;
        if (id == null) {
            id = await StorageService.getUserId();
        }
        
        if (id != null) {
             result = await ApiService.getVendorProducts(id);
        } else {
            result = {'success': false, 'error': 'User not logged in'};
        }
    } else if (widget.vendorId != null) {
         result = await ApiService.getVendorProducts(widget.vendorId!);
    } else {
        result = await ApiService.getProducts();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _products = result['data'];
          _filteredProducts = _products;
          // Re-apply filter if search text exists
          if (_searchController.text.isNotEmpty) {
             _filterProducts(_searchController.text);
          }
        } else {
          _error = result['error'] is Map 
              ? (result['error']['error'] ?? 'Failed to load products') 
              : result['error'].toString();
        }
      });
    }
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _products;
      });
      return;
    }

    setState(() {
      _filteredProducts = _products.where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading products...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isVendorView
                      ? Icons.inventory_2_outlined
                      : Icons.store_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.isVendorView
                    ? 'You haven\'t added any products yet.'
                    : 'No items in the market.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Search Header
        if (!widget.isVendorView)
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.all(16.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SearchPage()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Search for products...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            color: AppTheme.warmWhite,
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search my products...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _filterProducts('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterProducts,
            ),
          ),
          
        // Product Grid
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadProducts,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate responsive aspect ratio based on screen size
                final screenWidth = constraints.maxWidth;
                final isSmallScreen = screenWidth < 360;
                final isVerySmallScreen = screenWidth < 320;
                // Adjust aspect ratio to prevent overflow - larger ratio = more height
                double aspectRatio;
                if (isVerySmallScreen) {
                  aspectRatio = 0.58; // More height for very small screens
                } else if (isSmallScreen) {
                  aspectRatio = 0.64; // More height for small screens
                } else {
                  aspectRatio = 0.68; // More height for normal screens
                }
                
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: aspectRatio,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    return ProductCard(
                      product: _filteredProducts[index],
                      onTap: () {
                          Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => ProductDetailsPage(product: _filteredProducts[index]))
                          ).then((_) => _loadProducts()); // Reload in case rating changed
                      },
                      onEdit: widget.isVendorView ? () {
                           Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => AddProductPage(product: _filteredProducts[index]))
                          ).then((value) {
                               if (value == true) _loadProducts();
                          });
                      } : null,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
