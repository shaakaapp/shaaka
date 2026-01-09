import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/product_card.dart';
import '../services/storage_service.dart';
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
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
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
        } else {
          _error = result['error'] is Map 
              ? (result['error']['error'] ?? 'Failed to load products') 
              : result['error'].toString();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _loadProducts, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store_mall_directory, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(widget.isVendorView ? 'You haven\'t added any products yet.' : 'No items in the market.', style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search Header
        if (!widget.isVendorView)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Search for products...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
          
        // Product Grid
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadProducts,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7, // Adjust aspect ratio for taller cards with rating
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  product: _products[index],
                  onTap: () {
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => ProductDetailsPage(product: _products[index]))
                      ).then((_) => _loadProducts()); // Reload in case rating changed
                  },
                  onEdit: widget.isVendorView ? () {
                       Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => AddProductPage(product: _products[index]))
                      ).then((value) {
                           if (value == true) _loadProducts();
                      });
                  } : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
