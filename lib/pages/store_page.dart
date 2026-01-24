import 'dart:async';
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
  Map<String, List<Product>> _categorizedProducts = {};

  // Carousel Logic
  final PageController _carouselController = PageController();
  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;
  final List<String> _carouselImages = [
    'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=1000', // Groceries/Market
    'https://images.unsplash.com/photo-1604719312566-b7cb0463d3a1?auto=format&fit=crop&q=80&w=1000', // Organic Food
    'https://images.unsplash.com/photo-1543168256-418811576931?auto=format&fit=crop&q=80&w=1000', // Vegetables
    'https://images.unsplash.com/photo-1488459716781-31db52582fe9?auto=format&fit=crop&q=80&w=1000', // Fruits
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    if (!widget.isVendorView) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_carouselController.hasClients) {
        int nextPage = _currentCarouselIndex + 1;
        if (nextPage >= _carouselImages.length) {
          nextPage = 0;
        }
        _carouselController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _carouselTimer?.cancel();
    _carouselController.dispose();
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
          
          // Group products by category
          _categorizedProducts = {};
          for (var product in _products) {
             if (product.category.isNotEmpty) {
                if (!_categorizedProducts.containsKey(product.category)) {
                  _categorizedProducts[product.category] = [];
                }
                _categorizedProducts[product.category]!.add(product);
             }
          }
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
        // Search Header (Top and Fixed)
        if (!widget.isVendorView)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Material(
              color: Colors.transparent,
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SearchPage()),
                  );
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search for fresh products...',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search my products...',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 15,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    width: 1,
                  ),
                ),
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

        // Scrollable Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadProducts,
            child: CustomScrollView(
              slivers: [
                // Carousel (Show only if not vendor mode AND not searching)
                if (!widget.isVendorView && _searchController.text.isEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _carouselController,
                            itemCount: _carouselImages.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentCarouselIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return Image.network(
                                _carouselImages[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported,
                                      size: 50, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: _carouselImages.asMap().entries.map((entry) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: _currentCarouselIndex == entry.key ? 20.0 : 8.0,
                                  height: 8.0,
                                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.white.withOpacity(
                                        _currentCarouselIndex == entry.key ? 0.9 : 0.4),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // If Searching -> Show Grid
                if (_searchController.text.isNotEmpty)
                  SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return ProductCard(
                              product: _filteredProducts[index],
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailsPage(
                                        product: _filteredProducts[index]),
                                  ),
                                ).then((_) => _loadProducts());
                              },
                              onEdit: widget.isVendorView ? () { /*...*/ } : null,
                            );
                          },
                          childCount: _filteredProducts.length,
                        ),
                      ),
                    )
                // Else -> Show Categories
                else ...[
                  // Padding
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  
                  // Top Products (Placeholder Logic)
                  // if (_categorizedProducts.isNotEmpty) ...[
                  //    // Placeholder for Top Products if needed
                  // ],

                  // Categories
                  for (var category in _categorizedProducts.keys)
                    if (_categorizedProducts[category]!.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildCategorySection(category, _categorizedProducts[category]!),
                      ),
                      
                   const SliverToBoxAdapter(child: SizedBox(height: 80)), // Bottom padding
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildCategorySection(String category, List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to category view
                },
                child: Text(
                  'See all',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 185, // Height for ProductCard + Padding
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 110, // Fixed width for horizontal card
                child: ProductCard(
                  product: products[index],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsPage(product: products[index]),
                      ),
                    ).then((_) => _loadProducts());
                  },
                  onEdit: widget.isVendorView ? () {
                       Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => AddProductPage(product: products[index]))
                      ).then((value) {
                           if (value == true) _loadProducts();
                      });
                  } : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
